import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/local_repo.dart';
import '../services/firebase_service.dart';
import '../models/models.dart';
import 'admin_settings_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Order> orders = [];
  bool _isLoading = true;

  // Dashboard metrics
  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _readyOrders = 0;
  double _totalRevenue = 0.0;
  int _todayOrders = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (FirebaseService.instance.ready) {
        // Load from Firebase for real-time data
        final ordersSnapshot = await FirebaseService.instance.firestore.collection('orders').get();
        orders = ordersSnapshot.docs.map((doc) {
          final data = doc.data();
          return Order(
            id: doc.id,
            userId: data['userId'] ?? '',
            serviceId: data['serviceId'] ?? '',
            items: (data['items'] as List<dynamic>? ?? []).map((item) => OrderItem(
              name: item['name'] ?? '',
              quantity: item['quantity'] ?? 1,
              price: (item['price'] as num?)?.toDouble() ?? 0.0,
            )).toList(),
            pickupTime: DateTime.parse(data['pickupTime'] ?? DateTime.now().toIso8601String()),
            deliveryTime: DateTime.parse(data['deliveryTime'] ?? DateTime.now().toIso8601String()),
            instructions: data['instructions'] ?? '',
            status: OrderStatus.values.firstWhere(
              (s) => s.name == (data['status'] ?? 'pending'),
              orElse: () => OrderStatus.pending,
            ),
            total: (data['total'] as num?)?.toDouble() ?? 0.0,
            latitude: (data['latitude'] as num?)?.toDouble(),
            longitude: (data['longitude'] as num?)?.toDouble(),
            paymentMethod: data['paymentMethod'],
            paymentStatus: data['paymentStatus'],
          );
        }).toList();
      } else {
        // Fallback to local repo
        orders = LocalRepo.instance.listAllOrders();
      }

      _calculateMetrics();
    } catch (e) {
      print('Error loading admin data: $e');
      // Fallback to local data
      orders = LocalRepo.instance.listAllOrders();
      _calculateMetrics();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _calculateMetrics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _totalOrders = orders.length;
    _pendingOrders = orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.pickedUp).length;
    _readyOrders = orders.where((o) => o.status == OrderStatus.ready).length;
    _totalRevenue = orders.where((o) => o.paymentStatus == 'completed').fold(0.0, (sum, o) => sum + o.total);
    _todayOrders = orders.where((o) => o.pickupTime.isAfter(today)).length;
  }

  void _refresh() {
    _loadData();
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.pickedUp:
        return Colors.blue;
      case OrderStatus.inWashing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.outForDelivery:
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.grey;
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
          'Admin Dashboard',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4A5568)),
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2, color: Color(0xFF4A5568)),
            onPressed: () => Navigator.pushNamed(context, '/admin-services'),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF4A5568)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Color(0xFF4A5568)),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard Metrics
                    const Text(
                      'Today\'s Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metrics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Total Orders',
                            _totalOrders.toString(),
                            Icons.shopping_cart,
                            const Color(0xFF667EEA),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Pending',
                            _pendingOrders.toString(),
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Ready',
                            _readyOrders.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Revenue',
                            'KES ${_totalRevenue.toStringAsFixed(0)}',
                            Icons.attach_money,
                            const Color(0xFF48BB78),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Orders Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Orders',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Filter to show only pending orders
                            setState(() {
                              orders = orders.where((o) =>
                                o.status != OrderStatus.delivered).toList();
                            });
                          },
                          child: const Text('Show Active'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (orders.isEmpty)
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
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Color(0xFFCBD5E0),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No orders yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A5568),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Orders will appear here when customers place them',
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
                        itemCount: orders.length,
                        itemBuilder: (context, i) {
                          final o = orders[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(o.status).withOpacity(0.1),
                                child: Icon(
                                  _getStatusIcon(o.status),
                                  color: _getStatusColor(o.status),
                                ),
                              ),
                              title: Text(
                                'Order ${o.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'KES ${o.total.toStringAsFixed(0)} • ${o.status.name}',
                                    style: TextStyle(
                                      color: _getStatusColor(o.status),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pickup: ${o.pickupTime.toLocal().toString().split(' ')[0]}',
                                    style: const TextStyle(
                                      color: Color(0xFF718096),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (o.latitude != null && o.longitude != null)
                                    IconButton(
                                      icon: const Icon(Icons.map, color: Color(0xFF667EEA)),
                                      onPressed: () async {
                                        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${o.latitude},${o.longitude}');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                    ),
                                  PopupMenuButton<OrderStatus>(
                                    onSelected: (s) async {
                                      try {
                                        if (FirebaseService.instance.ready) {
                                          await FirebaseService.instance.updateOrderStatus(o.id, s.name);
                                        } else {
                                          await LocalRepo.instance.updateOrderStatus(o.id, s);
                                        }
                                        _refresh();
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to update status: $e')),
                                        );
                                      }
                                    },
                                    itemBuilder: (ctx) => OrderStatus.values.map((s) =>
                                      PopupMenuItem(value: s, child: Text(s.name))
                                    ).toList(),
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.pushNamed(context, '/order', arguments: {'orderId': o.id}),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
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
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF718096),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.pickedUp:
        return Icons.local_shipping;
      case OrderStatus.inWashing:
        return Icons.wash;
      case OrderStatus.ready:
        return Icons.check_circle;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.done_all;
    }
  }
}
