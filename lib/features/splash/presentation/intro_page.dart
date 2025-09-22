import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/login_page.dart';
import '../../guest/presentation/guest_demo_page.dart';
import '../../../shared/widgets/main_navigation.dart';
import '../../book_search/presentation/book_search_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  List<BookSearchResult> _searchResults = [];
  bool _isSearching = false;

  final List<IntroPageData> _pages = [
    IntroPageData(
      title: '책을 덮는 순간의 감동',
      description: '사라지기 전에 대화하세요',
      features: [
        '책을 덮는 순간의 감동',
        '사라지기 전에 대화하세요',
      ],
      buttonText: '치읓과 대화하기',
      showBrowseButton: true,
      showAiChatButton: true,
    ),
    IntroPageData(
      title: 'AI 지혜와 5분 대화로 당신의 감동을',
      description: '하나의 에세이로 만들어 드립니다',
      features: [
        'AI와 5분 대화',
        '개인화된 질문',
        '감동을 에세이로 변환',
      ],
      buttonText: 'AI와 대화하기',
      showBrowseButton: true,
      showAiChatButton: true,
    ),
    IntroPageData(
      title: '어떤 책을 읽으셨나요?',
      description: '네이버 도서 검색으로 찾아보세요',
      features: [
        '네이버 도서 검색',
        '다양한 책 정보 제공',
        '간편한 책 선택',
      ],
      buttonText: '다음',
      showBrowseButton: true,
      showSearchDemo: true,
    ),
    IntroPageData(
      title: '지금 시작하세요',
      description: '당신만의 독서 여정을 시작해보세요',
      features: [
        '무료로 체험',
        '간편한 회원가입',
        '즉시 사용 가능',
      ],
      buttonText: '시작하기',
      showBrowseButton: true,
    ),
  ];

  void _nextPage() {
    // "AI와 대화하기" 버튼인 경우 책 검색 페이지로 이동
    if (_pages[_currentPage].showAiChatButton == true) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const BookSearchPage()),
      );
      return;
    }
    
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 마지막 페이지에서 로그인 페이지로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Widget _buildFirstIntroPage() {
    return Container(
      // 상위 Scaffold에서 전체 그라데이션 적용 중
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Text(
              '책을 덮는 순간의 감동\n사라지기 전에 대화하세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF244B74),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'AI 치읓과 대화하면 당신의 감동을\n에세이로 만들어 드릴게요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const BookSearchPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '치읓과 대화하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _startBrowsing,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '둘러볼게요',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 첫 페이지에서 둘러보기 아래에 사업자 정보 링크 배치
            InkWell(
              onTap: () {
                if (kIsWeb) {
                  html.window.open('https://laivdata.notion.site/ebd/2734d0474fac80a78c39d382b48b8350', '_blank');
                }
              },
              child: Text(
                '사업자 정보',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  void _skipToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _startBrowsing() {
    // 둘러보기 - 홈화면으로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  Widget _buildSearchDemo() {
    return Column(
      children: [
        // 검색 입력창 (BookSearchPage 스타일)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: _isSearching 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.search),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const BookSearchPage()),
                  );
                },
              ),
            ),
            onSubmitted: (_) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BookSearchPage()),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 검색 결과 표시 (BookSearchPage 스타일)
        if (_searchResults.isNotEmpty) ...[
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final book = _searchResults[index];
                return _buildBookItem(book);
              },
            ),
          ),
        ] else ...[
          // 기본 데모 표시
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.book,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '데미안',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '헤르만 헤세',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _searchBooksInOnboarding() async {
    if (_searchController.text.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://bookagent-production-2f69.up.railway.app/api/search-books?query=${_searchController.text}'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('검색 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
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
          onTap: () => _selectBookFromOnboarding(book),
          splashColor: AppColors.primary.withOpacity(0.05),
          highlightColor: AppColors.primary.withOpacity(0.03),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              children: [
                // 📚 책 표지 이미지
                Container(
                  width: 45,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: book.image.isNotEmpty
                        ? Image.network(
                            book.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildSimplePlaceholder(book.title);
                            },
                          )
                        : _buildSimplePlaceholder(book.title),
                  ),
                ),
                const SizedBox(width: 16),
                
                // 📖 책 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 출판사
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


  Widget _buildSimplePlaceholder(String title) {
    final colors = [
      AppColors.primary,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.blue,
    ];
    final color = colors[title.hashCode % colors.length];
    
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.book,
        color: color,
        size: 24,
      ),
    );
  }

  void _selectBookFromOnboarding(BookSearchResult book) {
    // 온보딩에서 책 선택 시 게스트 데모로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GuestDemoPage(selectedBook: book),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F1FF), // 연한 블루
              Color(0xFFFFEFEA), // 연한 코랄
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
          children: [
            // 헤더 - 건너뛰기/둘러보기 버튼
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60), // 균형을 위한 공간
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _skipToLogin,
                      child: Text(
                        '건너뛰기',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60),
                ],
              ),
            ),

            // 페이지 컨텐츠
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  // 첫 페이지는 별도 디자인 적용
                  if (index == 0) {
                    return _buildFirstIntroPage();
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 제목
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            page.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // 설명
                        Text(
                          page.description,
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // 기능 목록 또는 검색 데모
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.dividerColor,
                              width: 1,
                            ),
                          ),
                          child: page.showSearchDemo == true 
                            ? _buildSearchDemo()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${index + 1}. ${page.title}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...page.features.asMap().entries.map((entry) {
                                    final featureIndex = entry.key;
                                    final feature = entry.value;
                                    final letters = ['a', 'b', 'c', 'd', 'e'];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        '${letters[featureIndex]}. $feature',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                        ),

                        const SizedBox(height: 60),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }


}

class IntroPageData {
  final String title;
  final String description;
  final List<String> features;
  final String buttonText;
  final bool showBrowseButton;
  final bool showSearchDemo;
  final bool showAiChatButton;

  IntroPageData({
    required this.title,
    required this.description,
    required this.features,
    required this.buttonText,
    this.showBrowseButton = false,
    this.showSearchDemo = false,
    this.showAiChatButton = false,
  });
}

