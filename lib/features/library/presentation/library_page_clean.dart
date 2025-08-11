import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../chat/presentation/ai_chat_page.dart';
import '../../review/presentation/review_creation_page.dart';
import 'ebook_tab.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.myLibrary),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.selectedTab,
          unselectedLabelColor: AppColors.unselectedTab,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: AppStrings.reviewTab),
            Tab(text: '전자책'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ReviewTab(),
          EBookTab(),
        ],
      ),
    );
  }
}

// 발제문 탭
class ReviewTab extends StatefulWidget {
  const ReviewTab({super.key});

  @override
  State<ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<ReviewTab> {
  String _selectedFilter = AppStrings.allReviews;

  // 임시 데이터 - 실제로는 상태 관리나 서버에서 가져올 데이터
  final Map<String, int> _reviewCounts = {
    AppStrings.allReviews: 0,
    AppStrings.draftReviews: 0,
    AppStrings.completedReviews: 0,
    AppStrings.publishedReviews: 0,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태별 카운트 표시
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _StatusCount(
                  label: AppStrings.draftReviews,
                  count: _reviewCounts[AppStrings.draftReviews]!,
                  color: AppColors.draft,
                ),
                _StatusCount(
                  label: AppStrings.completedReviews,
                  count: _reviewCounts[AppStrings.completedReviews]!,
                  color: AppColors.completedReview,
                ),
                _StatusCount(
                  label: AppStrings.publishedReviews,
                  count: _reviewCounts[AppStrings.publishedReviews]!,
                  color: AppColors.published,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 필터 버튼들
          Row(
            children: [
              _FilterChip(
                label: AppStrings.allReviews,
                isSelected: _selectedFilter == AppStrings.allReviews,
                onTap: () => setState(() => _selectedFilter = AppStrings.allReviews),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: AppStrings.createReview,
                isSelected: false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ReviewCreationPage(),
                    ),
                  );
                },
                isAction: true,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: AppStrings.publishReview,
                isSelected: false,
                onTap: () {
                  // TODO: 게시 페이지로 이동
                },
                isAction: true,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 빈 상태
          Expanded(
            child: _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 작성한 발제문이 없습니다',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI와 대화하며 첫 발제문을 작성해보세요!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ReviewCreationPage(),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('발제문 작성하기'),
          ),
        ],
      ),
    );
  }
}

class _StatusCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusCount({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isAction;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary 
              : isAction 
                  ? AppColors.secondary.withOpacity(0.1)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : isAction 
                    ? AppColors.secondary
                    : AppColors.dividerColor,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? AppColors.onPrimary 
                : isAction 
                    ? AppColors.secondary
                    : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}


