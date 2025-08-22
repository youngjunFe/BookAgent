import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../chat/presentation/ai_chat_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookSearchPage extends StatefulWidget {
  const BookSearchPage({super.key});

  @override
  State<BookSearchPage> createState() => _BookSearchPageState();
}

class _BookSearchPageState extends State<BookSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<BookSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('책 검색'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '어떤 책에 대해 이야기하고 싶으신가요?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // 검색 입력창
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '책 제목이나 저자명을 입력하세요',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: _isSearching 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.search),
                    onPressed: _searchBooks,
                  ),
                ),
                onSubmitted: (_) => _searchBooks(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 검색 결과
            Expanded(
              child: _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '책을 검색해보세요',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final book = _searchResults[index];
                      return _buildBookItem(book);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookItem(BookSearchResult book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: InkWell(
        onTap: () => _selectBook(book),
        child: Row(
          children: [
            // 책 표지
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: book.image.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.book,
                          color: AppColors.primary,
                          size: 30,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.book,
                    color: AppColors.primary,
                    size: 30,
                  ),
            ),
            const SizedBox(width: 16),
            
            // 책 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.publisher,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                  if (book.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      book.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textHint,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchBooks() async {
    if (_searchController.text.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://bookagent-production.up.railway.app/api/search-books?query=${_searchController.text}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final books = (data['books'] as List)
            .map((book) => BookSearchResult.fromJson(book))
            .toList();
        
        setState(() {
          _searchResults = books;
        });
      }
    } catch (e) {
      print('Search error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('검색 중 오류가 발생했습니다.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectBook(BookSearchResult book) {
    // 책 선택 후 AI 대화 페이지로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AiChatPage(
          initialContext: '선택한 책: ${book.title} (${book.author})\n\n이 책에 대해 대화해보세요!',
          bookTitle: book.title,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class BookSearchResult {
  final String title;
  final String author;
  final String publisher;
  final String image;
  final String description;
  final String isbn;

  BookSearchResult({
    required this.title,
    required this.author,
    required this.publisher,
    required this.image,
    required this.description,
    required this.isbn,
  });

  factory BookSearchResult.fromJson(Map<String, dynamic> json) {
    return BookSearchResult(
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      publisher: json['publisher'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      isbn: json['isbn'] ?? '',
    );
  }
}
