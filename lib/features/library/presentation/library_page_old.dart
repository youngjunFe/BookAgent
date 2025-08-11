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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.selectedTab,
          unselectedLabelColor: AppColors.unselectedTab,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
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

  // 임시 데이터
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
          // 상태별 카운트
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.dividerColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusCount(
                  label: AppStrings.allReviews,
                  count: _reviewCounts[AppStrings.allReviews]!,
                  color: AppColors.textPrimary,
                ),
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

          // 리뷰 리스트
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
            Icons.article_outlined,
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

// 독서 관리 탭
class ReadingTab extends StatefulWidget {
  const ReadingTab({super.key});

  @override
  State<ReadingTab> createState() => _ReadingTabState();
}

class _ReadingTabState extends State<ReadingTab> {
  String _selectedFilter = AppStrings.wantToRead;

  // 임시 데이터
  final Map<String, int> _bookCounts = {
    AppStrings.wantToRead: 0,
    AppStrings.reading: 0,
    AppStrings.completed: 0,
    AppStrings.paused: 0,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태별 버튼과 카운트
          Row(
            children: [
              Expanded(
                child: _ReadingStatusButton(
                  label: AppStrings.wantToRead,
                  count: _bookCounts[AppStrings.wantToRead]!,
                  color: AppColors.wantToRead,
                  isSelected: _selectedFilter == AppStrings.wantToRead,
                  onTap: () => setState(() => _selectedFilter = AppStrings.wantToRead),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReadingStatusButton(
                  label: AppStrings.reading,
                  count: _bookCounts[AppStrings.reading]!,
                  color: AppColors.reading,
                  isSelected: _selectedFilter == AppStrings.reading,
                  onTap: () => setState(() => _selectedFilter = AppStrings.reading),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ReadingStatusButton(
                  label: AppStrings.completed,
                  count: _bookCounts[AppStrings.completed]!,
                  color: AppColors.completed,
                  isSelected: _selectedFilter == AppStrings.completed,
                  onTap: () => setState(() => _selectedFilter = AppStrings.completed),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReadingStatusButton(
                  label: AppStrings.paused,
                  count: _bookCounts[AppStrings.paused]!,
                  color: AppColors.paused,
                  isSelected: _selectedFilter == AppStrings.paused,
                  onTap: () => setState(() => _selectedFilter = AppStrings.paused),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 책 리스트
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
            Icons.menu_book_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 등록된 책이 없습니다',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 책을 추가해보세요!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: 책 추가 페이지로 이동
            },
            icon: const Icon(Icons.add),
            label: const Text('책 추가하기'),
          ),
        ],
      ),
    );
  }
}

// 상태 카운트 위젯
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
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
        ),
      ],
    );
  }
}

// 필터 칩 위젯
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected || isAction
              ? AppColors.primary
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected || isAction
                ? AppColors.primary
                : AppColors.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected || isAction
                ? AppColors.onPrimary
                : AppColors.textSecondary,
            fontWeight: isSelected || isAction
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// 독서 상태 버튼 위젯
class _ReadingStatusButton extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReadingStatusButton({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count${AppStrings.books}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
