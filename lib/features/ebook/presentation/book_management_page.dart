import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/ebook.dart';
import 'add_book_page.dart';
import 'ebook_reader_page.dart';

class BookManagementPage extends StatefulWidget {
  const BookManagementPage({super.key});

  @override
  State<BookManagementPage> createState() => _BookManagementPageState();
}

class _BookManagementPageState extends State<BookManagementPage> {
  List<EBook> _books = [];
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() {
    setState(() {
      _isLoading = true;
    });
    
    // TODO: 실제 데이터 로딩
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _books = EBook.sampleBooks;
        _isLoading = false;
      });
    });
  }

  List<EBook> get _filteredBooks {
    if (_searchQuery.isEmpty) {
      return _books;
    }
    return _books.where((book) {
      return book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             book.author.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _addBook() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddBookPage(),
      ),
    );

    if (result != null && result is EBook) {
      setState(() {
        _books.add(result);
      });
    }
  }

  Future<void> _editBook(EBook book) async {
    // TODO: 책 편집 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('책 편집 기능을 준비 중입니다.'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<void> _deleteBook(EBook book) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('책 삭제'),
        content: Text('정말로 "${book.title}"을(를) 삭제하시겠습니까?\n삭제된 책은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        _books.removeWhere((b) => b.id == book.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${book.title}"이(가) 삭제되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _openBook(EBook book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EBookReaderPage(ebook: book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('책 관리'),
        backgroundColor: AppColors.background,
        elevation: 1,
        shadowColor: AppColors.dividerColor,
        actions: [
          IconButton(
            onPressed: _addBook,
            icon: const Icon(Icons.add),
            tooltip: '새 책 추가',
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: '책 제목이나 저자로 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
            ),
          ),

          // 통계 정보
          if (!_isLoading) _buildStatistics(),

          // 책 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBooks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = _filteredBooks[index];
                          return _BookManagementCard(
                            book: book,
                            onTap: () => _openBook(book),
                            onEdit: () => _editBook(book),
                            onDelete: () => _deleteBook(book),
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

  Widget _buildStatistics() {
    final totalBooks = _books.length;
    final readingBooks = _books.where((book) => book.progress > 0 && book.progress < 1).length;
    final completedBooks = _books.where((book) => book.progress >= 1).length;
    final unreadBooks = _books.where((book) => book.progress == 0).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Container(width: 1, height: 40, color: AppColors.dividerColor),
          Expanded(
            child: _StatItem(
              title: '읽는 중',
              count: readingBooks,
              color: Colors.orange,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.dividerColor),
          Expanded(
            child: _StatItem(
              title: '완독',
              count: completedBooks,
              color: Colors.green,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.dividerColor),
          Expanded(
            child: _StatItem(
              title: '미읽음',
              count: unreadBooks,
              color: AppColors.textHint,
            ),
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
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.library_books_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? '검색 결과가 없습니다'
                : '관리할 책이 없습니다',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? '다른 검색어를 시도해보세요'
                : '+ 버튼을 눌러 첫 번째 책을 추가해보세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addBook,
              icon: const Icon(Icons.add),
              label: const Text('책 추가하기'),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookManagementCard extends StatelessWidget {
  final EBook book;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookManagementCard({
    required this.book,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 책 아이콘
                  Container(
                    width: 50,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.dividerColor),
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

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
                      ],
                    ),
                  ),

                  // 액션 버튼
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('편집'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('삭제', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 추가 정보
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.pages,
                    label: '${book.totalPages}페이지',
                  ),
                  const SizedBox(width: 8),
                  if (book.chapters.isNotEmpty)
                    _InfoChip(
                      icon: Icons.list,
                      label: '${book.chapters.length}장',
                    ),
                  const Spacer(),
                  Text(
                    '추가: ${_formatDate(book.addedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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


