import 'package:flutter/material.dart';
import '../services/local_repo.dart';
import '../models/models.dart';
import '../widgets/logo_widget.dart';
// Supabase removed; using LocalRepo/Firebase for services in prototype
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Service> services = [];

  @override
  void initState() {
    super.initState();
    if (FirebaseService.instance.ready) {
      FirebaseService.instance.firestore.collection('services').snapshots().listen((snap) {
        final list = snap.docs.map((d) => Service(id: d.id, title: d.get('title') ?? '', description: d.get('description') ?? '', basePrice: (d.get('basePrice') as num?)?.toDouble() ?? 0.0)).toList();
        setState(() => services = list);
      });
    } else {
      services = LocalRepo.instance.listServices();
    }
  }

  @override
  Widget build(BuildContext context) {
  final user = LocalRepo.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Laundry Home'), actions: [
        IconButton(onPressed: () => Navigator.pushNamed(context, '/orders'), icon: const Icon(Icons.history)),
        IconButton(onPressed: () => Navigator.pushNamed(context, '/profile'), icon: const Icon(Icons.person)),
        IconButton(onPressed: () => Navigator.pushNamed(context, '/admin'), icon: const Icon(Icons.dashboard)),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const LogoWidget(size: 72),
            const SizedBox(width: 12),
            if (user != null) Text('Welcome, ${user.name}!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),

          // Services header with a soft pastel subtitle
          const Text('Services', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Choose a service to create an order', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),

          // Card-like container with light background for the services list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF7FBFF), Color(0xFFFFF7FB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/images/washing_machine.png'),
                  fit: BoxFit.contain,
                  opacity: 0.18,
                  alignment: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: services.isEmpty
                  ? const Center(child: Text('No services available', style: TextStyle(color: Colors.black45)))
                  : ListView.separated(
                      itemCount: services.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final s = services[i];
                        return Material(
                          color: Colors.white,
                          elevation: 2,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => Navigator.pushNamed(context, '/create-order', arguments: {'serviceId': s.id}),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(s.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Text(s.description, style: const TextStyle(color: Colors.black54)),
                                  ]),
                                ),
                                const SizedBox(width: 8),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('KES ${s.basePrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(color: const Color(0xFFFFC1E3), borderRadius: BorderRadius.circular(6)),
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                    child: const Text('Order', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                                  ),
                                ])
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}
