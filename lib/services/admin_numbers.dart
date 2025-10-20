import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminNumbers {
  static const _key = 'admin_numbers';

  // Read admin numbers from SharedPreferences. If none stored, return default list
  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<String> numbers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(numbers));
  }

  static Future<void> add(String number) async {
    final list = await load();
    if (!list.contains(number)) {
      list.add(number);
      await save(list);
    }
  }

  static Future<void> remove(String number) async {
    final list = await load();
    list.remove(number);
    await save(list);
  }
}
