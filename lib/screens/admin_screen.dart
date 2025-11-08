import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/local_repo.dart';
import '../models/models.dart';
// Supabase removed; admin actions use LocalRepo
import 'admin_settings_screen.dart';

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
  appBar: AppBar(title: const Text('Admin Dashboard'), actions: [
    IconButton(icon: const Icon(Icons.inventory_2), onPressed: () => Navigator.pushNamed(context, '/admin-services')),
    IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsScreen()))),
    IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.pushReplacementNamed(context, '/home')),
  ]),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, i) {
          final o = orders[i];
          return Card(
            child: ListTile(
              leading: IconButton(
                icon: const Icon(Icons.map),
                onPressed: (o.latitude != null && o.longitude != null)
                    ? () async {
                        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${o.latitude},${o.longitude}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      }
                    : null,
              ),
              title: Text('Order ${o.id} - KES ${o.total.toStringAsFixed(0)}'),
              isThreeLine: o.latitude != null && o.longitude != null,
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Status: ${o.status.name}'),
                if (o.latitude != null && o.longitude != null)
                  Text('Client location: ${o.latitude!.toStringAsFixed(5)}, ${o.longitude!.toStringAsFixed(5)}')
                else
                  const Text('Client location: not provided')
              ]),
              trailing: PopupMenuButton<OrderStatus>(
                onSelected: (s) async {
                  await LocalRepo.instance.updateOrderStatus(o.id, s);
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
