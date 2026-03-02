import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _supabaseUrl = 'https://pogqouxdsshsjaqwtwha.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBvZ3FvdXhkc3Noc2phcXd0d2hhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1MjAxMzQsImV4cCI6MjA3MzA5NjEzNH0.w1x7J6ZoDt2ieV6cuR4m0iJw3u_xpzm8xzs9GWG2OhI';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }
}
