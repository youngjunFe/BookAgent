import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../../features/auth/services/supabase_auth_service.dart';
import '../models/ebook.dart';

abstract class EBookApi {
  Future<List<EBook>> list();
  Future<EBook> create(EBook ebook);
  Future<EBook> update(EBook ebook);
  Future<void> delete(String id);
  Future<void> updateProgress({
    required String id,
    required int currentPage,
    required double progress,
    required DateTime lastReadAt,
  });
  Future<EBook> markAsCompleted(String id);
}

class SupabaseEBookApi implements EBookApi {
  SupabaseClient get _client => SupabaseClientProvider.client;
  final String _ebooksTable = 'ebooks';

  @override
  Future<List<EBook>> list() async {
    // 현재 로그인된 사용자 ID 가져오기
    final currentUser = SupabaseAuthService().currentUser;
    if (currentUser == null) {
      throw Exception('사용자 인증이 필요합니다');
    }
    
    // 현재 사용자의 전자책만 조회
    final response = await _client
        .from(_ebooksTable)
        .select()
        .eq('user_id', currentUser.id)  // 중요: 사용자별 필터링
        .order('last_read_at', ascending: false);
    
    return (response as List)
        .map((e) => _ebookFromRow(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<EBook> create(EBook ebook) async {
    // 현재 로그인된 사용자 ID 확인
    final currentUser = SupabaseAuthService().currentUser;
    if (currentUser == null) {
      throw Exception('사용자 인증이 필요합니다');
    }
    
    // 사용자 ID가 포함된 전자책 생성
    final ebookWithUserId = ebook.copyWith(userId: currentUser.id);
    final inserted = await _client
        .from(_ebooksTable)
        .insert(_ebookToInsertRow(ebookWithUserId))
        .select()
        .single();
    
    return _ebookFromRow(inserted as Map<String, dynamic>);
  }

  @override
  Future<EBook> update(EBook ebook) async {
    // 현재 로그인된 사용자 ID 확인
    final currentUser = SupabaseAuthService().currentUser;
    if (currentUser == null) {
      throw Exception('사용자 인증이 필요합니다');
    }
    
    // 자신의 전자책만 수정 가능
    final updated = await _client
        .from(_ebooksTable)
        .update(_ebookToRow(ebook))
        .eq('id', ebook.id)
        .eq('user_id', currentUser.id)  // 중요: 사용자 소유권 확인
        .select()
        .single();
    
    return _ebookFromRow(updated as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    // 현재 로그인된 사용자 ID 확인
    final currentUser = SupabaseAuthService().currentUser;
    if (currentUser == null) {
      throw Exception('사용자 인증이 필요합니다');
    }
    
    // 자신의 전자책만 삭제 가능
    await _client
        .from(_ebooksTable)
        .delete()
        .eq('id', id)
        .eq('user_id', currentUser.id);  // 중요: 사용자 소유권 확인
  }

  @override
  Future<void> updateProgress({
    required String id,
    required int currentPage,
    required double progress,
    required DateTime lastReadAt,
  }) async {
    try {
      // 현재 로그인된 사용자 ID 확인
      final currentUser = SupabaseAuthService().currentUser;
      if (currentUser == null) {
        throw Exception('사용자 인증이 필요합니다');
      }
      
      // 자신의 전자책만 진행률 업데이트 가능
      await _client
          .from(_ebooksTable)
          .update({
            'current_page': currentPage,
            'progress': progress,
            'last_read_at': lastReadAt.toIso8601String(),
          })
          .eq('id', id)
          .eq('user_id', currentUser.id);  // 중요: 사용자 소유권 확인
      
      print('✅ 진행률 업데이트 성공: $currentPage페이지, ${(progress * 100).toInt()}%');
    } catch (e) {
      print('❌ updateProgress 에러: $e (조용히 무시)');
      // 에러는 조용히 무시 - 더미 데이터 사용 중이므로
    }
  }

  @override
  Future<EBook> markAsCompleted(String id) async {
    // 현재 로그인된 사용자 ID 확인
    final currentUser = SupabaseAuthService().currentUser;
    if (currentUser == null) {
      throw Exception('사용자 인증이 필요합니다');
    }
    
    // 자신의 전자책만 완독 처리 가능
    final updated = await _client
        .from(_ebooksTable)
        .update({
          'progress': 1.0,
          'is_completed': true,
          'last_read_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', currentUser.id)  // 중요: 사용자 소유권 확인
        .select()
        .single();
    
    return _ebookFromRow(updated as Map<String, dynamic>);
  }

  // 변환 메서드들
  Map<String, dynamic> _ebookToRow(EBook ebook) {
    return {
      'id': ebook.id,
      'user_id': ebook.userId,  // 중요: 사용자 ID 포함
      'title': ebook.title,
      'author': ebook.author,
      'content': ebook.content,
      'cover_image_url': ebook.coverImageUrl,
      'added_at': ebook.addedAt.toIso8601String(),
      'last_read_at': ebook.lastReadAt?.toIso8601String(),
      'total_pages': ebook.totalPages,
      'current_page': ebook.currentPage,
      'progress': ebook.progress,
      'is_completed': ebook.isCompleted,
      'chapters': ebook.chapters,
    };
  }

  Map<String, dynamic> _ebookToInsertRow(EBook ebook) {
    final row = _ebookToRow(ebook);
    row.remove('id'); // Supabase will generate UUID
    return row;
  }

  EBook _ebookFromRow(Map<String, dynamic> row) {
    return EBook(
      id: row['id'] as String,
      userId: row['user_id'] as String,  // 중요: 사용자 ID 포함
      title: row['title'] as String,
      author: row['author'] as String,
      content: row['content'] as String,
      coverImageUrl: row['cover_image_url'] as String?,
      addedAt: DateTime.parse(row['added_at'] as String),
      lastReadAt: row['last_read_at'] != null
          ? DateTime.parse(row['last_read_at'] as String)
          : null,
      totalPages: row['total_pages'] as int,
      currentPage: row['current_page'] as int? ?? 0,
      progress: (row['progress'] as num?)?.toDouble() ?? 0.0,
      isCompleted: row['is_completed'] as bool? ?? false,
      chapters: (row['chapters'] as List?)?.cast<String>() ?? [],
    );
  }
}