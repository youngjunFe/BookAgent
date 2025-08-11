import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/config/app_config.dart';

class ReviewAiService {
  ReviewAiService._();

  // Supabase Edge Function: generate_review
  static Future<String> generateReview({
    String? chatHistory,
    String? bookTitle,
  }) async {
    if (!SupabaseClientProvider.isReady) {
      return _fallback(bookTitle);
    }

    try {
      // 1) 우선 Railway 등 외부 Agent 서비스가 설정된 경우 우선 사용
      if (AppConfig.agentBaseUrl != null) {
        final uri = Uri.parse('${AppConfig.agentBaseUrl}/generate-review');
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: '{"chat_history": ${_escapeJson(chatHistory)}, "book_title": ${_escapeJson(bookTitle)}}',
        );
        if (resp.statusCode >= 200 && resp.statusCode < 300 && resp.body.isNotEmpty) {
          return resp.body;
        }
      }

      // 우선 공식 invoke 시도
      try {
        final res = await Supabase.instance.client.functions.invoke(
          'generate_review',
          body: {
            'chat_history': chatHistory ?? '',
            'book_title': bookTitle ?? '',
          },
        );

        final data = res.data;
        if (data is Map && data['content'] is String) {
          return data['content'] as String;
        }
        if (data is String && data.isNotEmpty) {
          return data;
        }
      } catch (_) {
        // 아래 HTTP 폴백 시도
      }

      // HTTP 폴백 (anon key 사용)
      try {
        final url = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/generate_review');
        final resp = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
          body: '{"chat_history": ${_escapeJson(chatHistory)}, "book_title": ${_escapeJson(bookTitle)}}',
        );
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final body = resp.body;
          if (body.isNotEmpty) {
            return body;
          }
        }
      } catch (_) {}
      return _fallback(bookTitle);
    } catch (_) {
      return _fallback(bookTitle);
    }
  }

  static String _fallback(String? bookTitle) {
    return '${bookTitle ?? '책'}에 대한 발제문\n\n'
        '이 작품을 읽으며 가장 인상 깊었던 지점과 질문들을 정리해보세요.\n'
        '1) 핵심 메시지\n2) 인물의 변화\n3) 나의 관점 변화';
  }

  static String _escapeJson(String? value) {
    final v = (value ?? '').replaceAll('\\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n');
    return '"$v"';
  }
}


