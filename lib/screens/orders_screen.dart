import 'package:flutter/material.dart';
import '../services/mock_repo.dart';
import '../models/models.dart';

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
    final user = MockRepo.instance.currentUser;
    if (user != null) orders = MockRepo.instance.listUserOrders(user.id);
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
              title: Text('Order ${o.id} - \$${o.total.toStringAsFixed(2)}'),
              subtitle: Text('Status: ${o.status.name}'),
              onTap: () => Navigator.pushNamed(context, '/order', arguments: {'orderId': o.id}),
            ),
          );
        },
      ),
    );
  }
}
