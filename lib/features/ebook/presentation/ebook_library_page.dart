import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../models/ebook.dart';
import '../data/ebook_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ebook_reader_page.dart';
import 'add_book_page.dart';
import 'book_management_page.dart';

class EBookLibraryPage extends StatefulWidget {
  const EBookLibraryPage({super.key});

  @override
  State<EBookLibraryPage> createState() => _EBookLibraryPageState();
}

class _EBookLibraryPageState extends State<EBookLibraryPage> {
  List<EBook> _ebooks = [];
  bool _isLoading = false;
  String? _error;
  final _repo = EbookRepository();
  String _sortBy = '최근 읽은 순';
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _repo.fetchEbooks();
      setState(() {
        _ebooks = items;
      });
      _sortBooks(_sortBy);
    } catch (e) {
      setState(() {
        _error = '목록을 불러오지 못했습니다';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeRealtime() {
    try {
      _channel = Supabase.instance.client
          .channel('public:ebooks')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'ebooks',
            callback: (payload) {
              _loadBooks();
            },
          )
          .subscribe();
    } catch (_) {}
  }

  void _sortBooks(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      switch (sortBy) {
        case '최근 읽은 순':
          _ebooks.sort((a, b) {
            if (a.lastReadAt == null && b.lastReadAt == null) return 0;
            if (a.lastReadAt == null) return 1;
            if (b.lastReadAt == null) return -1;
            return b.lastReadAt!.compareTo(a.lastReadAt!);
          });
          break;
        case '제목 순':
          _ebooks.sort((a, b) => a.title.compareTo(b.title));
          break;
        case '저자 순':
          _ebooks.sort((a, b) => a.author.compareTo(b.author));
          break;
        case '추가한 순':
          _ebooks.sort((a, b) => b.addedAt.compareTo(a.addedAt));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('전자책 서재'),
        backgroundColor: AppColors.background,
        elevation: 1,
        shadowColor: AppColors.dividerColor,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BookManagementPage(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: '책 관리',
          ),
          PopupMenuButton<String>(
            onSelected: _sortBooks,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: '최근 읽은 순',
                child: Text('최근 읽은 순'),
              ),
              const PopupMenuItem(
                value: '제목 순',
                child: Text('제목 순'),
              ),
              const PopupMenuItem(
                value: '저자 순',
                child: Text('저자 순'),
              ),
              const PopupMenuItem(
                value: '추가한 순',
                child: Text('추가한 순'),
              ),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _sortBy,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.sort,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _ebooks.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // 읽기 통계
                _buildReadingStats(),
                
                // 책 목록
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ebooks.length,
                    itemBuilder: (context, index) {
                      final book = _ebooks[index];
                      return _BookCard(
                        book: book,
                        onTap: () => _openBook(book),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBook,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.onPrimary),
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
            '아직 추가된 전자책이 없습니다',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+ 버튼을 눌러 첫 번째 책을 추가해보세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addBook,
            icon: const Icon(Icons.add),
            label: const Text('책 추가하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingStats() {
    final totalBooks = _ebooks.length;
    final readingBooks = _ebooks.where((book) => book.progress > 0 && book.progress < 1).length;
    final completedBooks = _ebooks.where((book) => book.progress >= 1).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              title: '전체',
              count: totalBooks,
              color: AppColors.primary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.dividerColor,
          ),
          Expanded(
            child: _StatItem(
              title: '읽는 중',
              count: readingBooks,
              color: Colors.orange,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.dividerColor,
          ),
          Expanded(
            child: _StatItem(
              title: '완독',
              count: completedBooks,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _openBook(EBook book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EBookReaderPage(ebook: book),
      ),
    );
  }

  Future<void> _addBook() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddBookPage(),
      ),
    );

    if (result != null && result is EBook) {
      setState(() {
        _ebooks.add(result);
      });
    }
  }
}

class _BookCard extends StatelessWidget {
  final EBook book;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 책 표지
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.dividerColor),
                ),
                child: _buildDefaultCover(),
              ),

              const SizedBox(width: 16),

              // 책 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 진행률
                    if (book.progress > 0) ...[
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: book.progress,
                              backgroundColor: AppColors.dividerColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                book.progress >= 1.0 ? Colors.green : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(book.progress * 100).toInt()}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${book.currentPage + 1} / ${book.totalPages}페이지',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '읽기 시작하기',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    // 마지막 읽은 시간
                    if (book.lastReadAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '마지막 읽기: ${_formatDate(book.lastReadAt!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 상태 아이콘
              Icon(
                book.progress >= 1.0
                    ? Icons.check_circle
                    : book.progress > 0
                        ? Icons.play_circle_outline
                        : Icons.play_circle_outlined,
                color: book.progress >= 1.0
                    ? Colors.green
                    : book.progress > 0
                        ? AppColors.primary
                        : AppColors.textHint,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return const Icon(
      Icons.menu_book,
      color: AppColors.primary,
      size: 32,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '방금 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _StatItem({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
