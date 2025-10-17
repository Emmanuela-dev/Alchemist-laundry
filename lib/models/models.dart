enum OrderStatus { pending, pickedUp, inWashing, ready, outForDelivery, delivered }

class UserProfile {
  final String id;
  String name;
  String email;
  String phone;
  String address;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.address = '',
  });
}

class Service {
  final String id;
  final String title;
  final String description;
  final double basePrice; // per kg or per item depending on type

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.basePrice,
  });
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({required this.name, required this.quantity, required this.price});
}

class Order {
  final String id;
  final String userId;
  final String serviceId;
  final List<OrderItem> items;
  final DateTime pickupTime;
  final DateTime deliveryTime;
  String instructions;
  OrderStatus status;
  final double total;

  Order({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.items,
    required this.pickupTime,
    required this.deliveryTime,
    this.instructions = '',
    this.status = OrderStatus.pending,
    required this.total,
  });
}

class Comment {
  final String id;
  final String orderId;
  final String userId;
  final String text;
  final int rating; // 1-5
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.text,
    this.rating = 5,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
