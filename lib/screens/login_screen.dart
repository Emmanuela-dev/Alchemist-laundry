import 'package:flutter/material.dart';
import '../services/local_repo.dart';
import '../services/firebase_service.dart';
import '../models/models.dart';
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
  UserRole? _userRole;

  void _login() async {
    setState(() {
      _loading = true;
    });
    try {
      if (FirebaseService.instance.ready) {
        final cred = await FirebaseService.instance.signIn(_email.text.trim(), _password.text.trim());
        final uid = cred.user?.uid;
        if (uid != null) {
          final userDoc = await FirebaseService.instance.getUserProfile(uid);
          final data = userDoc.data() as Map<String, dynamic>?;
          final role = data?['role'] ?? 'client';
          _userRole = UserRole.values.firstWhere(
            (r) => r.name == role,
            orElse: () => UserRole.client,
          );
        }
      } else {
        await LocalRepo.instance.login(_email.text, _password.text);
        // For local repo, assume client role for now
        _userRole = UserRole.client;
      }
      if (!mounted) return;
      // Navigate based on role
      if (_userRole == UserRole.admin) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
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
