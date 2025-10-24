import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  /// Jalankan ini di main.dart sebelum runApp()
  static Future<void> init() async {
    await Supabase.initialize(
      url:
          'https://pyedbocxchfvlafhuqdw.supabase.co', // ganti sesuai URL project
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5ZWRib2N4Y2hmdmxhZmh1cWR3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAyMTUzOTksImV4cCI6MjA3NTc5MTM5OX0.S2kC2Y0R2ok4-Lmlc3WDRbI_EX6Kmm1pegdl6FGicFM', // ganti sesuai anon key project
    );
  }

  /// Supabase client yang bisa dipakai di mana saja
  static SupabaseClient get client => Supabase.instance.client;
}
