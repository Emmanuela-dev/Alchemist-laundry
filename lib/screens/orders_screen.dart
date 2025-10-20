import 'package:flutter/material.dart';
import '../services/local_repo.dart';
import '../models/models.dart';
// Supabase removed; using LocalRepo for orders in prototype

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
      orders = LocalRepo.instance.listUserOrders(user.id);
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
