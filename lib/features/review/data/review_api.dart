import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../../features/auth/services/supabase_auth_service.dart';
import '../models/review.dart';

abstract class ReviewApi {
  Future<List<Review>> list({String? status});
  Future<Review> create(Review review);
  Future<Review> update(Review review);
  Future<void> delete(String id);
  Future<Map<ReviewStatus, int>> fetchCountsByStatus();
}

class SupabaseReviewApi implements ReviewApi {
  SupabaseClient get _client => SupabaseClientProvider.client;
  final String _table = 'reviews';

  @override
  Future<List<Review>> list({String? status}) async {
    print('📋 발제문 목록 조회 - Supabase 모드');
    
    try {
      final authService = SupabaseAuthService();
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        print('❌ 로그인되지 않은 사용자');
        return [];
      }
    
      var query = _client.from(_table).select().eq('user_id', currentUser.id);
    
      if (status != null) {
        query = query.eq('status', status);
      }
    
      final response = await query.order('created_at', ascending: false);
      final List<Review> reviews = (response as List).map((data) => _fromRow(data)).toList();
    
      print('✅ ${reviews.length}개 발제문 조회 성공');
      return reviews;
    } catch (e) {
      print('❌ 발제문 목록 조회 실패: $e');
      return [];
    }
  }
  
  Review _fromRow(Map<String, dynamic> row) {
    return Review(
      id: row['id'] ?? '',
      userId: row['user_id'] ?? '',
      title: row['title'] ?? '',
      content: row['content'] ?? '',
      bookTitle: row['book_title'] ?? '',
      bookAuthor: row['book_author'],
      status: _parseStatus(row['status']),
      createdAt: _parseDateTime(row['created_at']),
      updatedAt: _parseDateTime(row['updated_at']),
      chatHistory: row['chat_history'],
    );
  }

  ReviewStatus _parseStatus(String? status) {
    switch (status) {
      case 'draft':
        return ReviewStatus.draft;
      case 'completed':
        return ReviewStatus.completed;
      case 'published':
        return ReviewStatus.published;
      default:
        return ReviewStatus.draft;
    }
  }
    
  DateTime _parseDateTime(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> _toInsertRow(Review review, String userId) {
    return {
      'user_id': userId,
      'title': review.title,
      'content': review.content,
      'book_title': review.bookTitle,
      'book_author': review.bookAuthor,
      'status': review.status.name,
      'created_at': review.createdAt.toIso8601String(),
      'updated_at': review.updatedAt.toIso8601String(),
      'chat_history': review.chatHistory,
    };
  }

  @override
  Future<Review> create(Review review) async {
    print('💥 발제문 저장 - Supabase 모드');
    
    try {
      final authService = SupabaseAuthService();
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw Exception('로그인되지 않은 사용자');
      }

      final data = _toInsertRow(review, currentUser.id);
      final response = await _client.from(_table).insert(data).select().single();
      
      final savedReview = _fromRow(response);
      print('✅ Supabase 저장 완료!');
      print('📝 제목: ${savedReview.title}');
      print('📄 내용: ${savedReview.content.length}자');
      
      return savedReview;
    } catch (e) {
      print('❌ 발제문 저장 실패: $e');
      rethrow;
    }
  }
  
  @override
  Future<Review> update(Review review) async {
    print('✏️ 발제문 수정 - Supabase 모드');
    
    try {
      final authService = SupabaseAuthService();
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw Exception('로그인되지 않은 사용자');
      }

      final data = _toUpdateRow(review);
      final response = await _client.from(_table)
          .update(data)
          .eq('id', review.id)
          .eq('user_id', currentUser.id)
          .select()
          .single();
      
      final updatedReview = _fromRow(response);
      print('✅ Supabase 수정 완료');
      return updatedReview;
    } catch (e) {
      print('❌ 발제문 수정 실패: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    print('🗑️ 발제문 삭제 - Supabase 모드');
    
    try {
      final authService = SupabaseAuthService();
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw Exception('로그인되지 않은 사용자');
      }

      await _client.from(_table)
          .delete()
          .eq('id', id)
          .eq('user_id', currentUser.id);
      
      print('✅ Supabase 삭제 완료');
    } catch (e) {
      print('❌ 발제문 삭제 실패: $e');
      rethrow;
    }
  }

  @override
  Future<Map<ReviewStatus, int>> fetchCountsByStatus() async {
    print('📊 상태별 개수 조회 - Supabase 모드');
    
    try {
      final authService = SupabaseAuthService();
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        return {for (final s in ReviewStatus.values) s: 0};
      }

      final response = await _client.from(_table)
          .select('status')
          .eq('user_id', currentUser.id);
      
      final counts = <ReviewStatus, int>{};
      for (final status in ReviewStatus.values) {
        counts[status] = (response as List)
            .where((row) => row['status'] == status.name)
            .length;
      }
      
      print('✅ 상태별 개수 조회 완료');
      return counts;
    } catch (e) {
      print('❌ 상태별 개수 조회 실패: $e');
      return {for (final s in ReviewStatus.values) s: 0};
    }
  }

  Map<String, dynamic> _toUpdateRow(Review review) {
    return {
      'title': review.title,
      'content': review.content,
      'book_title': review.bookTitle,
      'book_author': review.bookAuthor,
      'status': review.status.name,
      'updated_at': DateTime.now().toIso8601String(),
      'chat_history': review.chatHistory,
    };
  }
}


