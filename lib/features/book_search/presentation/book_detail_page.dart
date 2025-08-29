import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/elevation_levels.dart';
import '../../chat/presentation/ai_chat_page.dart';
import '../models/book_search_result.dart';

class BookDetailPage extends StatelessWidget {
  final BookSearchResult book;

  const BookDetailPage({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 책 정보 카드
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // 책 표지 이미지
                        _buildBookCover(),
                        
                        const SizedBox(height: 32),
                        
                        // 책 제목
                        Text(
                          book.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 저자 및 출판사
                        Text(
                          '${book.author} 지음 | ${book.publisher}',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // 책 설명
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _getBookDescription(),
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                                height: 1.6,
                                letterSpacing: -0.2,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // 감동 기록하기 버튼
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // 채팅 페이지로 이동
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => AiChatPage(
                          initialContext: '선택한 책: ${book.title} (${book.author})\n\n이 책에 대해 대화해보세요!',
                          bookTitle: book.title,
                          bookAuthor: book.author,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: AppColors.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '감동 기록하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 책 표지 이미지 위젯
  Widget _buildBookCover() {
    return Container(
      width: 180,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: book.image.isNotEmpty
            ? _buildImageWithFallbacks(book)
            : _buildBookCoverPlaceholder(book.title),
      ),
    );
  }

  // 다중 프록시 fallback 이미지 로딩 (book_search_page.dart와 동일)
  Widget _buildImageWithFallbacks(BookSearchResult book) {
    final List<String> proxyUrls = [
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(book.image)}',
      'https://corsproxy.io/?${Uri.encodeComponent(book.image)}',
      'https://cors-anywhere.herokuapp.com/${book.image}',
      book.image, // 직접 URL (마지막 시도)
    ];

    return _buildImageWithProxyFallback(book, proxyUrls, 0);
  }

  Widget _buildImageWithProxyFallback(BookSearchResult book, List<String> proxyUrls, int currentIndex) {
    if (currentIndex >= proxyUrls.length) {
      return _buildBookCoverPlaceholder(book.title);
    }

    final currentUrl = proxyUrls[currentIndex];
    print('🔄 [${book.title}] Trying proxy ${currentIndex + 1}/${proxyUrls.length}: $currentUrl');

    return Image.network(
      currentUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          print('✅ [${book.title}] Image loaded successfully with proxy ${currentIndex + 1}');
          return child;
        }
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ [${book.title}] Proxy ${currentIndex + 1} failed: $error');
        return _buildImageWithProxyFallback(book, proxyUrls, currentIndex + 1);
      },
    );
  }

  // 플레이스홀더 이미지
  Widget _buildBookCoverPlaceholder(String title) {
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            selectedColor.withOpacity(0.7),
            selectedColor.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              initial,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              Icons.menu_book,
              color: Colors.white.withOpacity(0.8),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  // 책 설명 생성
  String _getBookDescription() {
    // 실제로는 API에서 받아오거나 데이터베이스에서 가져올 수 있지만,
    // 현재는 간단한 설명을 생성합니다.
    return '이 책은 ${book.author}의 작품으로, ${book.publisher}에서 출간되었습니다.\n\n'
           '책을 읽으며 느꼈던 감동과 생각들을 AI와 함께 나누어보세요. '
           '작품 속 인물들의 감정과 상황에 대해 깊이 있는 대화를 나누며, '
           '새로운 관점과 통찰을 얻을 수 있습니다.\n\n'
           '아래 "감동 기록하기" 버튼을 눌러 이 책에 대한 '
           '여러분만의 독특한 감상과 생각을 기록해보세요.';
  }
}
