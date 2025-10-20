import 'package:flutter/material.dart';
import '../services/local_repo.dart';
import '../services/firebase_service.dart';
// Supabase removed; using LocalRepo/Firebase for auth in prototype

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  void _signup() async {
    setState(() {
      _loading = true;
    });
    if (FirebaseService.instance.ready) {
      final cred = await FirebaseService.instance.signUp(_email.text.trim(), _password.text.trim());
      final uid = cred.user?.uid;
      if (uid != null) {
        await FirebaseService.instance.createUserDoc(uid, {'name': _name.text.trim(), 'email': _email.text.trim(), 'phone': ''});
      }
    } else {
      final user = await LocalRepo.instance.signup(_name.text, _email.text, _password.text);
      if (!mounted) return;
      final displayName = (user.name.isNotEmpty) ? user.name : _email.text.split('@').first;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome back, $displayName')));
      // give the user a moment to see the welcome message
      await Future.delayed(const Duration(milliseconds: 1200));
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 8),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loading ? null : _signup, child: _loading ? const CircularProgressIndicator() : const Text('Create account')),
        ]),
      ),
    );
  }
}
