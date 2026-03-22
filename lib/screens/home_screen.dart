import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/local_repo.dart';
import 'services_screen.dart';
import 'profile_screen.dart';
import 'customer_care_screen.dart';

const _whatsappNumber = '254757952937';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _HomePage(),
    ServicesScreen(),
    CustomerCareScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFE91E8C),
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.cleaning_services_outlined), activeIcon: Icon(Icons.cleaning_services), label: 'Services'),
            BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), activeIcon: Icon(Icons.support_agent), label: 'Support'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  Future<void> _openWhatsApp(BuildContext context) async {
    final message = Uri.encodeComponent(
      'Hello! I\'d like to enquire about your laundry services.',
    );
    final url = Uri.parse('https://wa.me/$_whatsappNumber?text=$message');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = LocalRepo.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 24,
                right: 24,
                bottom: 36,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE91E8C), Color(0xFFFF80AB), Color(0xFFFF4081)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.name.split(' ').first ?? 'there'} 👋',
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const Text(
                            'Alchemist Laundry',
                            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_laundry_service, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Professional cleaning • Fast delivery • Quality guaranteed',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // WhatsApp CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () => _openWhatsApp(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Order via WhatsApp',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Why choose us
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Why Choose Us?',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _featureCard('Fast\nDelivery', Icons.delivery_dining,
                          [const Color(0xFFE91E8C), const Color(0xFFFF80AB)]),
                      const SizedBox(width: 12),
                      _featureCard('Quality\nCleaning', Icons.verified,
                          [const Color(0xFFFF4081), const Color(0xFFFF80AB)]),
                      const SizedBox(width: 12),
                      _featureCard('Best\nPrices', Icons.price_check,
                          [const Color(0xFFFF80AB), const Color(0xFFFFB3D1)]),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Services preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Our Services',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                  GestureDetector(
                    onTap: () {
                      final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                      homeState?.setState(() => homeState._currentIndex = 1);
                    },
                    child: const Text('See All',
                        style: TextStyle(color: Color(0xFFE91E8C), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ServicesPreview(),

            const SizedBox(height: 32),

            // How it works
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How It Works',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                  const SizedBox(height: 16),
                  _stepCard('1', 'Browse Services', 'Check out our services and prices below',
                      const Color(0xFFE91E8C)),
                  _stepCard('2', 'Chat on WhatsApp', 'Send us a message with what you need',
                      const Color(0xFFFF4081)),
                  _stepCard('3', 'We Pick Up', 'We collect your laundry from your location',
                      const Color(0xFFFF80AB)),
                  _stepCard('4', 'Fresh Delivery', 'Get your clean clothes delivered back to you',
                      const Color(0xFFFFB3D1)),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _featureCard(String label, IconData icon, List<Color> colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: colors[0].withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _stepCard(String step, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(step,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3748))),
                Text(subtitle, style: const TextStyle(color: Color(0xFF718096), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final services = LocalRepo.instance.listServices().take(4).toList();
    final gradients = [
      [const Color(0xFFE91E8C), const Color(0xFFFF80AB)],
      [const Color(0xFFFF4081), const Color(0xFFFF80AB)],
      [const Color(0xFFFF80AB), const Color(0xFFFFB3D1)],
      [const Color(0xFFFFB3D1), const Color(0xFFFFD6E7)],
    ];
    final icons = [
      Icons.local_laundry_service,
      Icons.dry_cleaning,
      Icons.iron,
      Icons.delivery_dining,
    ];

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: services.length,
        itemBuilder: (context, i) {
          final s = services[i];
          final g = gradients[i % gradients.length];
          return GestureDetector(
            onTap: () {
              final homeState = context.findAncestorStateOfType<_HomeScreenState>();
              homeState?.setState(() => homeState._currentIndex = 1);
            },
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: g, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: g[0].withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icons[i % icons.length], color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(s.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 4),
                  Text('KES ${s.basePrice.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
