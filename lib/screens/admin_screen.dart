import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/local_repo.dart';
import '../services/firebase_service.dart';
import '../models/models.dart';
import 'admin_settings_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  List<Order> orders = [];
  List<Order> filteredOrders = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  late AnimationController _metricsController;
  late AnimationController _chartController;

  // Dashboard metrics
  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _readyOrders = 0;
  double _totalRevenue = 0.0;
  int _todayOrders = 0;
  double _yesterdayRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _metricsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _metricsController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (FirebaseService.instance.ready) {
        // Load from Firebase for real-time data
        final ordersSnapshot = await FirebaseService.instance.firestore.collection('orders').get();
        orders = ordersSnapshot.docs.map((doc) {
          final data = doc.data();
          return Order(
            id: doc.id,
            userId: data['userId'] ?? '',
            serviceId: data['serviceId'] ?? '',
            items: (data['items'] as List<dynamic>? ?? []).map((item) => OrderItem(
              name: item['name'] ?? '',
              quantity: item['quantity'] ?? 1,
              price: (item['price'] as num?)?.toDouble() ?? 0.0,
            )).toList(),
            pickupTime: DateTime.parse(data['pickupTime'] ?? DateTime.now().toIso8601String()),
            deliveryTime: DateTime.parse(data['deliveryTime'] ?? DateTime.now().toIso8601String()),
            instructions: data['instructions'] ?? '',
            status: OrderStatus.values.firstWhere(
              (s) => s.name == (data['status'] ?? 'pending'),
              orElse: () => OrderStatus.pending,
            ),
            total: (data['total'] as num?)?.toDouble() ?? 0.0,
            latitude: (data['latitude'] as num?)?.toDouble(),
            longitude: (data['longitude'] as num?)?.toDouble(),
            paymentMethod: data['paymentMethod'],
            paymentStatus: data['paymentStatus'],
          );
        }).toList();
      } else {
        // Fallback to local repo
        orders = LocalRepo.instance.listAllOrders();
      }

      _calculateMetrics();
      _applyFilter(_selectedFilter);
      _metricsController.forward();
      _chartController.forward();
    } catch (e) {
      print('Error loading admin data: $e');
      // Fallback to local data
      orders = LocalRepo.instance.listAllOrders();
      _calculateMetrics();
      _applyFilter(_selectedFilter);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _calculateMetrics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    _totalOrders = orders.length;
    _pendingOrders = orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.pickedUp).length;
    _readyOrders = orders.where((o) => o.status == OrderStatus.ready).length;
    _totalRevenue = orders.where((o) => o.paymentStatus == 'completed').fold(0.0, (sum, o) => sum + o.total);
    _todayOrders = orders.where((o) => o.pickupTime.isAfter(today)).length;
    _yesterdayRevenue = orders
        .where((o) => o.pickupTime.isAfter(yesterday) && o.pickupTime.isBefore(today) && o.paymentStatus == 'completed')
        .fold(0.0, (sum, o) => sum + o.total);
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case 'pending':
          filteredOrders = orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.pickedUp).toList();
          break;
        case 'ready':
          filteredOrders = orders.where((o) => o.status == OrderStatus.ready).toList();
          break;
        case 'delivered':
          filteredOrders = orders.where((o) => o.status == OrderStatus.delivered).toList();
          break;
        case 'active':
          filteredOrders = orders.where((o) => o.status != OrderStatus.delivered).toList();
          break;
        default:
          filteredOrders = List.from(orders);
      }
    });
  }

  void _refresh() {
    _metricsController.reset();
    _chartController.reset();
    _loadData();
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.pickedUp:
        return Colors.blue;
      case OrderStatus.inWashing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.outForDelivery:
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.grey;
    }
  }

  Widget _buildAnimatedMetricCard(String title, String value, IconData icon, Color color, int index, {String? trend}) {
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _metricsController,
        curve: Interval(index * 0.15, 1.0, curve: Curves.easeOut),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          trend.startsWith('+') ? Icons.trending_up : Icons.trending_down,
                          size: 14,
                          color: trend.startsWith('+') ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trend,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: trend.startsWith('+') ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOut,
              builder: (context, animValue, child) {
                return Text(
                  value.contains('KES') ? 'KES ${animValue.toStringAsFixed(0)}' : animValue.toInt().toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF718096),
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

  Widget _buildRevenueChart() {
    // Calculate daily revenue for the last 7 days
    final now = DateTime.now();
    final chartData = <FlSpot>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final dayRevenue = orders
          .where((o) => 
            o.pickupTime.isAfter(dayStart) && 
            o.pickupTime.isBefore(dayEnd) &&
            o.paymentStatus == 'completed'
          )
          .fold(0.0, (sum, o) => sum + o.total);
      
      chartData.add(FlSpot((6 - i).toDouble(), dayRevenue));
    }

    return AnimatedBuilder(
      animation: _chartController,
      builder: (context, child) {
        return Opacity(
          opacity: _chartController.value,
          child: Container(
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
                    Icon(Icons.show_chart, color: Color(0xFF667EEA)),
                    SizedBox(width: 8),
                    Text(
                      '7-Day Revenue Trend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1000,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (value.toInt() >= 0 && value.toInt() < days.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    days[value.toInt()],
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            interval: 2000,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${(value / 1000).toStringAsFixed(1)}K',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: chartData.isEmpty ? 5000 : chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartData,
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: const Color(0xFF667EEA),
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF667EEA).withOpacity(0.3),
                                const Color(0xFF667EEA).withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _applyFilter(value),
      selectedColor: const Color(0xFF667EEA),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4A5568),
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade300,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final revenueChange = _yesterdayRevenue > 0
        ? (((_totalRevenue - _yesterdayRevenue) / _yesterdayRevenue) * 100).toStringAsFixed(1)
        : '0.0';
    final revenueTrend = _totalRevenue >= _yesterdayRevenue ? '+$revenueChange%' : '$revenueChange%';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4A5568)),
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2, color: Color(0xFF4A5568)),
            onPressed: () => Navigator.pushNamed(context, '/admin-services'),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF4A5568)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Color(0xFF4A5568)),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard Metrics
                    const Text(
                      'Today\'s Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metrics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnimatedMetricCard(
                            'Total Orders',
                            _totalOrders.toString(),
                            Icons.shopping_cart,
                            const Color(0xFF667EEA),
                            0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAnimatedMetricCard(
                            'Pending',
                            _pendingOrders.toString(),
                            Icons.pending,
                            Colors.orange,
                            1,
                            trend: _todayOrders > 0 ? '+$_todayOrders' : '0',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnimatedMetricCard(
                            'Ready',
                            _readyOrders.toString(),
                            Icons.check_circle,
                            Colors.green,
                            2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAnimatedMetricCard(
                            'Revenue',
                            'KES ${_totalRevenue.toStringAsFixed(0)}',
                            Icons.attach_money,
                            const Color(0xFF48BB78),
                            3,
                            trend: revenueTrend,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Revenue Chart
                    _buildRevenueChart(),

                    const SizedBox(height: 32),

                    // Filter Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Orders',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          '${filteredOrders.length} of $_totalOrders',
                          style: const TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Filter Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip('All', 'all'),
                        _buildFilterChip('Active', 'active'),
                        _buildFilterChip('Pending', 'pending'),
                        _buildFilterChip('Ready', 'ready'),
                        _buildFilterChip('Delivered', 'delivered'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (filteredOrders.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
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
                        child: const Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Color(0xFFCBD5E0),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No orders found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A5568),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try changing the filter',
                              style: TextStyle(
                                color: Color(0xFF718096),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, i) {
                          final o = filteredOrders[i];
                          final statusColor = _getStatusColor(o.status);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [statusColor.withOpacity(0.8), statusColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getStatusIcon(o.status),
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                'Order ${o.id.substring(0, 8)}...',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          o.status.name.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'KES ${o.total.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Color(0xFF48BB78),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pickup: ${o.pickupTime.toLocal().toString().split(' ')[0]}',
                                    style: const TextStyle(
                                      color: Color(0xFF718096),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (o.latitude != null && o.longitude != null)
                                    IconButton(
                                      icon: Icon(Icons.map, color: statusColor),
                                      onPressed: () async {
                                        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${o.latitude},${o.longitude}');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                    ),
                                  PopupMenuButton<OrderStatus>(
                                    onSelected: (s) async {
                                      try {
                                        if (FirebaseService.instance.ready) {
                                          await FirebaseService.instance.updateOrderStatus(o.id, s.name);
                                        } else {
                                          await LocalRepo.instance.updateOrderStatus(o.id, s);
                                        }
                                        _refresh();
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to update status: $e')),
                                        );
                                      }
                                    },
                                    itemBuilder: (ctx) => OrderStatus.values.map((s) =>
                                      PopupMenuItem(value: s, child: Text(s.name))
                                    ).toList(),
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.pushNamed(context, '/order', arguments: {'orderId': o.id}),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.pickedUp:
        return Icons.local_shipping;
      case OrderStatus.inWashing:
        return Icons.wash;
      case OrderStatus.ready:
        return Icons.check_circle;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.done_all;
    }
  }
}
