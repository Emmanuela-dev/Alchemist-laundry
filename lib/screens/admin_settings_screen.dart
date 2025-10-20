import 'package:flutter/material.dart';
import '../services/admin_numbers.dart';

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
