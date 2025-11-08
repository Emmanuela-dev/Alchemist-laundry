import 'package:flutter/material.dart';
import '../services/local_repo.dart';
import '../models/models.dart';

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  List<Service> _services = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _services = LocalRepo.instance.listServices();
    });
  }

  Future<void> _showEdit([Service? s]) async {
    final title = TextEditingController(text: s?.title ?? '');
    final desc = TextEditingController(text: s?.description ?? '');
    final price = TextEditingController(text: s != null ? s.basePrice.toStringAsFixed(0) : '0');
    final img = TextEditingController(text: s?.imageUrl ?? '');

    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s == null ? 'Add service' : 'Edit service'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 8),
                TextFormField(controller: desc, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                TextFormField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Base price')),
                const SizedBox(height: 8),
                TextFormField(controller: img, decoration: const InputDecoration(labelText: 'Image URL (optional)')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () async {
                final t = title.text.trim();
                final d = desc.text.trim();
                final p = double.tryParse(price.text.trim()) ?? 0;
                final imageUrl = img.text.trim().isEmpty ? null : img.text.trim();
                if (t.isEmpty) return;
                final id = s?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
                final ns = Service(id: id, title: t, description: d, basePrice: p, imageUrl: imageUrl);
                if (s == null) {
                  await LocalRepo.instance.addService(ns);
                } else {
                  await LocalRepo.instance.updateService(ns);
                }
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Save'))
        ],
      ),
    );

    if (saved == true) _load();
  }

  Future<void> _delete(Service s) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete service'), content: Text('Delete "${s.title}"?'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete'))]));
    if (ok == true) {
      await LocalRepo.instance.deleteService(s.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Services')),
      body: _services.isEmpty
          ? const Center(child: Text('No services'))
          : ListView.builder(
              itemCount: _services.length,
              itemBuilder: (ctx, i) {
                final s = _services[i];
                return Card(
                  child: ListTile(
                    leading: s.imageUrl != null && s.imageUrl!.isNotEmpty
                        ? Image.network(s.imageUrl!, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))
                        : const Icon(Icons.local_laundry_service),
                    title: Text(s.title),
                    subtitle: Text('${s.description}\nKES ${s.basePrice.toStringAsFixed(0)}'),
                    isThreeLine: true,
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEdit(s)), IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(s))]),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showEdit(), child: const Icon(Icons.add)),
    );
  }
}
