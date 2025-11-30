import 'package:flutter/material.dart';
import '../services/admin_numbers.dart';
import '../services/customer_care.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _controller = TextEditingController();
  List<String> _numbers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await AdminNumbers.load();
    setState(() => _numbers = list);
  }

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await AdminNumbers.add(text);
    _controller.clear();
    await _load();
  }

  Future<void> _remove(String n) async {
    await AdminNumbers.remove(n);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Settings')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          TextField(controller: _controller, decoration: const InputDecoration(labelText: 'Admin phone (+254716548186)', hintText: '+254716548186')),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _add, child: const Text('Add admin number')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              // open customer care editor
              final current = await CustomerCare.load();
              final phones = List<String>.from(current['phones'] as List<dynamic>);
              final email = current['email'] as String;
              final p1 = TextEditingController(text: phones.isNotEmpty ? phones[0] : '');
              final p2 = TextEditingController(text: phones.length > 1 ? phones[1] : '');
              final eCtrl = TextEditingController(text: email);
              final saved = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Customer Care'),
                content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(controller: p1, decoration: const InputDecoration(labelText: 'Phone 1 (e.g. +254716548186)')),
                    const SizedBox(height: 8),
                    TextField(controller: p2, decoration: const InputDecoration(labelText: 'Phone 2 (e.g. +254757952937)')),
                    const SizedBox(height: 8),
                    TextField(controller: eCtrl, decoration: const InputDecoration(labelText: 'Email (support@example.com)')),
                  ]),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () async {
                    final list = <String>[];
                    if (p1.text.trim().isNotEmpty) list.add(p1.text.trim());
                    if (p2.text.trim().isNotEmpty) list.add(p2.text.trim());
                    await CustomerCare.save(phones: list, email: eCtrl.text.trim());
                    Navigator.of(ctx).pop(true);
                  }, child: const Text('Save'))
                ],
              ));
              if (saved == true) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer care updated')));
              }
            },
            child: const Text('Edit Customer Care Contacts'),
          ),
          const SizedBox(height: 12),
          const Text('Configured admin numbers', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _numbers.length,
              itemBuilder: (context, i) {
                final n = _numbers[i];
                return ListTile(
                  title: Text(n),
                  trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _remove(n)),
                );
              },
            ),
          )
        ]),
      ),
    );
  }
}
