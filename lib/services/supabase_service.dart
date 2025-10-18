import 'supabase_config.dart';
import '../models/models.dart';

String formatKES(num value) {
  return 'KES ${value.toStringAsFixed(0)}';
}

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  // This file provides a no-op stub implementation so the app can compile
  // when `supabase_flutter` is not added to pubspec.yaml (we removed it for
  // faster local builds). If you later add `supabase_flutter`, restore the
  // original implementation and re-add the import at the top of this file.

  Future<void> init() async {
    // Nothing to do when supabase is not available.
    return;
  }

  bool get ready => false;

  Future<dynamic> signUp(String email, String password) async {
    if (!SupabaseConfig.enabled) return null;
    throw StateError('Supabase is enabled in config but supabase_flutter is not available. Add supabase_flutter to pubspec.yaml to enable.');
  }

  Future<dynamic> signIn(String email, String password) async {
    if (!SupabaseConfig.enabled) return null;
    throw StateError('Supabase is enabled in config but supabase_flutter is not available. Add supabase_flutter to pubspec.yaml to enable.');
  }

  Future<List<Service>> listServices() async {
    if (!SupabaseConfig.enabled) return [];
    throw StateError('Supabase is enabled in config but supabase_flutter is not available. Add supabase_flutter to pubspec.yaml to enable.');
  }

  Future<Map<String, dynamic>?> createOrder(String userId, String serviceId, List<Map<String, dynamic>> items, DateTime pickup, DateTime delivery, String instructions, num total) async {
    if (!SupabaseConfig.enabled) return null;
    throw StateError('Supabase is enabled in config but supabase_flutter is not available. Add supabase_flutter to pubspec.yaml to enable.');
  }

  Future<List<Map<String, dynamic>>> listOrdersForUser(String userId) async {
    if (!SupabaseConfig.enabled) return [];
    throw StateError('Supabase is enabled in config but supabase_flutter is not available. Add supabase_flutter to pubspec.yaml to enable.');
  }

  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    if (!SupabaseConfig.enabled) return null;
    throw StateError('Supabase is enabled in config but supabase_flutter is not available. Add supabase_flutter to pubspec.yaml to enable.');
  }

  Future<void> addComment(String orderId, String userId, String text, int rating) async {
    if (!SupabaseConfig.enabled) return;
    throw StateError('Supabase is enabled in config but supabase_flutter is not available. Add supabase_flutter to pubspec.yaml to enable.');
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    if (!SupabaseConfig.enabled) return;
    throw StateError('Supabase is enabled in config but supabase_flutter is not available. Add supabase_flutter to pubspec.yaml to enable.');
  }
}
