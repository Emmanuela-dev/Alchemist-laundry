import 'package:flutter/material.dart';
import '../services/local_repo.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_numbers.dart';
import '../services/sms_config.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  String? serviceId;
  final _itemName = TextEditingController(text: 'Clothes');
  final _quantity = TextEditingController(text: '1');
  DateTime pickup = DateTime.now().add(const Duration(days: 1));
  DateTime delivery = DateTime.now().add(const Duration(days: 3));
  final _instructions = TextEditingController();
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    serviceId = args?['serviceId'] as String?;
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
    setState(() {
      _loading = true;
    });
    final qty = int.tryParse(_quantity.text) ?? 1;
    final unitPrice = 150.0; // KES per unit example
    final items = [OrderItem(name: _itemName.text, quantity: qty, price: unitPrice)];
  // total computed in LocalRepo.createOrder

    // Attempt to get current location (best-effort). Use last-known first and a short timeout
    double? lat;
    double? lng;
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

    // Centralized create order flow with error handling and guaranteed loading reset
    try {
      // Safely compute base price for the selected service (avoid firstWhere throwing)
      final servicesList = LocalRepo.instance.listServices();
      final basePrice = servicesList.firstWhere(
        (s) => s.id == (serviceId ?? 's1'),
        orElse: () => Service(id: '', title: '', description: '', basePrice: 0.0),
      ).basePrice;

      if (FirebaseService.instance.ready) {
        final user = FirebaseService.instance.auth.currentUser;
        final doc = await FirebaseService.instance.createOrder({
          'userId': user?.uid ?? LocalRepo.instance.currentUser?.id,
          'serviceId': serviceId ?? 's1',
          'items': items.map((e) => {'name': e.name, 'quantity': e.quantity, 'price': e.price}).toList(),
          'pickupTime': pickup.toIso8601String(),
          'deliveryTime': delivery.toIso8601String(),
          'instructions': _instructions.text,
          'total': items.fold<double>(0, (p, e) => p + e.price * e.quantity) + basePrice,
          'latitude': lat,
          'longitude': lng,
          'status': 'pending',
          'placedAt': DateTime.now().toIso8601String(),
        });
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/order', arguments: {'orderId': doc.id});
        // After creating the order in Firestore, open WhatsApp to primary admin
        _openWhatsAppToPrimaryAdmin(doc.id, items, serviceId, orderTotal: items.fold<double>(0, (p, e) => p + e.price * e.quantity));
      } else {
        final order = await LocalRepo.instance.createOrder(serviceId: serviceId ?? 's1', items: items, pickup: pickup, delivery: delivery, instructions: _instructions.text, latitude: lat, longitude: lng);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/order', arguments: {'orderId': order.id});
        // After creating the local order, open WhatsApp to primary admin
        _openWhatsAppToPrimaryAdmin(order.id, items, serviceId, orderTotal: items.fold<double>(0, (p, e) => p + e.price * e.quantity));
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
    final serviceTitle = LocalRepo.instance.listServices().firstWhere((s) => s.id == (serviceId ?? 's1')).title;
    final itemsText = items.map((i) => '${i.name} x${i.quantity}').join(', ');
    final msg = 'New order $orderId\nCustomer: ${user?.name ?? ''} ${user?.phone ?? ''}\nService: $serviceTitle\nItems: $itemsText\nTotal: KES ${orderTotal.toStringAsFixed(0)}';
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = LocalRepo.instance.listServices();
    final service = serviceId != null ? services.firstWhere((s) => s.id == serviceId, orElse: () => Service(id: '', title: '', description: '', basePrice: 0.0)) : null;
    final bool serviceAvailable = service != null && service.id.isNotEmpty;
  final header = serviceAvailable ? Text('Service: ${service.title}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)) : const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Create Order')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          header,
          const SizedBox(height: 8),
          TextField(controller: _itemName, decoration: const InputDecoration(labelText: 'Item name')),
          const SizedBox(height: 8),
          TextField(controller: _quantity, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('Pickup: ${pickup.toLocal().toString().split(' ')[0]}')),
            TextButton(onPressed: () => _pickDate(context, true), child: const Text('Change')),
          ],),
          Row(children: [
            Expanded(child: Text('Delivery: ${delivery.toLocal().toString().split(' ')[0]}')),
            TextButton(onPressed: () => _pickDate(context, false), child: const Text('Change')),
          ],),
          TextField(controller: _instructions, decoration: const InputDecoration(labelText: 'Special instructions')),const SizedBox(height: 16),
          if (!serviceAvailable) ...[
            const Text('Selected service is not available. Please choose a service from the Home screen.', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: (!_loading && serviceAvailable) ? _submit : null,
            child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Place Order'),
          ),
        ]),
      ),
    );
  }
}
