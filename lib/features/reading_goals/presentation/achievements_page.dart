import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/achievement.dart';

class AchievementsPage extends StatefulWidget {
  final List<Achievement> achievements;

  const AchievementsPage({
    super.key,
    required this.achievements,
  });

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  AchievementType? _selectedFilter;

  List<Achievement> get filteredAchievements {
    if (_selectedFilter == null) {
      return widget.achievements;
    }
    return widget.achievements.where((a) => a.type == _selectedFilter).toList();
  }

  int get unlockedCount => widget.achievements.where((a) => a.isUnlocked).length;
  int get totalCount => widget.achievements.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('성취 목록'),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 진행률 헤더
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade400,
                  Colors.orange.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
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
                    Icons.emoji_events,
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
                        '성취 현황',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        '$unlockedCount / $totalCount',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${((unlockedCount / totalCount) * 100).toInt()}% 달성',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: unlockedCount / totalCount,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 6,
                ),
              ],
            ),
          ),

          // 필터 탭
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('전체', null),
                ...AchievementType.values.map((type) => _buildFilterChip(type.displayName, type)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 성취 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredAchievements.length,
              itemBuilder: (context, index) {
                return _buildAchievementCard(filteredAchievements[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AchievementType? type) {
    final isSelected = _selectedFilter == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.dividerColor,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked 
              ? _getColorFromHex(achievement.badgeColor).withOpacity(0.3)
              : AppColors.dividerColor,
          width: achievement.isUnlocked ? 2 : 1,
        ),
        boxShadow: achievement.isUnlocked
            ? [
                BoxShadow(
                  color: _getColorFromHex(achievement.badgeColor).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // 배지 아이콘
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

          const SizedBox(width: 16),

          // 배지 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: achievement.isUnlocked 
                              ? AppColors.textPrimary 
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (achievement.isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '달성',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: achievement.isUnlocked 
                        ? AppColors.textSecondary 
                        : AppColors.textHint,
                  ),
                ),

                const SizedBox(height: 8),

                // 진행률
                if (!achievement.isUnlocked) ...[
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: achievement.progress.clamp(0.0, 1.0),
                          backgroundColor: AppColors.dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getColorFromHex(achievement.badgeColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${achievement.currentValue}/${achievement.requiredValue}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ] else if (achievement.unlockedAt != null) ...[
                  Text(
                    '${_formatDate(achievement.unlockedAt!)}에 달성',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getColorFromHex(achievement.badgeColor),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 4),

                // 카테고리
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: achievement.isUnlocked
                        ? _getColorFromHex(achievement.badgeColor).withOpacity(0.1)
                        : AppColors.textHint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    achievement.type.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: achievement.isUnlocked
                          ? _getColorFromHex(achievement.badgeColor)
                          : AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}


