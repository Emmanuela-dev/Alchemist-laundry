import 'package:flutter/material.dart';
import 'dart:math' as math;
// using simple network tile previews instead of flutter_map to keep web builds stable
import 'package:url_launcher/url_launcher.dart';
import 'full_map_screen.dart';
import 'order_tracking_screen.dart';
import '../models/models.dart';
import '../services/local_repo.dart';
import '../services/firebase_service.dart';

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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();

    // Automatically open WhatsApp after a short delay to show order details first
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && order != null) {
        _sendToWhatsApp();
      }
    });
  }

  void _loadOrder() async {
    // First try to load from local repo
    order = LocalRepo.instance.getOrder(widget.orderId);
    comments = LocalRepo.instance.getComments(widget.orderId);

    // If not found locally and Firebase is available, try Firebase
    if (order == null && FirebaseService.instance.ready) {
      try {
        final orderDoc = await FirebaseService.instance.firestore
            .collection('orders')
            .doc(widget.orderId)
            .get();

        if (orderDoc.exists) {
          final data = orderDoc.data() as Map<String, dynamic>;
          final items = <OrderItem>[];
          final itemsList = data['items'] as List<dynamic>? ?? [];
          for (final it in itemsList) {
            final im = it as Map<String, dynamic>;
            items.add(OrderItem(
              name: im['name'],
              quantity: im['quantity'],
              price: (im['price'] as num).toDouble()
            ));
          }

          order = Order(
            id: data['id'] ?? widget.orderId,
            userId: data['userId'],
            serviceId: data['serviceId'] ?? 'cart-order',
            items: items,
            pickupTime: DateTime.parse(data['pickupTime']),
            deliveryTime: DateTime.parse(data['deliveryTime']),
            instructions: data['instructions'] ?? '',
            status: OrderStatus.values.firstWhere(
              (v) => v.name == data['status'],
              orElse: () => OrderStatus.pending,
            ),
            total: (data['total'] as num).toDouble(),
            latitude: (data['latitude'] as num?)?.toDouble(),
            longitude: (data['longitude'] as num?)?.toDouble(),
            paymentMethod: data['paymentMethod'],
            paymentStatus: data['paymentStatus'],
          );
        }
      } catch (e) {
        print('Error loading order from Firebase: $e');
      }
    }

    // Set loading to false
    if (mounted) {
      setState(() {
        _loading = false;
      });
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

  void _sendToWhatsApp() async {
    // Use the specific admin number for orders
    final adminPhoneNumber = '254757952937';

    // Build a richer message
    final user = LocalRepo.instance.currentUser;
    final itemsText = order!.items.map((i) => '${i.name} x${i.quantity}').join(', ');
    final serviceTitle = LocalRepo.instance.listServices().firstWhere(
      (s) => s.id == order!.serviceId,
      orElse: () => Service(id: 'unknown', title: 'Laundry Service', description: '', basePrice: 0)
    ).title;
    final msg = 'New order ${order!.id}\nCustomer: ${user?.name ?? ''} ${user?.phone ?? ''}\nService: $serviceTitle\nItems: $itemsText\nTotal: KES ${order!.total.toStringAsFixed(0)}';
    final phone = adminPhoneNumber.replaceAll('+', '');
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading order details...', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    if (order == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Order not found', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('The order could not be loaded. Please try again.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  final service = LocalRepo.instance.listServices().firstWhere(
    (s) => s.id == order!.serviceId,
    orElse: () => Service(id: 'unknown', title: 'Laundry Service', description: '', basePrice: 0)
  );
    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${order!.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.track_changes),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderTrackingScreen(order: order!),
                ),
              );
            },
            tooltip: 'Track Order',
          ),
        ],
      ),
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
            onPressed: _sendToWhatsApp,
            icon: const Icon(Icons.send),
            label: const Text('Send to admin on WhatsApp'),
          ),
        ]),
      ),
    );
  }
}
