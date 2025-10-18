class SupabaseConfig {
  // Fill these with your Supabase project values to enable real auth
  // Example:
  // static const String url = 'https://xyzcompany.supabase.co';
  // static const String anonKey = 'public-anon-key';
  static const String url = '';
  static const String anonKey = '';

  static bool get enabled => url.isNotEmpty && anonKey.isNotEmpty;
}
