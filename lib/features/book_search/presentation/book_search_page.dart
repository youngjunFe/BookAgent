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
      backgroundColor: Colors.grey[50],
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
              '어떤 책을 읽으셨나요?',
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
                  hintText: '편하고 입력해 주세요',
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectBook(book),
          splashColor: AppColors.primary.withOpacity(0.05),
          highlightColor: AppColors.primary.withOpacity(0.03),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              children: [
                // 📚 책 표지 이미지 (작게)
                Container(
                  width: 45,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.primarySurface,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: book.image.isNotEmpty
                        ? _buildImageWithProxy(book)
                        : _buildSimplePlaceholder(book.title),
                  ),
                ),
                const SizedBox(width: 16),
                
                // 📖 책 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 분류 (민음사, 시간과공간사, 유페이퍼 등)
                      Text(
                        book.publisher.isNotEmpty ? book.publisher : '출판사',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      
                      // 책 제목
                      Text(
                        book.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      
                      // 저자 정보
                      Text(
                        book.author.isNotEmpty ? book.author : '저자 정보 없음',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // 오른쪽 화살표
                Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📚 간단한 책 표지 플레이스홀더 (작은 사이즈용)
  Widget _buildSimplePlaceholder(String title) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiary,
      AppColors.accentSageGreen,
      AppColors.accentBurgundy,
    ];
    
    final colorIndex = title.length % colors.length;
    final selectedColor = colors[colorIndex];
    
    // 제목의 첫 글자 가져오기
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: selectedColor.withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: selectedColor,
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

  /// 🖼️ 이미지 표시 여부 판단 (디버깅 포함)
  bool _shouldShowImage(BookSearchResult book) {
    print('🖼️ [${book.title}] Image URL: "${book.image}"');
    print('📏 Length: ${book.image.length}');
    print('🔍 isEmpty: ${book.image.isEmpty}');
    print('✂️ trimmed isEmpty: ${book.image.trim().isEmpty}');
    print('🌐 Starts with http: ${book.image.startsWith('http')}');
    
    final shouldShow = book.image.isNotEmpty && 
                      book.image.trim().isNotEmpty && 
                      (book.image.startsWith('http://') || book.image.startsWith('https://'));
    
    print('✅ Should show image: $shouldShow');
    print('─' * 50);
    
    return shouldShow;
  }

  String _getProxyImageUrl(String originalUrl) {
    // CORS 우회를 위한 프록시 서비스 사용 (임시 해결책)
    // 프로덕션에서는 자체 API 서버에 프록시 엔드포인트 구현 권장
    if (originalUrl.contains('pstatic.net')) {
      print('🔄 Using CORS proxy for: $originalUrl');
      return 'https://cors-anywhere.herokuapp.com/$originalUrl';
    }
    return originalUrl;
  }

  /// 🚀 다중 프록시 fallback 시스템 (안정적인 이미지 로딩)
  Widget _buildImageWithProxy(BookSearchResult book) {
    return _buildImageWithMultiProxy(book, 0);
  }
  
  /// 🔄 여러 프록시 서비스를 순차적으로 시도
  Widget _buildImageWithMultiProxy(BookSearchResult book, int proxyIndex) {
    // 사용 가능한 프록시 서비스들
    final proxyServices = [
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(book.image)}',
      'https://corsproxy.io/?${Uri.encodeComponent(book.image)}',
      'https://cors-anywhere.herokuapp.com/${book.image}',
      book.image, // 마지막에 원본 URL 시도
    ];
    
    if (proxyIndex >= proxyServices.length) {
      print('❌ [${book.title}] All proxy services failed, showing placeholder');
      return _buildBookCoverPlaceholder(book.title);
    }
    
    final currentProxyUrl = proxyServices[proxyIndex];
    final proxyName = proxyIndex == 0 ? 'AllOrigins' : 
                     proxyIndex == 1 ? 'CorsProxy.io' :
                     proxyIndex == 2 ? 'CORS-Anywhere' : 'Direct';
                     
    print('🔄 [${book.title}] Trying ${proxyName} (${proxyIndex + 1}/${proxyServices.length}): $currentProxyUrl');
    
    return Image.network(
      currentProxyUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          print('✅ [${book.title}] Image loaded successfully with ${proxyName}!');
          return child;
        }
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
        print('❌ [${book.title}] ${proxyName} failed: $error');
        // 다음 프록시 시도
        return _buildImageWithMultiProxy(book, proxyIndex + 1);
      },
    );
  }

  /// 🔄 다중 프록시 시도 (더 안정적인 이미지 로딩)
  Widget _buildImageWithFallbacks(BookSearchResult book) {
    final originalUrl = book.image;
    
    // 시도할 프록시 서비스들 (순서대로)
    final proxyUrls = [
      originalUrl, // 1. 원본 URL 먼저 시도
      'https://cors-anywhere.herokuapp.com/$originalUrl', // 2. CORS Anywhere
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}', // 3. AllOrigins
      'https://corsproxy.io/?${Uri.encodeComponent(originalUrl)}', // 4. CorsProxy.io
    ];

    return _buildImageWithProxyFallback(book, proxyUrls, 0);
  }

  /// 🔄 재귀적으로 프록시 URL들을 시도하는 위젯
  Widget _buildImageWithProxyFallback(BookSearchResult book, List<String> proxyUrls, int currentIndex) {
    if (currentIndex >= proxyUrls.length) {
      // 모든 프록시 실패 시 플레이스홀더 표시
      print('❌ [${book.title}] All proxy attempts failed, showing placeholder');
      return _buildBookCoverPlaceholder(book.title);
    }

    final currentUrl = proxyUrls[currentIndex];
    print('🔄 [${book.title}] Trying proxy ${currentIndex + 1}/${proxyUrls.length}: $currentUrl');

    return Image.network(
      currentUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          print('✅ [${book.title}] Image loaded successfully with proxy ${currentIndex + 1}!');
          return child;
        }
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
        print('❌ [${book.title}] Proxy ${currentIndex + 1} failed: $error');
        
        // 다음 프록시 시도
        return _buildImageWithProxyFallback(book, proxyUrls, currentIndex + 1);
      },
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
