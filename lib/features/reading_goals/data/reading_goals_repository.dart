import '../../../core/supabase/supabase_client_provider.dart';
import '../models/reading_goal.dart';
import '../models/reading_stats.dart';
import '../models/achievement.dart';
import 'reading_goals_api.dart';

class ReadingGoalsRepository {
  ReadingGoalsRepository({ReadingGoalsApi? api}) : _api = api ?? SupabaseReadingGoalsApi();
  final ReadingGoalsApi _api;

  Future<List<ReadingGoal>> list() {
    return _api.list();
  }

  Future<ReadingGoal> create(ReadingGoal goal) {
    return _api.create(goal);
  }

  Future<ReadingGoal> update(ReadingGoal goal) {
    return _api.update(goal);
  }

  Future<void> delete(String id) {
    return _api.delete(id);
  }

  Future<ReadingStats> fetchStats() {
    return _api.fetchStats();
  }

  Future<List<Achievement>> fetchAchievements() {
    return _api.fetchAchievements();
  }

  Future<Achievement> unlockAchievement(String achievementId) {
    return _api.unlockAchievement(achievementId);
  }

  /// 독서 진행률 업데이트 (책 완료, 페이지 읽기 등)
  Future<void> updateReadingProgress({
    required int booksCompleted,
    required int pagesRead,
    required int readingTimeMinutes,
  }) async {
    try {
      // 1. 현재 통계 가져오기
      final currentStats = await fetchStats();
      
      // 2. 통계 업데이트
      final updatedStats = currentStats.copyWith(
        totalBooksRead: currentStats.totalBooksRead + booksCompleted,
        totalPagesRead: currentStats.totalPagesRead + pagesRead,
        totalReadingTime: currentStats.totalReadingTime + readingTimeMinutes,
      );
      
      // 3. 활성 목표들 가져오기
      final activeGoals = await list();
    
      // 4. 각 목표의 진행률 업데이트
      for (final goal in activeGoals.where((g) => !g.isCompleted)) {
        int progressToAdd = 0;
        
        switch (goal.type) {
          case GoalType.daily:
          case GoalType.weekly:
          case GoalType.monthly:
          case GoalType.yearly:
            progressToAdd = booksCompleted;
            break;
          case GoalType.pages:
            progressToAdd = pagesRead;
            break;
          case GoalType.time:
            progressToAdd = readingTimeMinutes;
            break;
          case GoalType.streak:
            // 연속 독서는 별도 로직 필요
            if (booksCompleted > 0 || pagesRead > 0) {
              progressToAdd = 1; // 하루 독서 완료
            }
            break;
        }
        
        if (progressToAdd > 0) {
          final updatedGoal = goal.copyWith(
            currentValue: goal.currentValue + progressToAdd,
            isCompleted: (goal.currentValue + progressToAdd) >= goal.targetValue,
          );
          
          await update(updatedGoal);
          
          // 목표 달성 시 도전과제 확인
          if (updatedGoal.isCompleted && !goal.isCompleted) {
            try {
              await _checkAchievements(updatedGoal);
            } catch (e) {
              print('❌ 도전과제 확인 실패: $e (계속 진행)');
            }
          }
        }
      }
    } catch (e) {
      print('❌ 독서 진행률 업데이트 실패: $e');
      // 에러 시 조용히 무시
    }
  }

  /// 목표 달성 시 관련 도전과제 확인 및 해금
  Future<void> _checkAchievements(ReadingGoal completedGoal) async {
    final achievements = await fetchAchievements();
    final unlockedAchievements = <Achievement>[];
    
    for (final achievement in achievements.where((a) => !a.isUnlocked)) {
      bool shouldUnlock = false;
      
      switch (achievement.category) {
        case AchievementCategory.reading:
          // 독서 관련 도전과제
          if (achievement.id == 'first_book' && completedGoal.type != GoalType.streak) {
            shouldUnlock = true;
          }
          break;
        case AchievementCategory.goals:
          // 목표 달성 관련 도전과제
          if (achievement.id == 'first_goal') {
            shouldUnlock = true;
          }
          break;
        case AchievementCategory.streak:
          // 연속 독서 관련 도전과제
          if (completedGoal.type == GoalType.streak) {
            shouldUnlock = true;
          }
          break;
        case AchievementCategory.special:
          // 특별 도전과제
          break;
      }
      
      if (shouldUnlock) {
        final unlockedAchievement = await unlockAchievement(achievement.id);
        unlockedAchievements.add(unlockedAchievement);
      }
    }
    
    // TODO: 도전과제 해금 알림 표시
  }
}
