import 'package:flutter/material.dart';
import '../services/local_repo.dart';
import '../services/firebase_service.dart';
// Supabase removed; using LocalRepo/Firebase for auth in prototype

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  void _login() async {
    setState(() {
      _loading = true;
    });
    try {
      if (FirebaseService.instance.ready) {
        await FirebaseService.instance.signIn(_email.text.trim(), _password.text.trim());
      } else {
        await LocalRepo.instance.login(_email.text, _password.text);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loading ? null : _login, child: _loading ? const CircularProgressIndicator() : const Text('Login')),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/signup'), child: const Text('Create account')),
        ]),
      ),
    );
  }
}
