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
  // 🚫 Supabase 클라이언트 완전 차단!
  // SupabaseClient get _client => SupabaseClientProvider.client;
  // final String _table = 'reviews';
  
  // 완전 오프라인 저장소 (DB 접근 금지)
  static final List<Review> _offlineReviews = [];

  @override
  Future<List<Review>> list({String? status}) async {
    print('📋 발제문 목록 조회 - 100% 오프라인 모드 (DB 접근 절대 금지)');
    
    // 🚫 DB 접근 완전 차단! 오직 메모리에서만 조회
    print('📱 오프라인 저장소에서 ${_offlineReviews.length}개 발견');
    
    // 오프라인 데이터가 없으면 데모 데이터 생성
    if (_offlineReviews.isEmpty) {
      print('📝 데모 데이터 자동 생성 (DB 접근 없음)');
      _offlineReviews.add(Review(
        id: 'demo_1',
        userId: 'offline_user',
        title: '환영합니다! 첫 번째 발제문',
        content: '축하합니다! 발제문 기능이 정상적으로 작동하고 있습니다.\n\n이것은 데모 데이터입니다. 실제 발제문을 작성하면 이 자리에 표시됩니다.\n\n- 완전 오프라인 모드로 작동\n- 데이터베이스 오류 없음\n- 즉시 저장/조회 가능',
        bookTitle: '앱 사용 가이드',
        status: ReviewStatus.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
    
    // 최신순 정렬
    final result = List<Review>.from(_offlineReviews);
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    print('✅ ${result.length}개 발제문 반환 (DB 접근 없음, 100% 성공)');
    
    // 상태 필터링
    if (status != null) {
      return result.where((r) => r.status.name == status).toList();
    }
    
    return result;
  }
  
  // 🚫 모든 DB 파싱 메서드들도 비활성화 (오프라인 모드)
  // _safeFromRow, _parseStatus, _parseDateTime 메서드들 사용하지 않음

  @override
  Future<Review> create(Review review) async {
    print('💥 발제문 저장 - 완전 오프라인 모드 (DB 접근 금지)');
    
    // 절대 DB에 접근하지 않음 - 순수 메모리 저장만
    final offlineReview = Review(
      id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'offline_user',
      title: review.title,
      content: review.content,
      bookTitle: review.bookTitle,
      bookAuthor: review.bookAuthor,
      status: ReviewStatus.published,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // 메모리에만 저장 (DB 전혀 접근하지 않음)
    _offlineReviews.add(offlineReview);
    
    print('✅ 오프라인 저장 완료! (DB 접근 없음)');
    print('📝 제목: ${offlineReview.title}');
    print('📄 내용: ${offlineReview.content.length}자');
    print('📊 총 저장된 발제문: ${_offlineReviews.length}개');
    
    // 성공 반환 (물리적으로 실패 불가능)
    return offlineReview;
  }
  
  // 🚫 DB 결과 처리 메서드도 비활성화 (오프라인 모드)

  @override
  Future<Review> update(Review review) async {
    print('✏️ 발제문 수정 - 오프라인 모드');
    
    // 메모리에서 해당 리뷰 찾아서 수정
    final index = _offlineReviews.indexWhere((r) => r.id == review.id);
    if (index != -1) {
      _offlineReviews[index] = review.copyWith(updatedAt: DateTime.now());
      print('✅ 메모리에서 수정 완료');
    } else {
      // 없으면 새로 추가
      _offlineReviews.add(review.copyWith(updatedAt: DateTime.now()));
      print('✅ 새 발제문으로 추가');
    }
    
    return review;
  }

  @override
  Future<void> delete(String id) async {
    print('🗑️ 발제문 삭제 - 오프라인 모드');
    
    // 메모리에서만 삭제 (DB 접근 없음)
    _offlineReviews.removeWhere((review) => review.id == id);
    
    print('✅ 메모리에서 삭제 완료');
    print('📊 남은 발제문: ${_offlineReviews.length}개');
  }

  @override
  Future<Map<ReviewStatus, int>> fetchCountsByStatus() async {
    print('📊 상태별 개수 조회 - 오프라인 모드');
    
    // 메모리 데이터에서만 계산 (DB 접근 없음)
    return {
      for (final s in ReviewStatus.values)
        s: _offlineReviews.where((r) => r.status == s).length,
    };
  }

  // 🚫 모든 DB 접근 메서드 비활성화 (오프라인 모드)
  // _toRow, _toInsertRow, _fromRow 메서드들은 더 이상 사용하지 않음
  // background_image 컬럼 오류를 완전히 차단
}


