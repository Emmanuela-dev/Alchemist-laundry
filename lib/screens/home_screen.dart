import 'package:flutter/material.dart';
import '../services/mock_repo.dart';
import '../models/models.dart';
import '../widgets/logo_widget.dart';

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
    services = MockRepo.instance.listServices();
  }

  @override
  Widget build(BuildContext context) {
    final user = MockRepo.instance.currentUser;
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
          const Text('Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, i) {
                final s = services[i];
                return Card(
                  child: ListTile(
                    title: Text(s.title),
                    subtitle: Text(s.description),
                    trailing: Text('\$${s.basePrice.toStringAsFixed(2)}'),
                    onTap: () => Navigator.pushNamed(context, '/create-order', arguments: {'serviceId': s.id}),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
