import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/local_repo.dart';
import '../services/supabase_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({required this.orderId, super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? order;
  List<Comment> comments = [];
  final _comment = TextEditingController();
  int _rating = 5;

  @override
  void initState() {
    super.initState();
    if (SupabaseService.instance.ready) {
      SupabaseService.instance.getOrder(widget.orderId).then((o) {
        setState(() {
          if (o != null) {
            order = Order(id: o['id'], userId: o['user_id'], serviceId: o['service_id'], items: [], pickupTime: DateTime.tryParse(o['pickup_time'] ?? '') ?? DateTime.now(), deliveryTime: DateTime.tryParse(o['delivery_time'] ?? '') ?? DateTime.now(), instructions: o['instructions'] ?? '', total: (o['total'] as num?)?.toDouble() ?? 0.0);
          }
        });
      });
      // comments not yet mapped; keep empty list for now
      comments = [];
    } else {
      order = LocalRepo.instance.getOrder(widget.orderId);
      comments = LocalRepo.instance.getComments(widget.orderId);
    }
  }

  void _addComment() async {
    final user = LocalRepo.instance.currentUser!;
    await LocalRepo.instance.addComment(widget.orderId, user.id, _comment.text, _rating);
    setState(() {
      comments = LocalRepo.instance.getComments(widget.orderId);
      _comment.clear();
      _rating = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (order == null) return Scaffold(body: Center(child: Text('Order not found')));
  final service = LocalRepo.instance.listServices().firstWhere((s) => s.id == order!.serviceId);
    return Scaffold(
      appBar: AppBar(title: Text('Order ${order!.id}')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Service: ${service.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Total: KES ${order!.total.toStringAsFixed(0)}'),
          Text('Pickup: ${order!.pickupTime.toLocal()}'),
          Text('Delivery: ${order!.deliveryTime.toLocal()}'),
          Text('Status: ${order!.status.name}'),
          const SizedBox(height: 12),
          const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...order!.items.map((i) => Text('${i.name} x${i.quantity}')),
          const SizedBox(height: 12),
          const Divider(),
          const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: ListView(children: comments.map((c) => ListTile(title: Text(c.text), subtitle: Text('Rating: ${c.rating}'))).toList())),
          TextField(controller: _comment, decoration: const InputDecoration(labelText: 'Write a comment')),
          Row(children: [
            const Text('Rating:'),
            DropdownButton<int>(value: _rating, items: [1,2,3,4,5].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(), onChanged: (v) { if (v!=null) setState(()=>_rating=v); }),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _addComment, child: const Text('Add'))
          ])
        ]),
      ),
    );
  }
}
