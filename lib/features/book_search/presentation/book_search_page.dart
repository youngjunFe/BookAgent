import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/elevation_levels.dart';
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
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElevationLevels.level1, // Level1 Elevation
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectBook(book),
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withOpacity(0.10), // State Layer - Pressed (10%)
          highlightColor: AppColors.primary.withOpacity(0.08), // State Layer - Hover (8%)
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📚 개선된 책 표지 - 더 크고 세련되게
                Container(
                  width: 80,  // 60 → 80으로 확대
                  height: 110, // 80 → 110으로 확대
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: ElevationLevels.level2, // Level2 Elevation for 책 표지
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: book.image.isNotEmpty
                      ? Image.network(
                          book.image,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildBookCoverPlaceholder(book.title);
                          },
                        )
                      : _buildBookCoverPlaceholder(book.title),
                  ),
                ),
                const SizedBox(width: 20),
                
                // 📖 개선된 책 정보 - 새로운 Typography 적용
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목 - Title Large 적용
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // 저자 - Body Medium 적용
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              book.author,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // 출판사 - Body Small 적용
                      Row(
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              book.publisher,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textHint,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      // 설명 - Body Small 적용
                      if (book.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            book.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 화살표 아이콘
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
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
        print('🔍 API Response: $data'); // 디버깅용
        
        final books = (data['books'] as List)
            .map((book) {
              final result = BookSearchResult.fromJson(book);
              print('📚 Book: ${result.title}, Image: ${result.image}'); // 이미지 URL 확인
              return result;
            })
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
          bookAuthor: book.author,
        ),
      ),
    );
  }

  /// 📚 책 표지 플레이스홀더 생성 (책 제목 기반 색상 + 이니셜)
  Widget _buildBookCoverPlaceholder(String title) {
    // 책 제목을 기반으로 색상 생성
    final colors = [
      [AppColors.primary, AppColors.primaryLight],
      [AppColors.secondary, AppColors.secondaryLight], 
      [AppColors.tertiary, AppColors.tertiaryLight],
      [AppColors.accentSageGreen, AppColors.accentSageGreen.withOpacity(0.3)],
      [AppColors.accentBurgundy, AppColors.accentBurgundy.withOpacity(0.3)],
      [AppColors.accentLemonZest, AppColors.accentLemonZest.withOpacity(0.3)],
      [AppColors.accentSteelBlue, AppColors.accentSteelBlue.withOpacity(0.3)],
      [AppColors.accentLavenderPurple, AppColors.accentLavenderPurple.withOpacity(0.3)],
    ];
    
    final colorIndex = title.length % colors.length;
    final selectedColors = colors[colorIndex];
    
    // 책 제목의 첫 글자 추출
    String initial = title.isNotEmpty ? title[0].toUpperCase() : '책';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selectedColors,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: selectedColors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 배경 패턴
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: -5,
            left: -5,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.5),
              ),
            ),
          ),
          
          // 메인 콘텐츠
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 책 이니셜
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // 책 아이콘
                Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
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
