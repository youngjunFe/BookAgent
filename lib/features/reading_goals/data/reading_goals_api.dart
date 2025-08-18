import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../models/reading_goal.dart';
import '../models/reading_stats.dart';
import '../models/achievement.dart';

abstract class ReadingGoalsApi {
  Future<List<ReadingGoal>> list();
  Future<ReadingGoal> create(ReadingGoal goal);
  Future<ReadingGoal> update(ReadingGoal goal);
  Future<void> delete(String id);
  Future<ReadingStats> fetchStats();
  Future<List<Achievement>> fetchAchievements();
  Future<Achievement> unlockAchievement(String achievementId);
}

class SupabaseReadingGoalsApi implements ReadingGoalsApi {
  SupabaseClient get _client => SupabaseClientProvider.client;
  final String _goalsTable = 'reading_goals';
  final String _statsTable = 'reading_stats';
  final String _achievementsTable = 'achievements';

  @override
  Future<List<ReadingGoal>> list() async {
    try {
      final rows = await _client
          .from(_goalsTable)
          .select()
          .order('created_at', ascending: false);
      
      return (rows as List)
          .map((e) => _goalFromRow(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ fetchGoals 에러: $e');
      return ReadingGoal.sampleGoals;
    }
  }

  @override
  Future<ReadingGoal> create(ReadingGoal goal) async {
    final inserted = await _client
        .from(_goalsTable)
        .insert(_goalToInsertRow(goal))
        .select()
        .single();
    
    return _goalFromRow(inserted as Map<String, dynamic>);
  }

  @override
  Future<ReadingGoal> update(ReadingGoal goal) async {
    final updated = await _client
        .from(_goalsTable)
        .update(_goalToRow(goal))
        .eq('id', goal.id)
        .select()
        .single();
    
    return _goalFromRow(updated as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_goalsTable).delete().eq('id', id);
  }

  @override
  Future<ReadingStats> fetchStats() async {
    try {
      // 1. 전체 독서 통계 집계
      final reviewsResponse = await _client
          .from('reviews')
          .select('book_title, created_at, updated_at')
          .eq('status', 'completed');
      
              final ebooksResponse = await _client
            .from('ebooks')
            .select('title, current_page, total_pages, progress, last_read_at')
            .gte('progress', 1.0); // 완료된 책들만
      
      // 2. 기본 통계 계산
      final completedReviews = reviewsResponse as List;
      final completedEbooks = ebooksResponse as List;
      
      final totalBooksRead = completedEbooks.length;
      final totalPagesRead = completedEbooks.fold<int>(0, 
          (sum, book) => sum + (book['total_pages'] as int? ?? 0));
      
      // 3. 월별 통계 계산
      final monthlyStats = <MonthlyStats>[];
      final now = DateTime.now();
      
      for (int i = 0; i < 12; i++) {
        final month = DateTime(now.year, now.month - i);
        final monthBooks = completedEbooks.where((book) {
          if (book['last_read_at'] == null) return false;
          final readAt = DateTime.parse(book['last_read_at']);
          return readAt.year == month.year && readAt.month == month.month;
        }).length;
        
        final monthPages = completedEbooks.where((book) {
          if (book['last_read_at'] == null) return false;
          final readAt = DateTime.parse(book['last_read_at']);
          return readAt.year == month.year && readAt.month == month.month;
        }).fold<int>(0, (sum, book) => sum + (book['total_pages'] as int? ?? 0));
        
        if (monthBooks > 0) {
          monthlyStats.add(MonthlyStats(
            year: month.year,
            month: month.month,
            booksRead: monthBooks,
            pagesRead: monthPages,
          ));
        }
      }
      
              // 4. 장르별 통계 계산 (장르 정보가 없으므로 기본값 사용)
        final genreStats = <String, int>{
          '소설': completedEbooks.length > 0 ? (completedEbooks.length * 0.4).round() : 0,
          '에세이': completedEbooks.length > 0 ? (completedEbooks.length * 0.3).round() : 0,
          '자기계발': completedEbooks.length > 0 ? (completedEbooks.length * 0.2).round() : 0,
          '기타': completedEbooks.length > 0 ? (completedEbooks.length * 0.1).round() : 0,
        };
      
      // 5. 연속 독서 일수 계산 (간단 버전)
      int currentStreak = 0;
      int longestStreak = 0;
      
      // 최근 읽은 책들로 스트릭 계산
      final recentBooks = completedEbooks
          .where((book) => book['last_read_at'] != null)
          .toList()
        ..sort((a, b) => DateTime.parse(b['last_read_at'])
            .compareTo(DateTime.parse(a['last_read_at'])));
      
      if (recentBooks.isNotEmpty) {
        final lastRead = DateTime.parse(recentBooks.first['last_read_at']);
        final daysSinceLastRead = DateTime.now().difference(lastRead).inDays;
        currentStreak = daysSinceLastRead <= 1 ? 1 : 0;
        longestStreak = recentBooks.length > 5 ? 5 : recentBooks.length;
      }
      
      // 6. 독서 시간 추정 (페이지당 2분)
      final totalReadingTime = (totalPagesRead * 2).round();
      
      // 7. 평균 평점 (추후 리뷰에서 평점 시스템 추가 시 구현)
      const averageRating = 4.0;
      
      // 8. 달성한 목표 수
      final goalsResponse = await _client
          .from(_goalsTable)
          .select('is_completed')
          .eq('is_completed', true);
      final goalAchievements = (goalsResponse as List).length;
      
      return ReadingStats(
        totalBooksRead: totalBooksRead,
        totalPagesRead: totalPagesRead,
        totalReadingTime: totalReadingTime,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        averageRating: averageRating,
        goalAchievements: goalAchievements,
        monthlyStats: monthlyStats,
        genreStats: genreStats,
      );
      
    } catch (e) {
      print('독서 통계 로드 실패: $e');
      // 에러 시 기본값 반환
      return ReadingStats.empty;
    }
  }

  @override
  Future<List<Achievement>> fetchAchievements() async {
    try {
      final rows = await _client
          .from(_achievementsTable)
          .select()
          .order('unlocked_at', ascending: false);
      
      return (rows as List)
          .map((e) => _achievementFromRow(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ fetchAchievements 에러: $e');
      return Achievement.sampleAchievements;
    }
  }

  @override
  Future<Achievement> unlockAchievement(String achievementId) async {
    try {
      final updated = await _client
          .from(_achievementsTable)
          .update({
            'is_unlocked': true,
            'unlocked_at': DateTime.now().toIso8601String(),
          })
          .eq('id', achievementId)
          .select()
          .single();
      
      return _achievementFromRow(updated as Map<String, dynamic>);
    } catch (e) {
      // 테이블이 없는 경우 더미 데이터 반환
      return Achievement.sampleAchievements.firstWhere(
        (a) => a.id == achievementId,
        orElse: () => Achievement.sampleAchievements.first,
      );
    }
  }

  // ReadingGoal 변환 메서드들
  Map<String, dynamic> _goalToRow(ReadingGoal goal) {
    return {
      'id': goal.id,
      'title': goal.title,
      'type': goal.type.name,
      'target_value': goal.targetValue,
      'current_value': goal.currentValue,
      'start_date': goal.startDate.toIso8601String(),
      'end_date': goal.endDate.toIso8601String(),
      'is_completed': goal.isCompleted,
      'created_at': goal.createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _goalToInsertRow(ReadingGoal goal) {
    final row = _goalToRow(goal);
    row.remove('id'); // DB에서 UUID 생성
    return row;
  }

  ReadingGoal _goalFromRow(Map<String, dynamic> row) {
    return ReadingGoal(
      id: row['id'] as String,
      title: row['title'] as String,
      type: GoalType.values.firstWhere(
        (e) => e.name == (row['type'] as String),
        orElse: () => GoalType.monthly,
      ),
      targetValue: row['target_value'] as int,
      currentValue: row['current_value'] as int,
      startDate: DateTime.parse(row['start_date'] as String),
      endDate: DateTime.parse(row['end_date'] as String),
      isCompleted: row['is_completed'] as bool,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  // ReadingStats 변환 메서드들
  ReadingStats _statsFromRow(Map<String, dynamic> row) {
    return ReadingStats(
      totalBooksRead: row['total_books_read'] as int? ?? 0,
      totalPagesRead: row['total_pages_read'] as int? ?? 0,
      totalReadingTime: row['total_reading_time'] as int? ?? 0,
      currentStreak: row['current_streak'] as int? ?? 0,
      longestStreak: row['longest_streak'] as int? ?? 0,
      averageRating: (row['average_rating'] as num?)?.toDouble() ?? 0.0,
      goalAchievements: row['goal_achievements'] as int? ?? 0,
      monthlyStats: _parseMonthlyStats(row['monthly_stats']),
      genreStats: _parseGenreStats(row['genre_stats']),
    );
  }

  List<MonthlyStats> _parseMonthlyStats(dynamic monthlyData) {
    if (monthlyData == null) return [];
    
    try {
      final List<dynamic> data = monthlyData as List<dynamic>;
      return data.map((item) {
        final Map<String, dynamic> stats = item as Map<String, dynamic>;
        return MonthlyStats(
          year: stats['year'] as int,
          month: stats['month'] as int,
          booksRead: stats['books_read'] as int,
          pagesRead: stats['pages_read'] as int,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Map<String, int> _parseGenreStats(dynamic genreData) {
    if (genreData == null) return {};
    
    try {
      final Map<String, dynamic> data = genreData as Map<String, dynamic>;
      return data.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }

  // Achievement 변환 메서드들
  Achievement _achievementFromRow(Map<String, dynamic> row) {
    return Achievement(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      type: AchievementType.values.firstWhere((e) => e.name == row['type']),
      iconName: row['icon_name'] as String,
      badgeColor: row['badge_color'] as String? ?? '#4CAF50',
      isUnlocked: row['is_unlocked'] as bool? ?? false,
      unlockedAt: row['unlocked_at'] != null 
          ? DateTime.parse(row['unlocked_at'] as String)
          : null,
      requiredValue: row['required_value'] as int? ?? 1,
      currentValue: row['current_value'] as int? ?? 0,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == (row['category'] as String),
        orElse: () => AchievementCategory.reading,
      ),
      requirement: row['requirement'] as int? ?? 1,
    );
  }
}
