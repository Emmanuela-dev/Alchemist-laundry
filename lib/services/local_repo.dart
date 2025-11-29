import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'notification_service.dart';
import 'sms_service.dart';

class LocalRepo {
  LocalRepo._private();
  static final LocalRepo instance = LocalRepo._private();

  late SharedPreferences _prefs;

  final Map<String, UserProfile> _users = {};
  final Map<String, Service> _services = {};
  final Map<String, Order> _orders = {};
  final Map<String, List<Comment>> _comments = {};

  UserProfile? _currentUser;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // load services if present, otherwise seed defaults
    final svcString = _prefs.getString('services');
    if (svcString != null) {
      final list = jsonDecode(svcString) as List<dynamic>;
      for (final e in list) {
        final map = e as Map<String, dynamic>;
        final s = Service(
          id: map['id'],
          title: map['title'],
          description: map['description'] ?? '',
          basePrice: (map['basePrice'] as num).toDouble(),
          imageUrl: map['imageUrl'] as String?,
        );
        _services[s.id] = s;
      }
    } else {
      // seed
      final s1 = Service(id: 's1', title: 'Wash & Fold', description: 'Wash and fold per laundry basket', basePrice: 300, imageUrl: null);
      final s2 = Service(id: 's2', title: 'Dry Cleaning', description: 'Dry clean per item', basePrice: 300, imageUrl: null);
      final s3 = Service(id: 's3', title: 'Ironing / Pressing', description: 'Per item ironing', basePrice: 50, imageUrl: null);
      final s4 = Service(id: 's4', title: 'Pickup & Delivery', description: 'Pickup and delivery service', basePrice: 0, imageUrl: null);
      final s5 = Service(id: 's5', title: 'Duvet', description: 'Duvet based on sizes', basePrice: 275, imageUrl: null);
      final s6 = Service(id: 's6', title: 'Blankets', description: 'Washing normal blankets', basePrice: 150, imageUrl: null);
      final s7 = Service(id: 's7', title: 'Shoes', description: 'Wash all types of shoes', basePrice: 50, imageUrl: null);
      final s8 = Service(id: 's8', title: 'House Cleaning', description: 'General House Cleaning', basePrice: 1200, imageUrl: null);
      _services[s1.id] = s1;
      _services[s2.id] = s2;
      _services[s3.id] = s3;
      _services[s4.id] = s4;
      _services[s5.id] = s5;
      _services[s6.id] = s6;
      _services[s7.id] = s7;
      _services[s8.id] = s8;
      await _saveServices();
    }

