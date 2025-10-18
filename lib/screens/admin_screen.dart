import 'package:flutter/material.dart';
import '../services/local_repo.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

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
    // use local repo for admin listing for now
    orders = LocalRepo.instance.listAllOrders();
  }

  void _refresh() {
    setState(() {
      orders = LocalRepo.instance.listAllOrders();
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
              title: Text('Order ${o.id} - KES ${o.total.toStringAsFixed(0)}'),
              subtitle: Text('Status: ${o.status.name}'),
              trailing: PopupMenuButton<OrderStatus>(
                onSelected: (s) async {
                  if (SupabaseService.instance.ready) {
                    await SupabaseService.instance.updateOrderStatus(o.id, s.name);
                    } else {
                      await LocalRepo.instance.updateOrderStatus(o.id, s);
                    }
                  _refresh();
                },
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
