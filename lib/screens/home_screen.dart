import 'package:flutter/material.dart';
import '../services/local_repo.dart';
import '../models/models.dart';
import '../widgets/logo_widget.dart';
// Supabase removed; using LocalRepo/Firebase for services in prototype

enum ServiceType { washFold, dryClean, ironing }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Service> services = [];
  ServiceType _selectedServiceType = ServiceType.washFold;
  Map<String, int> cart = {}; // serviceId -> quantity
  late AnimationController _statsController;
  late AnimationController _pulseController;
  
  // User statistics
  int _totalOrders = 0;
  int _activeOrders = 0;
  int _completedOrders = 0;

  @override
  void initState() {
    super.initState();
    services = LocalRepo.instance.listServices();
    _loadUserStats();
    
    // Initialize animation controllers
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _statsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadUserStats() {
    final user = LocalRepo.instance.currentUser;
    if (user != null) {
      final userOrders = LocalRepo.instance.listUserOrders(user.id);
      setState(() {
        _totalOrders = userOrders.length;
        _activeOrders = userOrders.where((o) => 
          o.status != OrderStatus.delivered && 
          o.status != OrderStatus.ready
        ).length;
        _completedOrders = userOrders.where((o) => 
          o.status == OrderStatus.delivered
        ).length;
      });
    }
  }

  void _addToCart(String serviceId) {
    setState(() {
      cart[serviceId] = (cart[serviceId] ?? 0) + 1;
    });
  }

  void _removeFromCart(String serviceId) {
    setState(() {
      if (cart[serviceId] != null && cart[serviceId]! > 0) {
        cart[serviceId] = cart[serviceId]! - 1;
        if (cart[serviceId] == 0) {
          cart.remove(serviceId);
        }
      }
    });
  }

  int _getCartQuantity(String serviceId) {
    return cart[serviceId] ?? 0;
  }

  int _getTotalItems() {
    return cart.values.fold(0, (sum, quantity) => sum + quantity);
  }

  void _proceedToOrder() {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to your cart first')),
      );
      return;
    }

    // Convert cart to OrderItems
    List<OrderItem> orderItems = [];
    cart.forEach((serviceId, quantity) {
      final service = services.firstWhere(
        (s) => s.id == serviceId,
        orElse: () => Service(id: serviceId, title: 'Unknown Service', description: '', basePrice: 0)
      );
      orderItems.add(OrderItem(
        name: '${service.title} (${_selectedServiceType.name})',
        quantity: quantity,
        price: service.basePrice,
      ));
    });

    Navigator.pushNamed(context, '/create-order', arguments: {
      'cartItems': orderItems,
      'serviceType': _selectedServiceType,
    });
  }

  Widget _buildAnimatedStatCard(String title, String value, IconData icon, Color color, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _statsController,
        curve: Interval(index * 0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeCard(String title, IconData icon, ServiceType type, Color color) {
    final isSelected = _selectedServiceType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedServiceType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4A5568),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
   final user = LocalRepo.instance.currentUser;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Alchemist Laundry',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF2D3748),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                IconButton(
                  onPressed: _proceedToOrder,
                  icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF4A5568)),
                ),
                if (_getTotalItems() > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.2),
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B6B),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '${_getTotalItems()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/orders');
                Future.delayed(const Duration(milliseconds: 300), _loadUserStats);
              },
              icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF4A5568)),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              icon: const Icon(Icons.person_outline, color: Color(0xFF4A5568)),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF7FAFC),
              Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadUserStats();
              return Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.waving_hand,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Good day!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (user != null)
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Statistics Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnimatedStatCard(
                          'Total Orders',
                          _totalOrders.toString(),
                          Icons.shopping_bag,
                          const Color(0xFF667EEA),
                          0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnimatedStatCard(
                          'Active',
                          _activeOrders.toString(),
                          Icons.local_shipping,
                          const Color(0xFFFBB040),
                          1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnimatedStatCard(
                          'Completed',
                          _completedOrders.toString(),
                          Icons.check_circle,
                          const Color(0xFF48BB78),
                          2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          'My Orders',
                          Icons.receipt_long,
                          const Color(0xFF667EEA),
                          () => Navigator.pushNamed(context, '/orders'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          'Call Support',
                          Icons.phone,
                          const Color(0xFF48BB78),
                          () => Navigator.pushNamed(context, '/customer-care'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Service Type Selector
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cleaning_services, color: Color(0xFF667EEA)),
                            SizedBox(width: 8),
                            Text(
                              'Choose Service Type',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildServiceTypeCard(
                              'Wash & Fold',
                              Icons.local_laundry_service,
                              ServiceType.washFold,
                              const Color(0xFF667EEA),
                            ),
                            const SizedBox(width: 12),
                            _buildServiceTypeCard(
                              'Dry Clean',
                              Icons.dry_cleaning,
                              ServiceType.dryClean,
                              const Color(0xFF764BA2),
                            ),
                            const SizedBox(width: 12),
                            _buildServiceTypeCard(
                              'Ironing',
                              Icons.iron,
                              ServiceType.ironing,
                              const Color(0xFFF093FB),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Services Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Services',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            color: Color(0xFF667EEA),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Services List
                  services.isEmpty
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No services available', style: TextStyle(color: Colors.black45)),
                        ))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: services.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final s = services[i];
                            final inCart = _getCartQuantity(s.id) > 0;
                            
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: inCart ? const Color(0xFF667EEA) : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: inCart 
                                        ? const Color(0xFF667EEA).withOpacity(0.2)
                                        : Colors.black.withOpacity(0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Thumbnail with gradient background
                                    Hero(
                                      tag: 'service_${s.id}',
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: s.imageUrl != null && s.imageUrl!.isNotEmpty
                                              ? Image.network(
                                                  s.imageUrl!,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stack) => Container(
                                                    color: Colors.white.withOpacity(0.2),
                                                    child: const Icon(Icons.image_not_supported, color: Colors.white70, size: 32),
                                                  ),
                                                )
                                              : Container(
                                                  color: Colors.white.withOpacity(0.2),
                                                  child: const Icon(Icons.local_laundry_service, color: Colors.white, size: 32),
                                                ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Title & description
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2D3748),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            s.description,
                                            style: const TextStyle(
                                              color: Color(0xFF718096),
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Price & quantity controls
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF667EEA).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'KES ${s.basePrice.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF667EEA),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(25),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Row(
                                            children: [
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () => _removeFromCart(s.id),
                                                  borderRadius: BorderRadius.circular(25),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    child: const Icon(Icons.remove, color: Color(0xFFFF6B6B), size: 20),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                child: Text(
                                                  '${_getCartQuantity(s.id)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF2D3748),
                                                  ),
                                                ),
                                              ),
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () => _addToCart(s.id),
                                                  borderRadius: BorderRadius.circular(25),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    child: const Icon(Icons.add, color: Color(0xFF48BB78), size: 20),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
