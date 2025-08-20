import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/login_page.dart';
import '../../guest/presentation/guest_demo_page.dart';
import '../../../shared/widgets/main_navigation.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<IntroPageData> _pages = [
    IntroPageData(
      title: '책을 읽는 순간의 그 감동',
      description: '사라지기 전에 AI와 대화하세요',
      features: [
        '책을 읽는 순간의 그 감동',
        '사라지기 전에 AI와 대화하세요',
      ],
      buttonText: '다음',
      showBrowseButton: false,
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
      title: 'AI 지혜와 5분 대화로 당신의 감동을',
      description: '하나의 에세이로 만들어 드립니다',
      features: [
        'AI와 5분 대화',
        '개인화된 질문',
        '감동을 에세이로 변환',
      ],
      buttonText: '다음',
      showBrowseButton: true,
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

  void _skipToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _startBrowsing() {
    // 둘러보기 - 게스트 데모 페이지로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const GuestDemoPage()),
    );
  }

  Widget _buildSearchDemo() {
    return Column(
      children: [
        // 검색 입력창 데모
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '어떤 책을 읽으셨나요?',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(
                Icons.search,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 검색 결과 데모
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.dividerColor),
          ),
          child: Row(
            children: [
              // 책 표지 데모
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
              // 책 정보
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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

            // 하단 영역
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 페이지 인디케이터
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentPage
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 둘러보기 버튼 (조건부 표시)
                  if (_pages[_currentPage].showBrowseButton == true) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _startBrowsing,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '둘러보기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 다음/시작하기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _pages[_currentPage].buttonText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class IntroPageData {
  final String title;
  final String description;
  final List<String> features;
  final String buttonText;
  final bool showBrowseButton;
  final bool showSearchDemo;

  IntroPageData({
    required this.title,
    required this.description,
    required this.features,
    required this.buttonText,
    this.showBrowseButton = false,
    this.showSearchDemo = false,
  });
}

