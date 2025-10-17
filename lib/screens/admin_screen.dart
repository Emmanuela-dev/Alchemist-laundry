import 'package:flutter/material.dart';
import '../services/mock_repo.dart';
import '../models/models.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Order> orders = [];

  @override
  void initState() {
    super.initState();
    orders = MockRepo.instance.listAllOrders();
  }

  void _refresh() {
    setState(() {
      orders = MockRepo.instance.listAllOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, i) {
          final o = orders[i];
          return Card(
            child: ListTile(
              title: Text('Order ${o.id} - \$${o.total.toStringAsFixed(2)}'),
              subtitle: Text('Status: ${o.status.name}'),
              trailing: PopupMenuButton<OrderStatus>(
                onSelected: (s) async { await MockRepo.instance.updateOrderStatus(o.id, s); _refresh(); },
                itemBuilder: (ctx) => OrderStatus.values.map((s) => PopupMenuItem(value: s, child: Text(s.name))).toList(),
              ),
              onTap: () => Navigator.pushNamed(context, '/order', arguments: {'orderId': o.id}),
            ),
          );
        },
      ),
    );
  }
}
