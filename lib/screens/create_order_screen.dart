import 'package:flutter/material.dart';
import '../services/mock_repo.dart';
import '../models/models.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  String? serviceId;
  final _itemName = TextEditingController(text: 'Clothes');
  final _quantity = TextEditingController(text: '1');
  DateTime pickup = DateTime.now().add(const Duration(days: 1));
  DateTime delivery = DateTime.now().add(const Duration(days: 3));
  final _instructions = TextEditingController();
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    serviceId = args?['serviceId'] as String?;
  }

  Future<void> _pickDate(BuildContext ctx, bool isPickup) async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: ctx, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 30)));
    if (picked != null) {
      setState(() {
        if (isPickup) {
          pickup = picked;
        } else {
          delivery = picked;
        }
      });
    }
  }

  void _submit() async {
    setState(() {
      _loading = true;
    });
    final items = [OrderItem(name: _itemName.text, quantity: int.tryParse(_quantity.text) ?? 1, price: 2.5)];
    final order = await MockRepo.instance.createOrder(serviceId: serviceId ?? 's1', items: items, pickup: pickup, delivery: delivery, instructions: _instructions.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    Navigator.pushReplacementNamed(context, '/order', arguments: {'orderId': order.id});
  }

  @override
  Widget build(BuildContext context) {
    final service = serviceId != null ? MockRepo.instance.listServices().firstWhere((s) => s.id == serviceId, orElse: () => MockRepo.instance.listServices()[0]) : null;
    final header = service != null ? Text('Service: ${service.title}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)) : const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Create Order')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          header,
          const SizedBox(height: 8),
          TextField(controller: _itemName, decoration: const InputDecoration(labelText: 'Item name')),
          const SizedBox(height: 8),
          TextField(controller: _quantity, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('Pickup: ${pickup.toLocal().toString().split(' ')[0]}')),
            TextButton(onPressed: () => _pickDate(context, true), child: const Text('Change')),
          ],),
          Row(children: [
            Expanded(child: Text('Delivery: ${delivery.toLocal().toString().split(' ')[0]}')),
            TextButton(onPressed: () => _pickDate(context, false), child: const Text('Change')),
          ],),
          TextField(controller: _instructions, decoration: const InputDecoration(labelText: 'Special instructions')),const SizedBox(height: 16),
          ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator() : const Text('Place Order')),
        ]),
      ),
    );
  }
}
