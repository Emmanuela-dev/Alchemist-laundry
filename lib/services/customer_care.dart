import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerCare {
  static const _key = 'customer_care';

  // returns {'phones': List<String>, 'email': String}
  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {'phones': <String>[], 'email': ''};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final phones = (m['phones'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];
      final email = m['email']?.toString() ?? '';
      return {'phones': phones, 'email': email};
    } catch (_) {
      return {'phones': <String>[], 'email': ''};
    }
  }

  static Future<void> save({required List<String> phones, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {'phones': phones, 'email': email};
    await prefs.setString(_key, jsonEncode(map));
  }

  static Future<void> setPhones(List<String> phones) async => save(phones: phones, email: (await load())['email'] as String);
  static Future<void> setEmail(String email) async => save(phones: (await load())['phones'] as List<String>, email: email);
}
