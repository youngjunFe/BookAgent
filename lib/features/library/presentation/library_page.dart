import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../chat/presentation/ai_chat_page.dart';
import '../../review/presentation/review_creation_page.dart';
import '../../review/presentation/review_editor_page.dart';
import '../../review/data/review_repository.dart';
import '../../review/models/review.dart';
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
  List<Review> _reviews = [];
  bool _isLoading = true;

  // 임시 데이터 - 실제로는 상태 관리나 서버에서 가져올 데이터
  final Map<String, int> _reviewCounts = {
    AppStrings.allReviews: 0,
    AppStrings.draftReviews: 0,
    AppStrings.completedReviews: 0,
    AppStrings.publishedReviews: 0,
  };
  final _reviewRepo = ReviewRepository();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 발제문 목록과 카운트를 동시에 로드
      final results = await Future.wait([
        _reviewRepo.list(),
        _reviewRepo.counts(),
      ]);
      
      if (!mounted) return;
      
      final reviews = results[0] as List<Review>;
      final counts = results[1] as Map<ReviewStatus, int>;
      
      setState(() {
        _reviews = reviews;
        _reviewCounts[AppStrings.draftReviews] = counts[ReviewStatus.draft] ?? 0;
        _reviewCounts[AppStrings.completedReviews] = counts[ReviewStatus.completed] ?? 0;
        _reviewCounts[AppStrings.publishedReviews] = counts[ReviewStatus.published] ?? 0;
        _reviewCounts[AppStrings.allReviews] = _reviewCounts[AppStrings.draftReviews]! +
            _reviewCounts[AppStrings.completedReviews]! +
            _reviewCounts[AppStrings.publishedReviews]!;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      print('발제문 로드 실패: $e');
    }
  }

  List<Review> get _filteredReviews {
    switch (_selectedFilter) {
      case AppStrings.allReviews:
        return _reviews;
      case AppStrings.draftReviews:
        return _reviews.where((r) => r.status == ReviewStatus.draft).toList();
      case AppStrings.completedReviews:
        return _reviews.where((r) => r.status == ReviewStatus.completed).toList();
      case AppStrings.publishedReviews:
        return _reviews.where((r) => r.status == ReviewStatus.published).toList();
      default:
        return _reviews;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: AppStrings.allReviews,
                  isSelected: _selectedFilter == AppStrings.allReviews,
                  onTap: () => setState(() => _selectedFilter = AppStrings.allReviews),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: AppStrings.draftReviews,
                  isSelected: _selectedFilter == AppStrings.draftReviews,
                  onTap: () => setState(() => _selectedFilter = AppStrings.draftReviews),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: AppStrings.completedReviews,
                  isSelected: _selectedFilter == AppStrings.completedReviews,
                  onTap: () => setState(() => _selectedFilter = AppStrings.completedReviews),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: AppStrings.createReview,
                  isSelected: false,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ReviewCreationPage(),
                      ),
                    );
                    // 발제문 작성 후 돌아오면 목록 새로고침
                    _loadData();
                  },
                  isAction: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 발제문 목록 또는 빈 상태
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredReviews.isEmpty 
                    ? _buildEmptyState()
                    : _buildReviewList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _filteredReviews.length,
          itemBuilder: (context, index) {
            final review = _filteredReviews[index];
            return _ReviewCard(
              review: review,
              onTap: () async {
                // 발제문 편집 페이지로 이동
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ReviewEditorPage(review: review),
                  ),
                );
                // 편집 후 목록 새로고침
                _loadData();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String emptyMessage = '아직 작성한 발제문이 없습니다';
    String emptySubMessage = 'AI와 대화하며 첫 발제문을 작성해보세요!';
    
    if (_selectedFilter == AppStrings.draftReviews) {
      emptyMessage = '초안 상태의 발제문이 없습니다';
      emptySubMessage = '새로운 발제문을 작성해보세요!';
    } else if (_selectedFilter == AppStrings.completedReviews) {
      emptyMessage = '완료된 발제문이 없습니다';
      emptySubMessage = '초안을 완성해보세요!';
    } else if (_selectedFilter == AppStrings.publishedReviews) {
      emptyMessage = '게시된 발제문이 없습니다';
      emptySubMessage = '완성된 발제문을 게시해보세요!';
    }

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
            emptyMessage,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            emptySubMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ReviewCreationPage(),
                ),
              );
              _loadData();
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

class _ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback onTap;

  const _ReviewCard({
    required this.review,
    required this.onTap,
  });

  // 배경 이미지 ID를 그라디언트로 변환
  LinearGradient _getBackgroundGradient() {
    if (review.backgroundImage == null) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      );
    }

    switch (review.backgroundImage) {
      case 'book_vintage':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4A574), Color(0xFF8B4513)],
        );
      case 'library_cozy':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF654321), Color(0xFF2F1B14)],
        );
      case 'nature_forest':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF228B22), Color(0xFF006400)],
        );
      case 'sunset_reading':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
        );
      case 'coffee_minimal':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDEB887), Color(0xFFA0522D)],
        );
      case 'ocean_calm':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4682B4), Color(0xFF1E90FF)],
        );
      case 'modern_abstract':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        );
      case 'classic_paper':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F5DC), Color(0xFFD2B48C)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: _getBackgroundGradient(),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상태 배지
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          review.statusText,
                          style: TextStyle(
                            color: review.statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDate(review.updatedAt),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // 제목 (하단)
                  Text(
                    review.title.isNotEmpty ? review.title : '제목 없음',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // 책 제목
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_stories,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          review.bookTitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  if (review.content.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    // 내용 미리보기
                    Text(
                      review.content,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final cardDate = DateTime(date.year, date.month, date.day);

    if (cardDate == today) {
      return '오늘 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (cardDate == yesterday) {
      return '어제';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
