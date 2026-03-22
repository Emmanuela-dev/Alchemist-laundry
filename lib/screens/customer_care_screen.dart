import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _whatsappNumber = '254757952937'; // Replace with actual WhatsApp number

class CustomerCareScreen extends StatelessWidget {
  const CustomerCareScreen({super.key});

  Future<void> _openWhatsApp(BuildContext context, String message) async {
    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$_whatsappNumber?text=$encoded');
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
    final quickMessages = [
      ('I want to place a laundry order', Icons.local_laundry_service),
      ('What are your prices?', Icons.price_check),
      ('Where are you located?', Icons.location_on),
      ('What are your working hours?', Icons.access_time),
      ('I have a complaint', Icons.report_problem_outlined),
      ('Track my order', Icons.track_changes),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 24,
              right: 24,
              bottom: 32,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF128C7E)],
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
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                const Text('Support & Contact',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('We\'re here to help! Chat with us on WhatsApp',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main WhatsApp button
                  GestureDetector(
                    onTap: () => _openWhatsApp(context, 'Hello! I need help with Alchemist Laundry.'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
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
                      child: const Column(
                        children: [
                          Icon(Icons.chat, color: Colors.white, size: 36),
                          SizedBox(height: 8),
                          Text('Chat on WhatsApp',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Tap to open WhatsApp',
                              style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text('Quick Messages',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                  const SizedBox(height: 4),
                  const Text('Tap to send a pre-filled message',
                      style: TextStyle(color: Color(0xFF718096), fontSize: 13)),
                  const SizedBox(height: 16),

                  ...quickMessages.map((item) => GestureDetector(
                        onTap: () => _openWhatsApp(context, item.$1),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(item.$2, color: const Color(0xFF25D366), size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(item.$1,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2D3748))),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF718096)),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
