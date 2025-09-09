import 'package:supabase_flutter/supabase_flutter.dart';

class AdminConfigService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // 설정값 가져오기
  static Future<String?> getConfig(String key) async {
    try {
      final response = await _supabase
          .from('admin_configs')
          .select('config_value')
          .eq('config_key', key)
          .eq('is_active', true)
          .single();

      return response['config_value'] as String?;
    } catch (e) {
      print('설정 로드 실패 ($key): $e');
      return null;
    }
  }

  // 여러 설정값 한번에 가져오기
  static Future<Map<String, String>> getConfigs(List<String> keys) async {
    try {
      final response = await _supabase
          .from('admin_configs')
          .select('config_key, config_value')
          .inFilter('config_key', keys)
          .eq('is_active', true);

      final Map<String, String> configs = {};
      for (final row in response) {
        configs[row['config_key'] as String] = row['config_value'] as String;
      }
      
      return configs;
    } catch (e) {
      print('설정 로드 실패: $e');
      return {};
    }
  }

  // 모든 설정값 가져오기 (카테고리별)
  static Future<Map<String, String>> getAllConfigsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('admin_configs')
          .select('config_key, config_value')
          .eq('category', category)
          .eq('is_active', true);

      final Map<String, String> configs = {};
      for (final row in response) {
        configs[row['config_key'] as String] = row['config_value'] as String;
      }
      
      return configs;
    } catch (e) {
      print('설정 로드 실패 ($category): $e');
      return {};
    }
  }

  // 설정값 저장하기
  static Future<bool> saveConfig(String key, String value, {String? description}) async {
    try {
      await _supabase
          .from('admin_configs')
          .upsert({
            'config_key': key,
            'config_value': value,
            'updated_at': DateTime.now().toIso8601String(),
            if (description != null) 'description': description,
          });

      return true;
    } catch (e) {
      print('설정 저장 실패 ($key): $e');
      return false;
    }
  }

  // 여러 설정값 한번에 저장하기
  static Future<bool> saveConfigs(Map<String, String> configs) async {
    try {
      final List<Map<String, dynamic>> updates = [];
      
      for (final entry in configs.entries) {
        updates.add({
          'config_key': entry.key,
          'config_value': entry.value,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      await _supabase.from('admin_configs').upsert(updates);
      return true;
    } catch (e) {
      print('설정 저장 실패: $e');
      return false;
    }
  }

  // 정수형 설정값 가져오기
  static Future<int?> getIntConfig(String key) async {
    final value = await getConfig(key);
    return value != null ? int.tryParse(value) : null;
  }

  // 정수형 설정값 저장하기
  static Future<bool> saveIntConfig(String key, int value) async {
    return await saveConfig(key, value.toString());
  }

  // 기본값과 함께 설정값 가져오기
  static Future<String> getConfigWithDefault(String key, String defaultValue) async {
    final value = await getConfig(key);
    return value ?? defaultValue;
  }

  // 기본값과 함께 정수형 설정값 가져오기
  static Future<int> getIntConfigWithDefault(String key, int defaultValue) async {
    final value = await getIntConfig(key);
    return value ?? defaultValue;
  }

  // AI 채팅 관련 설정들 한번에 가져오기
  static Future<Map<String, dynamic>> getChatSettings() async {
    try {
      final configs = await getConfigs([
        'ai_chat_prompt',
        'ai_welcome_message',
        'character_chat_prompt',
        'character_welcome_message_template',
        'review_generation_prompt',
        'min_chat_count',
        'max_chat_count',
      ]);

      return {
        'ai_chat_prompt': configs['ai_chat_prompt'] ?? '',
        'ai_welcome_message': configs['ai_welcome_message'] ?? '',
        'character_chat_prompt': configs['character_chat_prompt'] ?? '',
        'character_welcome_message_template': configs['character_welcome_message_template'] ?? '',
        'review_generation_prompt': configs['review_generation_prompt'] ?? '',
        'min_chat_count': int.tryParse(configs['min_chat_count'] ?? '10') ?? 10,
        'max_chat_count': int.tryParse(configs['max_chat_count'] ?? '15') ?? 15,
      };
    } catch (e) {
      print('채팅 설정 로드 실패: $e');
      return {
        'ai_chat_prompt': '',
        'ai_welcome_message': '',
        'character_chat_prompt': '',
        'character_welcome_message_template': '',
        'review_generation_prompt': '',
        'min_chat_count': 10,
        'max_chat_count': 15,
      };
    }
  }
}
