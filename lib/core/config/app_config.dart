import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get supabaseUrl {
    final value = dotenv.env['SUPABASE_URL'];
    if (value == null || value.isEmpty) {
      throw StateError('Missing SUPABASE_URL in .env');
    }
    return value;
  }

  static String get supabaseAnonKey {
    final value = dotenv.env['SUPABASE_ANON_KEY'];
    if (value == null || value.isEmpty) {
      throw StateError('Missing SUPABASE_ANON_KEY in .env');
    }
    return value;
  }

  static String? get agentBaseUrl {
    final value = dotenv.env['AGENT_BASE_URL'];
    if (value == null || value.isEmpty) {
      // Railway 배포 URL로 변경
      return 'https://bookagent-production.up.railway.app';
    }
    return value;
  }
}


