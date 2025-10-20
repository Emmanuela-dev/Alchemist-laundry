import 'package:flutter/material.dart';
import 'dart:math' as math;
// using simple network tile previews instead of flutter_map to keep web builds stable
import 'package:url_launcher/url_launcher.dart';
import '../services/sms_config.dart';
import '../services/admin_numbers.dart';
import 'full_map_screen.dart';
import '../models/models.dart';
import '../services/local_repo.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({required this.orderId, super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

// Helpers to compute OSM tile X/Y from lon/lat at a zoom level.
int _lonToTile(double lon, int zoom) {
  final x = ((lon + 180) / 360 * (1 << zoom)).floor();
  return x;
}

int _latToTile(double lat, int zoom) {
  final latRad = lat * math.pi / 180.0;
  // Formula from OSM slippy map tilenames
  final n = math.pow(2, zoom);
  final y = ((1 - (math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi)) / 2 * n).floor();
  return y;
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? order;
  List<Comment> comments = [];
  final _comment = TextEditingController();
  int _rating = 5;

  @override
  void initState() {
    super.initState();
    order = LocalRepo.instance.getOrder(widget.orderId);
    comments = LocalRepo.instance.getComments(widget.orderId);
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
          const SizedBox(height: 8),
          if (order!.latitude != null && order!.longitude != null)
            SizedBox(
              height: 160,
              child: Card(
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => FullMapScreen(latitude: order!.latitude!, longitude: order!.longitude!, title: 'Order ${order!.id}')));
                  },
                  // Show a simple map tile image from OpenStreetMap. This
                  // avoids depending on flutter_map's web API and marker
                  // builders which had mismatches in the current dependency
                  // set.
                  child: Image.network(
                    'https://tile.openstreetmap.org/16/${_lonToTile(order!.longitude!, 16)}/${_latToTile(order!.latitude!, 16)}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Center(child: Text('Map preview unavailable')),
                  ),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
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
          ,
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final ctx = context;
              final scaffold = ScaffoldMessenger.of(ctx);
              final admins = await AdminNumbers.load();
              if (!mounted) return;
              final targets = admins.isNotEmpty ? admins : SmsConfig.adminNumbers;
              if (targets.isEmpty) {
                scaffold.showSnackBar(const SnackBar(content: Text('No admin number configured')));
                return;
              }

              // Show chooser bottom sheet
              // capture ctx earlier to avoid build-context-across-async lint
              // ignore: use_build_context_synchronously
              final chosen = await showModalBottomSheet<String>(context: ctx, builder: (ctx) {
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  const ListTile(title: Text('Send order to admin via WhatsApp')),
                  ...targets.map((t) => ListTile(title: Text(t), leading: const Icon(Icons.person), onTap: () => Navigator.of(ctx).pop(t))),
                  ListTile(title: const Text('Cancel'), leading: const Icon(Icons.close), onTap: () => Navigator.of(ctx).pop()),
                ]);
              });

              if (!mounted) return;
              if (chosen == null) return;

              // Build a richer message
              final user = LocalRepo.instance.currentUser;
              final itemsText = order!.items.map((i) => '${i.name} x${i.quantity}').join(', ');
              final msg = 'New order ${order!.id}\nCustomer: ${user?.name ?? ''} ${user?.phone ?? ''}\nService: ${LocalRepo.instance.listServices().firstWhere((s) => s.id == order!.serviceId).title}\nItems: $itemsText\nTotal: KES ${order!.total.toStringAsFixed(0)}';
              final phone = chosen.replaceAll('+', '');
              final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');
              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
            },
            icon: Icon(Icons.send),
            label: const Text('Send to admin on WhatsApp'),
          ),
        ]),
      ),
    );
  }
}
