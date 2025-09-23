import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  /// Jalankan ini di main.dart sebelum runApp()
  static Future<void> init() async {
    await Supabase.initialize(
      url:
          'https://qijvvjuewmigqbkiigyf.supabase.co', // ganti sesuai URL project
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFpanZ2anVld21pZ3Fia2lpZ3lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1NjIwMTgsImV4cCI6MjA3NDEzODAxOH0.vowvkP8jBQn-IOGLarr5DXhkZOyXdV4yXDkkiDQvCxI', // ganti sesuai anon key project
    );
  }

  /// Supabase client yang bisa dipakai di mana saja
  static SupabaseClient get client => Supabase.instance.client;
}
