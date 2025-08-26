import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/ebook.dart';
import '../data/ebook_repository.dart';
import 'add_book_page.dart';
import 'ebook_reader_page.dart';
import 'edit_book_page.dart';

class BookManagementPage extends StatefulWidget {
  const BookManagementPage({super.key});

  @override
  State<BookManagementPage> createState() => _BookManagementPageState();
}

class _BookManagementPageState extends State<BookManagementPage> {
  List<EBook> _books = [];
  String _searchQuery = '';
  bool _isLoading = false;
  final _repo = EBookRepository();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final books = await _repo.list();
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _books = []; // 보안상 샘플 데이터 표시 금지
        _isLoading = false;
      });
      print('책 목록 로드 실패: $e');
      
      // 인증 오류인 경우 로그인 페이지로 이동
      if (e.toString().contains('사용자 인증이 필요합니다')) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
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
      await _loadBooks(); // 새로고침
    }
  }

  Future<void> _editBook(EBook book) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditBookPage(book: book),
      ),
    );

    if (result != null && result is EBook) {
      await _loadBooks(); // 책 목록 새로고침
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.title}이(가) 수정되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _deleteBook(EBook book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('책 삭제'),
        content: Text('${book.title}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repo.delete(book.id);
        await _loadBooks(); // 새로고침
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('책이 삭제되었습니다.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _readBook(EBook book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EBookReaderPage(ebook: book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('책 관리'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          IconButton(
            onPressed: _addBook,
            icon: const Icon(Icons.add),
            tooltip: '책 추가',
          ),
          IconButton(
            onPressed: _loadBooks,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '책 제목이나 저자로 검색...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // 책 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBooks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              '등록된 책이 없습니다',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '+ 버튼을 눌러 새 책을 추가해보세요',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBooks,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredBooks.length,
                          itemBuilder: (context, index) {
                            final book = _filteredBooks[index];
                            return _BookCard(
                              book: book,
                              onRead: () => _readBook(book),
                              onEdit: () => _editBook(book),
                              onDelete: () => _deleteBook(book),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final EBook book;
  final VoidCallback onRead;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookCard({
    required this.book,
    required this.onRead,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
              child: _buildCover(),
            ),
            
            const SizedBox(width: 16),
            
            // 책 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 진행률 표시
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: book.progress,
                          backgroundColor: AppColors.dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            book.isCompleted ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        book.isCompleted 
                            ? '완독' 
                            : '${(book.progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: book.isCompleted ? AppColors.success : AppColors.textSecondary,
                          fontWeight: book.isCompleted ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  
                  if (book.lastReadAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '마지막 읽기: ${_formatDate(book.lastReadAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            // 액션 버튼들
            Column(
              children: [
                IconButton(
                  onPressed: onRead,
                  icon: Icon(
                    book.isCompleted ? Icons.replay : Icons.play_arrow,
                    color: AppColors.primary,
                  ),
                  tooltip: book.isCompleted ? '다시 읽기' : '읽기',
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: '편집',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  tooltip: '삭제',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          book.coverImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultCover();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
        ),
      );
    }
    return _buildDefaultCover();
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
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}