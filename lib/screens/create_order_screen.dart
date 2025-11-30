import 'package:flutter/material.dart';
import '../services/local_repo.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_numbers.dart';
import '../services/sms_config.dart';
import '../screens/home_screen.dart'; // For ServiceType
import '../services/payment_service.dart';
import '../screens/location_picker_screen.dart';
import 'package:latlong2/latlong.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

enum PaymentMethod { cash, mpesa, card }

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  List<OrderItem> cartItems = [];
  ServiceType? serviceType;
  DateTime pickup = DateTime.now().add(const Duration(days: 1));
  DateTime delivery = DateTime.now().add(const Duration(days: 3));
  final _instructions = TextEditingController();
  bool _loading = false;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  LatLng? _selectedLocation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      cartItems = args['cartItems'] as List<OrderItem>? ?? [];
      serviceType = args['serviceType'] as ServiceType?;
    }
  }

  double get _totalAmount {
    return cartItems.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> _pickDate(BuildContext ctx, bool isPickup) async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: ctx, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 30)));
    if (picked != null) {
      setState(() {
        if (isPickup) {
          pickup = picked;
        } else {
          delivery = picked;
        }
      });
    }
  }

  void _submit() async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items in cart')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    // Use selected location if available, otherwise try to get current location
    double? lat;
    double? lng;

    if (_selectedLocation != null) {
      lat = _selectedLocation!.latitude;
      lng = _selectedLocation!.longitude;
    } else {
      // Fallback to current location if no location selected
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          lat = last.latitude;
          lng = last.longitude;
        } else {
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            final req = await Geolocator.requestPermission();
            if (req == LocationPermission.denied) {
              // user denied, continue without location
            }
          }
          final serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            try {
              final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best).timeout(const Duration(seconds: 5));
              lat = pos.latitude;
              lng = pos.longitude;
            } catch (_) {
              // timeout or other location errors -> ignore and continue
            }
          }
        }
      } catch (e) {
        // ignore location errors; proceed without coords
      }
    }

    // Centralized create order flow with error handling and guaranteed loading reset
    try {
      String orderId;
      if (FirebaseService.instance.ready) {
        final user = FirebaseService.instance.auth.currentUser;
        final doc = await FirebaseService.instance.createOrder({
          'userId': user?.uid ?? LocalRepo.instance.currentUser?.id,
          'serviceId': 'cart-order', // Generic service ID for cart orders
          'serviceType': serviceType?.name ?? 'washFold',
          'items': cartItems.map((e) => {'name': e.name, 'quantity': e.quantity, 'price': e.price}).toList(),
          'pickupTime': pickup.toIso8601String(),
          'deliveryTime': delivery.toIso8601String(),
          'instructions': _instructions.text,
          'total': _totalAmount,
          'latitude': lat,
          'longitude': lng,
          'status': 'pending',
          'paymentMethod': _selectedPaymentMethod.name,
          'paymentStatus': _selectedPaymentMethod == PaymentMethod.cash ? 'completed' : 'pending',
          'placedAt': DateTime.now().toIso8601String(),
        });
        orderId = doc.id;

        // Handle payment based on selected method
        if (_selectedPaymentMethod == PaymentMethod.mpesa) {
          final phoneNumber = user?.phoneNumber ?? LocalRepo.instance.currentUser?.phone ?? '';

          if (phoneNumber.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Phone number required for M-Pesa payment. Please update your profile.'),
                duration: Duration(seconds: 5),
              ),
            );
          } else {
            try {
              // Try to initiate M-Pesa payment
              final paymentResult = await PaymentService().initiatePayment(
                orderId: orderId,
                amount: _totalAmount,
                phoneNumber: phoneNumber,
                userId: user?.uid ?? LocalRepo.instance.currentUser?.id ?? '',
              );

              if (paymentResult['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(paymentResult['message'] ?? 'Please send payment to 0757952937 via M-Pesa'),
                    duration: const Duration(seconds: 7),
                  ),
                );
              } else {
                // Payment initiation failed, but order is still created
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order created. Payment setup failed: ${paymentResult['error'] ?? 'Unknown error'}. Our team will contact you.'),
                    duration: const Duration(seconds: 7),
                  ),
                );
              }
            } catch (e) {
              // Payment failed, but order is still created
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order created. M-Pesa setup failed: $e. Our team will contact you for payment.'),
                  duration: const Duration(seconds: 7),
                ),
              );
            }
          }
        } else if (_selectedPaymentMethod == PaymentMethod.cash) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Order received! Payment will be collected when our driver picks up your laundry.'),
              duration: Duration(seconds: 4),
            ),
          );
        } else if (_selectedPaymentMethod == PaymentMethod.card) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card payment coming soon! Order placed for cash payment.')),
          );
        }

        // Open WhatsApp to primary admin first
        await _openWhatsAppToPrimaryAdmin(orderId, cartItems, 'cart-order', orderTotal: _totalAmount);
        // Then navigate to order details
        Navigator.pushReplacementNamed(context, '/order', arguments: {'orderId': orderId});
      } else {
        final order = await LocalRepo.instance.createOrder(
          serviceId: 'cart-order',
          items: cartItems,
          pickup: pickup,
          delivery: delivery,
          instructions: _instructions.text,
          latitude: lat,
          longitude: lng,
          isCartOrder: true,
          paymentMethod: _selectedPaymentMethod.name,
          paymentStatus: _selectedPaymentMethod == PaymentMethod.cash ? 'completed' : 'pending'
        );
        orderId = order.id;

        if (_selectedPaymentMethod == PaymentMethod.cash) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Order received! Payment will be collected when our driver picks up your laundry.'),
              duration: Duration(seconds: 4),
            ),
          );
        } else if (_selectedPaymentMethod == PaymentMethod.mpesa) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('M-Pesa payment not available offline. Order placed for cash payment.')),
          );
        } else if (_selectedPaymentMethod == PaymentMethod.card) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card payment coming soon! Order placed for cash payment.')),
          );
        }

        // Open WhatsApp to primary admin first
        await _openWhatsAppToPrimaryAdmin(orderId, cartItems, 'cart-order', orderTotal: _totalAmount);
        // Then navigate to order details
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/order', arguments: {'orderId': orderId});
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('Create order failed: $e\n$st');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _openWhatsAppToPrimaryAdmin(String orderId, List<OrderItem> items, String? serviceId, {required double orderTotal}) async {
    final admins = await AdminNumbers.load();
    final targets = admins.isNotEmpty ? admins : SmsConfig.adminNumbers;
    if (targets.isEmpty) return; // nothing to do
    final phone = targets.first.replaceAll('+', '');
    final user = LocalRepo.instance.currentUser;
    final serviceTitle = LocalRepo.instance.listServices().firstWhere((s) => s.id == (serviceId ?? 's1'), orElse: () => Service(id: 'unknown', title: 'Laundry Service', description: '', basePrice: 0)).title;
    final itemsText = items.map((i) => '${i.name} x${i.quantity}').join(', ');
    final msg = 'New order $orderId\nCustomer: ${user?.name ?? ''} ${user?.phone ?? ''}\nService: $serviceTitle\nItems: $itemsText\nTotal: KES ${orderTotal.toStringAsFixed(0)}';
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Review Order',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A5568)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Service Type Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cleaning_services,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Service Type: ${serviceType?.name ?? 'Not specified'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Order Items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Items',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (cartItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Color(0xFFCBD5E0),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No items in cart',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A5568),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please go back and add some services',
                              style: TextStyle(
                                color: Color(0xFF718096),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF667EEA).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.local_laundry_service,
                                    color: Color(0xFF667EEA),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.quantity} × KES ${item.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Color(0xFF718096),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'KES ${(item.price * item.quantity).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    if (cartItems.isNotEmpty) ...[
                      const SizedBox(height: 24),

                      // Scheduling Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.schedule, color: Color(0xFF667EEA)),
                                SizedBox(width: 8),
                                Text(
                                  'Schedule',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildScheduleItem(
                              'Pickup Date',
                              pickup.toLocal().toString().split(' ')[0],
                              () => _pickDate(context, true),
                            ),
                            const SizedBox(height: 12),
                            _buildScheduleItem(
                              'Delivery Date',
                              delivery.toLocal().toString().split(' ')[0],
                              () => _pickDate(context, false),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pickup Location',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedLocation != null
                                              ? '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}'
                                              : 'Tap to select exact pickup location',
                                          style: TextStyle(
                                            color: _selectedLocation != null ? Colors.green : Colors.black54,
                                            fontSize: 12,
                                            fontWeight: _selectedLocation != null ? FontWeight.w500 : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      final LatLng? selectedLocation = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LocationPickerScreen(
                                            title: 'Select Pickup Location',
                                            initialLocation: _selectedLocation,
                                          ),
                                        ),
                                      );

                                      if (selectedLocation != null) {
                                        setState(() {
                                          _selectedLocation = selectedLocation;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Location selected: ${selectedLocation.latitude.toStringAsFixed(4)}, ${selectedLocation.longitude.toStringAsFixed(4)}'
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      Icons.map,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Instructions Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.note_alt_outlined, color: Color(0xFF667EEA)),
                                SizedBox(width: 8),
                                Text(
                                  'Special Instructions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _instructions,
                              decoration: InputDecoration(
                                hintText: 'Any special care instructions...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF667EEA)),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Payment Method Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.payment, color: Color(0xFF667EEA)),
                                SizedBox(width: 8),
                                Text(
                                  'Payment Method',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Choose how you would like to pay for this order',
                              style: TextStyle(
                                color: Color(0xFF718096),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPaymentMethodOption(
                                    PaymentMethod.cash,
                                    'Cash',
                                    'Pay on delivery',
                                    Icons.money,
                                    Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildPaymentMethodOption(
                                    PaymentMethod.mpesa,
                                    'M-Pesa',
                                    'Send to 0757952937',
                                    Icons.phone_android,
                                    const Color(0xFF48BB78),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildPaymentMethodOption(
                                    PaymentMethod.card,
                                    'Card',
                                    'Coming soon',
                                    Icons.credit_card,
                                    Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Total and Button
            if (cartItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          'KES ${_totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF48BB78),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (!_loading && cartItems.isNotEmpty) ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Place Order',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(String label, String value, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF667EEA),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Row(
            children: [
              Text(value),
              const SizedBox(width: 4),
              const Icon(Icons.edit, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption(PaymentMethod method, String title, String subtitle, IconData icon, Color color) {
    final isSelected = _selectedPaymentMethod == method;
    final isDisabled = method == PaymentMethod.card; // Card payment not yet implemented

    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => _selectedPaymentMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isDisabled ? Colors.grey : (isSelected ? color : const Color(0xFF718096)),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isDisabled ? Colors.grey : (isSelected ? color : const Color(0xFF2D3748)),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isDisabled ? Colors.grey.shade400 : const Color(0xFF718096),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
