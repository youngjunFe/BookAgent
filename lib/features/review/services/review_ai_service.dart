import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
        final uri = Uri.parse('${AppConfig.agentBaseUrl}/api/generate-review');
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: '{"bookTitle": ${_escapeJson(bookTitle)}, "chatHistory": ${_escapeJson(chatHistory)}, "constraints": ${_escapeJson(_constraintsPrompt())}, "format": "json", "schema": {"title":"string","content":"string"}}',
        );
        if (resp.statusCode >= 200 && resp.statusCode < 300 && resp.body.isNotEmpty) {
          print('🔍 Railway API 응답: ${resp.body.substring(0, resp.body.length > 200 ? 200 : resp.body.length)}...');
          
          // JSON 응답 파싱 (강력한 처리)
          try {
            final data = json.decode(resp.body);
            if (data is Map && data['review'] is String) {
              final reviewContent = data['review'] as String;
              print('✅ JSON 파싱 성공: ${reviewContent.substring(0, reviewContent.length > 100 ? 100 : reviewContent.length)}...');
              return reviewContent;
            }
          } catch (e) {
            print('❌ JSON 파싱 실패: $e');
            print('❌ 원본 응답: ${resp.body}');
          }
          
          // JSON 파싱 실패 시 fallback 사용 (raw body 반환 금지)
          print('⚠️ JSON 파싱 실패, fallback 사용');
          return _fallback(bookTitle);
        }
      }

      // 우선 공식 invoke 시도
      try {
        final res = await Supabase.instance.client.functions.invoke(
          'generate_review',
          body: {
            'chat_history': chatHistory ?? '',
            'book_title': bookTitle ?? '',
            'constraints': _constraintsPrompt(),
          },
        );

        final data = res.data;
        if (data is Map && data['content'] is String) {
          final content = data['content'] as String;
          return _extractFromJsonOrRaw(content);
        }
        if (data is String && data.isNotEmpty) {
          return _extractFromJsonOrRaw(data);
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
          body: '{"chat_history": ${_escapeJson(chatHistory)}, "book_title": ${_escapeJson(bookTitle)}, "constraints": ${_escapeJson(_constraintsPrompt())}, "format": "json", "schema": {"title":"string","content":"string"}}',
        );
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final body = resp.body;
          if (body.isNotEmpty) {
            return _extractFromJsonOrRaw(body);
          }
        }
      } catch (_) {}
      return _fallback(bookTitle);
    } catch (_) {
      return _fallback(bookTitle);
    }
  }

  static String _fallback(String? bookTitle) {
    final title = (bookTitle == null || bookTitle.trim().isEmpty) ? '책' : bookTitle.trim();
    return '${title}에 대한 발제문\n\n'
        '첫 줄은 발제문 제목으로 간결하게 작성하고, 그 이후는 평문으로만 작성하세요.\n'
        '- 금지: 인사말 금지, "제목:" 금지, 서론/본론/결론 머리글 금지, 마크다운 기호 금지';
  }

  static String _escapeJson(String? value) {
    final v = (value ?? '').replaceAll('\\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n');
    return '"$v"';
  }

  static String _constraintsPrompt() {
    return '응답 형식은 JSON 객체 하나만: {"title": string, "content": string}. '\
           '- title: 60자 이하, 인사말/"제목:"/마크다운/따옴표 금지. '\
           '- content: 순수 평문 단락만; 서론/본론/결론/요약 등 머리글 금지, 마크다운(**, *, #, >, ```) 금지, 코드펜스, 리스트, 인사말 금지. '\
           '- 책 제목/저자 정보를 응답에 포함하지 말 것. '\
           '- JSON 외의 어떠한 텍스트(설명/코드펜스 등)도 추가하지 말 것.';
  }

  // Try to parse {title, content} JSON; if not JSON, return raw
  static String _extractFromJsonOrRaw(String raw) {
    try {
      final data = json.decode(raw);
      if (data is Map && data['title'] is String && data['content'] is String) {
        final title = (data['title'] as String).trim();
        final content = (data['content'] as String).trim();
        // Combine into a single string; the caller still sanitizes
        return '$title\n\n$content';
      }
    } catch (_) {}
    return raw;
  }
}