    // load users
    final usersStr = _prefs.getString('users');
    if (usersStr != null) {
      final list = jsonDecode(usersStr) as List<dynamic>;
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        final u = UserProfile(id: m['id'], name: m['name'], email: m['email'], phone: m['phone'] ?? '', address: m['address'] ?? '');
        _users[u.id] = u;
      }
    } else {
      final u1 = UserProfile(id: 'u1', name: 'Demo User', email: 'demo@example.com', phone: '0700000000', address: '123 Demo St');
      _users[u1.id] = u1;
      _currentUser = u1;
      await _saveUsers();
    }

    // load orders
    final ordersStr = _prefs.getString('orders');
    if (ordersStr != null) {
      final list = jsonDecode(ordersStr) as List<dynamic>;
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        final items = <OrderItem>[];
        final itemsList = m['items'] as List<dynamic>? ?? [];
        for (final it in itemsList) {
          final im = it as Map<String, dynamic>;
          items.add(OrderItem(name: im['name'], quantity: im['quantity'], price: (im['price'] as num).toDouble()));
        }
        final o = Order(id: m['id'], userId: m['userId'], serviceId: m['serviceId'], items: items, pickupTime: DateTime.parse(m['pickupTime']), deliveryTime: DateTime.parse(m['deliveryTime']), instructions: m['instructions'] ?? '', status: OrderStatus.values.firstWhere((v) => v.name == m['status']), total: (m['total'] as num).toDouble(), latitude: (m['latitude'] as num?)?.toDouble(), longitude: (m['longitude'] as num?)?.toDouble());
        _orders[o.id] = o;
      }
    }

    // load comments
    final commentsStr = _prefs.getString('comments');
    if (commentsStr != null) {
      final map = jsonDecode(commentsStr) as Map<String, dynamic>;
      map.forEach((orderId, list) {
        final arr = list as List<dynamic>;
        _comments[orderId] = arr.map((c) {
          final m = c as Map<String, dynamic>;
          return Comment(id: m['id'], orderId: m['orderId'], userId: m['userId'], text: m['text'], rating: m['rating'], createdAt: DateTime.parse(m['createdAt']));
        }).toList();
      });
    }
  }

  // persistence helpers
  Future<void> _saveServices() async {
    final list = _services.values.map((s) => {'id': s.id, 'title': s.title, 'description': s.description, 'basePrice': s.basePrice, 'imageUrl': s.imageUrl}).toList();
    await _prefs.setString('services', jsonEncode(list));
  }

  // Admin helpers for services
  Future<void> addService(Service service) async {
    _services[service.id] = service;
    await _saveServices();
  }

  Future<void> updateService(Service service) async {
    if (_services.containsKey(service.id)) {
      _services[service.id] = service;
      await _saveServices();
    }
  }

  Future<void> deleteService(String id) async {
    _services.remove(id);
    await _saveServices();
  }

  Future<void> _saveUsers() async {
    final list = _users.values.map((u) => {'id': u.id, 'name': u.name, 'email': u.email, 'phone': u.phone, 'address': u.address}).toList();
    await _prefs.setString('users', jsonEncode(list));
  }

  Future<void> _saveOrders() async {
    final list = _orders.values.map((o) => {
      'id': o.id,
      'userId': o.userId,
      'serviceId': o.serviceId,
      'items': o.items.map((it) => {'name': it.name, 'quantity': it.quantity, 'price': it.price}).toList(),
      'pickupTime': o.pickupTime.toIso8601String(),
      'deliveryTime': o.deliveryTime.toIso8601String(),
      'instructions': o.instructions,
      'status': o.status.name,
      'total': o.total,
      'latitude': o.latitude,
      'longitude': o.longitude,
    }).toList();
    await _prefs.setString('orders', jsonEncode(list));
  }

  Future<void> _saveComments() async {
    final map = <String, dynamic>{};
    _comments.forEach((orderId, list) {
      map[orderId] = list.map((c) => {'id': c.id, 'orderId': c.orderId, 'userId': c.userId, 'text': c.text, 'rating': c.rating, 'createdAt': c.createdAt.toIso8601String()}).toList();
    });
    await _prefs.setString('comments', jsonEncode(map));
  }

  // Auth
  Future<UserProfile> login(String email, String password) async {
    // simple lookup
    final found = _users.values.firstWhere((u) => u.email == email, orElse: () => _users.values.first);
    _currentUser = found;
    await _saveUsers();
    return found;
  }

  Future<UserProfile> signup(String name, String email, String password) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final user = UserProfile(id: id, name: name, email: email);
    _users[id] = user;
    _currentUser = user;
    await _saveUsers();
    return user;
  }

  UserProfile? get currentUser => _currentUser;

  Future<void> setCurrentUser(UserProfile user) async {
    _currentUser = user;
    // Also save to users map if not already there
    _users[user.id] = user;
    await _saveUsers();
  }

  // Services
  List<Service> listServices() => _services.values.toList();

  // Orders
  Future<Order> createOrder({required String serviceId, required List<OrderItem> items, required DateTime pickup, required DateTime delivery, String instructions = '', double? latitude, double? longitude, bool isCartOrder = false, String? paymentMethod, String? paymentStatus}) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    // For cart orders, don't add base price since items already include pricing
    final basePrice = isCartOrder ? 0.0 : (_services[serviceId]?.basePrice ?? 0);
    final total = items.fold<double>(0, (p, e) => p + e.price * e.quantity) + basePrice;
    final order = Order(id: id, userId: _currentUser!.id, serviceId: serviceId, items: items, pickupTime: pickup, deliveryTime: delivery, instructions: instructions, total: total, latitude: latitude, longitude: longitude, paymentMethod: paymentMethod, paymentStatus: paymentStatus);
    _orders[id] = order;
    _comments[id] = [];
    await _saveOrders();
    await _saveComments();
    // Notify admins via SMS (best-effort). Uses SmsConfig.enabled to decide.
    try {
      // Notify admins with a minimal message: order summary
      final itemsText = items.map((i) => '${i.name} x${i.quantity}').join(', ');
      final msg = 'New Order: $itemsText - Total: KES ${total.toStringAsFixed(0)}';
      await SmsService.instance.notifyAdmins(msg);
    } catch (e) {
      // ignore SMS failures in local repo
    }
    return order;
  }

  List<Order> listUserOrders(String userId) => _orders.values.where((o) => o.userId == userId).toList();

  Order? getOrder(String id) => _orders[id];

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final o = _orders[orderId];
    if (o != null) {
      o.status = status;
      await _saveOrders();
      // Notify user when their order becomes ready
      if (status == OrderStatus.ready) {
        final title = 'Your laundry is ready';
        final body = 'Order ${o.id} is ready for pickup/delivery.';
        await NotificationService.instance.showOrderReady(o.id, title, body);
      }
    }
  }

  // Comments
  Future<Comment> addComment(String orderId, String userId, String text, int rating) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final c = Comment(id: id, orderId: orderId, userId: userId, text: text, rating: rating);
    _comments[orderId] ??= [];
    _comments[orderId]!.add(c);
    await _saveComments();
    return c;
  }

  List<Comment> getComments(String orderId) => _comments[orderId] ?? [];

  // Admin
  List<Order> listAllOrders() => _orders.values.toList();

  // User lookup for login
  UserProfile? findUserByNameAndPhone(String name, String phone) {
    try {
      return _users.values.firstWhere(
        (user) => user.name.toLowerCase() == name.toLowerCase() && user.phone == phone,
      );
    } catch (e) {
      return null;
    }
  }

  UserProfile? findUserByPhone(String phone) {
    try {
      return _users.values.firstWhere(
        (user) => user.phone == phone,
      );
    } catch (e) {
      return null;
    }
  }
}
