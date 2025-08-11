import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/reading_goal.dart';
import '../models/achievement.dart';
import '../models/reading_stats.dart';
import 'goal_creation_page.dart';
import 'achievements_page.dart';
import 'stats_page.dart';

class ReadingGoalsPage extends StatefulWidget {
  const ReadingGoalsPage({super.key});

  @override
  State<ReadingGoalsPage> createState() => _ReadingGoalsPageState();
}

class _ReadingGoalsPageState extends State<ReadingGoalsPage> {
  List<ReadingGoal> _goals = [];
  List<Achievement> _achievements = [];
  ReadingStats _stats = ReadingStats.sample;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // TODO: 실제 데이터 로딩
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _goals = ReadingGoal.sampleGoals;
          _achievements = Achievement.sampleAchievements;
          _isLoading = false;
        });
      }
    });
  }

  void _addNewGoal() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GoalCreationPage(),
      ),
    );

    if (result != null && result is ReadingGoal) {
      setState(() {
        _goals.add(result);
      });
    }
  }

  void _viewAllAchievements() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AchievementsPage(achievements: _achievements),
      ),
    );
  }

  void _viewDetailedStats() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatsPage(stats: _stats),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final recentAchievements = _achievements.where((a) => a.isUnlocked).take(3).toList();
    final activeGoals = _goals.where((g) => !g.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('독서 목표'),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _addNewGoal,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 현재 스트릭
            _buildStreakCard(),
            
            const SizedBox(height: 16),

            // 간단한 통계
            _buildQuickStats(),

            const SizedBox(height: 24),

            // 진행 중인 목표
            _buildSectionHeader('진행 중인 목표', '전체 보기', () {}),
            const SizedBox(height: 12),
            if (activeGoals.isEmpty)
              _buildEmptyGoals()
            else
              ...activeGoals.take(3).map((goal) => _buildGoalCard(goal)),

            const SizedBox(height: 24),

            // 최근 성취
            _buildSectionHeader('최근 성취', '전체 보기', _viewAllAchievements),
            const SizedBox(height: 12),
            if (recentAchievements.isEmpty)
              _buildEmptyAchievements()
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentAchievements.length,
                  itemBuilder: (context, index) {
                    return _buildAchievementBadge(recentAchievements[index]);
                  },
                ),
              ),

            const SizedBox(height: 24),

            // 상세 통계 버튼
            _buildStatsButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 스트릭',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  '${_stats.currentStreak}일 연속',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '최고 기록: ${_stats.longestStreak}일',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '이번 달',
            '${_stats.thisMonthBooks}권',
            Icons.calendar_month,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '올해',
            '${_stats.thisYearBooks}권',
            Icons.calendar_today,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '평균 평점',
            '${_stats.averageRating.toStringAsFixed(1)}★',
            Icons.star,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionText, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionText),
        ),
      ],
    );
  }

  Widget _buildGoalCard(ReadingGoal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: goal.type == GoalType.monthly
                      ? Colors.blue.withOpacity(0.1)
                      : goal.type == GoalType.yearly
                          ? Colors.purple.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  goal.type.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: goal.type == GoalType.monthly
                        ? Colors.blue
                        : goal.type == GoalType.yearly
                            ? Colors.purple
                            : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: goal.progress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    goal.progress >= 1.0 ? Colors.green : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${goal.currentValue}/${goal.targetValue} ${goal.type.unit}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(goal.progress * 100).toInt()}% 완료',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (goal.remainingDays > 0)
                Text(
                  '${goal.remainingDays}일 남음',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: goal.isOverdue ? Colors.red : AppColors.textSecondary,
                  ),
                )
              else if (goal.isOverdue)
                Text(
                  '기한 만료',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGoals() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 설정된 목표가 없습니다',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 독서 목표를 설정해보세요!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addNewGoal,
            icon: const Icon(Icons.add),
            label: const Text('목표 추가'),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(Achievement achievement) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? _getColorFromHex(achievement.badgeColor)
                  : AppColors.textHint,
              shape: BoxShape.circle,
              boxShadow: achievement.isUnlocked
                  ? [
                      BoxShadow(
                        color: _getColorFromHex(achievement.badgeColor).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              _getIconFromName(achievement.iconName),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAchievements() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 32,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 8),
            Text(
              '아직 획득한 배지가 없습니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _viewDetailedStats,
        icon: const Icon(Icons.analytics),
        label: const Text('상세 통계 보기'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'book':
        return Icons.book;
      case 'menu_book':
        return Icons.menu_book;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'flash_on':
        return Icons.flash_on;
      case 'explore':
        return Icons.explore;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.emoji_events;
    }
  }
}
