import 'package:flutter/material.dart';
import '../services/local_repo.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> orders = [];

  @override
  void initState() {
    super.initState();
  final user = LocalRepo.instance.currentUser;
    if (user != null) {
      if (SupabaseService.instance.ready) {
        SupabaseService.instance.listOrdersForUser(user.id).then((list) => setState(() {
              orders = list.map((e) => Order(id: e['id'], userId: e['user_id'], serviceId: e['service_id'], items: [], pickupTime: DateTime.tryParse(e['pickup_time'] ?? '') ?? DateTime.now(), deliveryTime: DateTime.tryParse(e['delivery_time'] ?? '') ?? DateTime.now(), instructions: e['instructions'] ?? '', total: (e['total'] as num?)?.toDouble() ?? 0.0)).toList();
            }));
      } else {
        orders = LocalRepo.instance.listUserOrders(user.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Orders')),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, i) {
          final o = orders[i];
          return Card(
            child: ListTile(
              title: Text('Order ${o.id} - KES ${o.total.toStringAsFixed(0)}'),
              subtitle: Text('Status: ${o.status.name}'),
              onTap: () => Navigator.pushNamed(context, '/order', arguments: {'orderId': o.id}),
            ),
          );
        },
      ),
    );
  }
}
