import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseClientProvider {
  SupabaseClientProvider._();

  static SupabaseClient get client => Supabase.instance.client;
  static bool isReady = false;

  static Future<void> init() async {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      isReady = true;
    } catch (e) {
      // Env가 없는 등 초기화 실패 시 오프라인 모드로 동작
      isReady = false;
      // ignore: avoid_print
      print('Supabase init skipped: $e');
    }
  }
}


