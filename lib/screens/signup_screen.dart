 import 'package:flutter/material.dart';
import '../services/local_repo.dart';
import '../services/firebase_service.dart';
import '../models/models.dart';
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
  final _adminCode = TextEditingController();
  UserRole _selectedRole = UserRole.client;
  bool _loading = false;
  bool _showAdminCode = false;

  void _signup() async {
    setState(() {
      _loading = true;
    });
    try {
      // Validate admin code if admin role is selected
      if (_selectedRole == UserRole.admin) {
        if (FirebaseService.instance.ready) {
          final isValidCode = await FirebaseService.instance.validateAdminCode(_adminCode.text.trim());
          if (!isValidCode) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid admin code')),
            );
            return;
          }
        } else {
          // Fallback to hardcoded code for local repo
          if (_adminCode.text.trim() != 'ADMIN123') {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid admin code')),
            );
            return;
          }
        }
      }

      if (FirebaseService.instance.ready) {
        final cred = await FirebaseService.instance.signUp(_email.text.trim(), _password.text.trim());
        final uid = cred.user?.uid;
        if (uid != null) {
          await FirebaseService.instance.createUserDoc(uid, {
            'name': _name.text.trim(),
            'email': _email.text.trim(),
            'phone': '',
            'role': _selectedRole.name
          });
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
      } else {
        final user = await LocalRepo.instance.signup(_name.text, _email.text, _password.text);
        if (!mounted) return;
        final displayName = (user.name.isNotEmpty) ? user.name : _email.text.split('@').first;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome back, $displayName')));
        // give the user a moment to see the welcome message
        await Future.delayed(const Duration(milliseconds: 1200));
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ${e.toString()}')),
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
      appBar: AppBar(title: const Text('Sign up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 8),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            const Text('Account Type:', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<UserRole>(
                    title: const Text('Client'),
                    value: UserRole.client,
                    groupValue: _selectedRole,
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                        _showAdminCode = false;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<UserRole>(
                    title: const Text('Admin'),
                    value: UserRole.admin,
                    groupValue: _selectedRole,
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                        _showAdminCode = true;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_showAdminCode) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _adminCode,
                decoration: const InputDecoration(labelText: 'Admin Code'),
                obscureText: true,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loading ? null : _signup, child: _loading ? const CircularProgressIndicator() : const Text('Create account')),
          ]),
        ),
      ),
    );
  }
}
