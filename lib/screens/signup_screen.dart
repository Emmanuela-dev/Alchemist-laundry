import 'package:flutter/material.dart';
import '../services/local_repo.dart';
import '../services/firebase_service.dart';
import '../models/models.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  Future<void> _signup() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String phone = _phone.text.trim();
      if (!phone.startsWith('+')) {
        phone = '+254${phone.startsWith('0') ? phone.substring(1) : phone}';
      }

      if (FirebaseService.instance.ready) {
        final credential = await FirebaseService.instance.signUp(
          _email.text.trim(),
          _password.text.trim(),
        );
        final uid = credential.user!.uid;

        await FirebaseService.instance.createUserDoc(uid, {
          'id': uid,
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'phone': phone,
          'role': 'client',
          'createdAt': DateTime.now().toIso8601String(),
        });

        final user = UserProfile(
          id: uid,
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: phone,
          role: UserRole.client,
        );
        await LocalRepo.instance.setCurrentUser(user);
      } else {
        final userId = DateTime.now().microsecondsSinceEpoch.toString();
        final user = UserProfile(
          id: userId,
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: phone,
          role: UserRole.client,
        );
        await LocalRepo.instance.setCurrentUser(user);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${_name.text.trim()}! 🎉 Please sign in.'),
          backgroundColor: const Color(0xFFE91E8C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF4081), Color(0xFFE91E8C), Color(0xFFFF80AB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.local_laundry_service, color: Color(0xFFE91E8C), size: 40),
                ),
                const SizedBox(height: 12),
                const Text('Alchemist Laundry',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Create Account',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                      const SizedBox(height: 4),
                      const Text('Join us and get fresh laundry!',
                          style: TextStyle(color: Color(0xFF718096), fontSize: 14)),
                      const SizedBox(height: 24),

                      _field(_name, 'Full Name', Icons.person_outline),
                      const SizedBox(height: 14),
                      _field(_email, 'Email Address', Icons.email_outlined,
                          type: TextInputType.emailAddress),
                      const SizedBox(height: 14),
                      _field(_phone, 'Phone Number', Icons.phone_outlined,
                          type: TextInputType.phone),
                      const SizedBox(height: 14),
                      _passField(_password, 'Password', _obscurePass,
                          () => setState(() => _obscurePass = !_obscurePass)),
                      const SizedBox(height: 14),
                      _passField(_confirm, 'Confirm Password', _obscureConfirm,
                          () => setState(() => _obscureConfirm = !_obscureConfirm)),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E8C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _loading
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Create Account',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ',
                              style: TextStyle(color: Color(0xFF718096))),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: const Text('Sign In',
                                style: TextStyle(
                                    color: Color(0xFFE91E8C), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFE91E8C)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _passField(TextEditingController ctrl, String label, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFE91E8C)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
