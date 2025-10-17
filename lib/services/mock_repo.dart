import 'dart:async';
// simple id generator - avoid external dependency
import '../models/models.dart';

class MockRepo {
  MockRepo._private();
  static final MockRepo instance = MockRepo._private();

  String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

  final Map<String, UserProfile> _users = {};
  final Map<String, Service> _services = {};
  final Map<String, Order> _orders = {};
  final Map<String, List<Comment>> _comments = {};

  UserProfile? _currentUser;

  Future<void> init() async {
    // seed services
    final s1 = Service(id: 's1', title: 'Wash & Fold', description: 'Wash and fold per kg', basePrice: 2.5);
    final s2 = Service(id: 's2', title: 'Dry Cleaning', description: 'Dry clean per item', basePrice: 5.0);
    final s3 = Service(id: 's3', title: 'Ironing / Pressing', description: 'Per item ironing', basePrice: 1.5);
    final s4 = Service(id: 's4', title: 'Pickup & Delivery', description: 'Pickup and delivery service', basePrice: 3.0);
    _services[s1.id] = s1;
    _services[s2.id] = s2;
    _services[s3.id] = s3;
    _services[s4.id] = s4;

    // seed a user
    final u1 = UserProfile(id: 'u1', name: 'Demo User', email: 'demo@example.com', phone: '0700000000', address: '123 Demo St');
    _users[u1.id] = u1;
    _currentUser = u1;

    // seed an order
    final order = Order(
      id: 'o1',
      userId: u1.id,
      serviceId: s1.id,
      items: [OrderItem(name: 'Shirts', quantity: 5, price: 2.5)],
      pickupTime: DateTime.now().add(const Duration(days: 1)),
      deliveryTime: DateTime.now().add(const Duration(days: 3)),
      instructions: 'Handle delicates with care',
      total: 12.5,
    );
    _orders[order.id] = order;
    _comments[order.id] = [];
  }

  // Auth simulation
  Future<UserProfile> login(String email, String password) async {
    // returns demo user for any credentials
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser ??= _users.values.first;
    return _currentUser!;
  }

  Future<UserProfile> signup(String name, String email, String password) async {
  final id = _genId();
    final user = UserProfile(id: id, name: name, email: email);
    _users[id] = user;
    _currentUser = user;
    return user;
  }

  UserProfile? get currentUser => _currentUser;

  // Services
  List<Service> listServices() => _services.values.toList();

  // Orders
  Future<Order> createOrder({required String serviceId, required List<OrderItem> items, required DateTime pickup, required DateTime delivery, String instructions = ''}) async {
  final id = _genId();
    final total = items.fold<double>(0, (p, e) => p + e.price * e.quantity) + (_services[serviceId]?.basePrice ?? 0);
    final order = Order(id: id, userId: _currentUser!.id, serviceId: serviceId, items: items, pickupTime: pickup, deliveryTime: delivery, instructions: instructions, total: total);
    _orders[id] = order;
    _comments[id] = [];
    return order;
  }

  List<Order> listUserOrders(String userId) => _orders.values.where((o) => o.userId == userId).toList();

  Order? getOrder(String id) => _orders[id];

  // Admin helper
  List<Order> listAllOrders() => _orders.values.toList();

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final o = _orders[orderId];
    if (o != null) {
      o.status = status;
    }
  }

  // Comments
  Future<Comment> addComment(String orderId, String userId, String text, int rating) async {
  final id = _genId();
    final c = Comment(id: id, orderId: orderId, userId: userId, text: text, rating: rating);
    _comments[orderId] ??= [];
    _comments[orderId]!.add(c);
    return c;
  }

  List<Comment> getComments(String orderId) => _comments[orderId] ?? [];
}
