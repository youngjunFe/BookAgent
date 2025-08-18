import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/main_navigation.dart';
import '../../chat/presentation/ai_chat_page.dart';
import '../../chat/presentation/character_selection_page.dart';
import '../../reading_goals/presentation/reading_goals_page.dart';
import '../../weather/presentation/weather_card.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigation();
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: 공지사항 페이지로 이동
                      },
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.secondary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.homeIntroTitle,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.homeIntroSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 날씨 기반 개인화 메시지
                const WeatherCard(),
                
                const SizedBox(height: 32),
                
                // Main Action Buttons
                Column(
                  children: [
                    // AI 리뷰 작성 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                                              onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AiChatPage(),
                          ),
                        );
                      },
                        icon: const Icon(Icons.auto_awesome, size: 24),
                        label: Text(AppStrings.startReview),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 서재 보기 버튼
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: 서재 페이지로 이동
                        },
                        icon: const Icon(Icons.library_books, size: 24),
                        label: Text(AppStrings.goToLibrary),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Quick Actions
                Text(
                  '빠른 액션',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.menu_book,
                        title: '전자책 읽기',
                        subtitle: '책을 읽어보세요',
                        color: AppColors.reading,
                        onTap: () {
                          // 나의 서재의 전자책 탭으로 이동
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const MainNavigation(initialIndex: 1), // 서재 탭으로 이동
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.chat_bubble_outline,
                        title: '등장인물과 대화',
                        subtitle: '캐릭터와 대화해보세요',
                        color: AppColors.secondary,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CharacterSelectionPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                // 독서 목표 카드
                _QuickActionCard(
                  icon: Icons.flag,
                  title: '독서 목표',
                  subtitle: '목표를 설정하고 달성 현황을 확인해보세요',
                  color: Colors.amber,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ReadingGoalsPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                
                // Recent Activity
                Text(
                  '최근 활동',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                _buildRecentActivity(context),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActivityItem(
            context,
            icon: Icons.menu_book,
            title: '《잉크 속의 눈》 읽기 완료',
            subtitle: '방금 전',
            iconColor: AppColors.success,
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            context,
            icon: Icons.chat_bubble,
            title: '해리 포터와 대화',
            subtitle: '5분 전',
            iconColor: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            context,
            icon: Icons.edit,
            title: '골목의 왕, 라떼 발제문 작성',
            subtitle: '1시간 전',
            iconColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            context,
            icon: Icons.flag,
            title: '월간 독서 목표 달성',
            subtitle: '2시간 전',
            iconColor: Colors.amber,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                // 전체 활동 내역 페이지로 이동
              },
              child: const Text('모든 활동 보기'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
