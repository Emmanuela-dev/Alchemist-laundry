import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/local_repo.dart';
import '../models/models.dart';

const _whatsappNumber = '254757952937';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  Future<void> _openWhatsApp(BuildContext context, String serviceName) async {
    final message = Uri.encodeComponent(
      'Hello! I\'m interested in your *$serviceName* service. Could you please provide more details?',
    );
    final url = Uri.parse('https://wa.me/$_whatsappNumber?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = LocalRepo.instance.listServices();

    final gradients = [
      [const Color(0xFFE91E8C), const Color(0xFFFF80AB)],
      [const Color(0xFFFF4081), const Color(0xFFFF80AB)],
      [const Color(0xFFFF80AB), const Color(0xFFFFB3D1)],
      [const Color(0xFFFFB3D1), const Color(0xFFFFD6E7)],
      [const Color(0xFFE91E8C), const Color(0xFFFF4081)],
      [const Color(0xFFFF4081), const Color(0xFFFFB3D1)],
      [const Color(0xFFFF80AB), const Color(0xFFFFD6E7)],
      [const Color(0xFFFFB3D1), const Color(0xFFFFE4F0)],
    ];

    final icons = [
      Icons.local_laundry_service,
      Icons.dry_cleaning,
      Icons.iron,
      Icons.delivery_dining,
      Icons.bed,
      Icons.king_bed,
      Icons.cleaning_services,
      Icons.home,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text('Our Services'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE91E8C), Color(0xFFFF80AB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE91E8C), Color(0xFFFF80AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What can we clean for you? ✨',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap any service then chat us on WhatsApp to book!',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _openWhatsApp(context, 'Laundry'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Chat Us on WhatsApp',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: services.isEmpty
                ? const Center(child: Text('No services available'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: services.length,
                    itemBuilder: (context, i) {
                      final s = services[i];
                      final gradient = gradients[i % gradients.length];
                      final icon = icons[i % icons.length];
                      return _ServiceCard(
                        service: s,
                        gradient: gradient,
                        icon: icon,
                        onWhatsApp: () => _openWhatsApp(context, s.title),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final List<Color> gradient;
  final IconData icon;
  final VoidCallback onWhatsApp;

  const _ServiceCard({
    required this.service,
    required this.gradient,
    required this.icon,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: service.imageUrl != null && service.imageUrl!.isNotEmpty
                  ? Image.network(
                      service.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconFallback(gradient, icon),
                    )
                  : _iconFallback(gradient, icon),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              service.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3748)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              service.description,
              style: const TextStyle(fontSize: 11, color: Color(0xFF718096)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'KES ${service.basePrice.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: GestureDetector(
              onTap: onWhatsApp,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.white, size: 15),
                    SizedBox(width: 6),
                    Text('Book via WhatsApp',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconFallback(List<Color> gradient, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 52),
    );
  }
}
