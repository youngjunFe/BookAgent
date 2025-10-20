import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/elevation_levels.dart';
import '../../../core/services/time_based_message_service.dart';
import '../../../shared/widgets/main_navigation.dart';
import '../../chat/presentation/ai_chat_page.dart';
import '../../chat/presentation/character_selection_page.dart';
import '../../reading_goals/presentation/reading_goals_page.dart';
import '../../book_search/presentation/book_search_page.dart';
import '../../auth/services/supabase_auth_service.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigation();
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final SupabaseAuthService _authService = SupabaseAuthService();
  String? _userNickname;
  TimeBasedMessage? _timeBasedMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) => _loadTimeBasedMessage());
  }

  Future<void> _loadUserData() async {
    try {
      final userInfo = _authService.currentUserInfo;
      if (userInfo != null) {
        if (mounted) {
          setState(() {
            _userNickname = userInfo.nickname;
          });
        }
      }
    } catch (e) {
      print('사용자 데이터 로딩 실패: $e');
      if (mounted) {
        setState(() {
          _userNickname = '사용자';
        });
      }
    }
  }

  void _loadTimeBasedMessage() {
    final isLoggedIn = _authService.isLoggedIn;
    final nickname = _userNickname ?? '사용자';
    final timeMessage = TimeBasedMessageService.getMessageForCurrentTime(
      isLoggedIn: isLoggedIn,
      nickname: nickname,
    );
    
    setState(() {
      _timeBasedMessage = timeMessage;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '홈',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            // 시간별 인사말 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _timeBasedMessage?.message1 ?? '안녕하세요!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D3D3D),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  Text(
                    _timeBasedMessage?.message2 ?? '오늘도 좋은 하루 보내세요!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D3D3D),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 캐러셀 이미지
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: _buildCarouselImage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 캐러셀 이미지 위젯
  Widget _buildCarouselImage() {
    final List<String> slideImages = [
      'https://raw.githubusercontent.com/youngjunFe/BookAgent/main/assets/images/slides/slide1.png',
      'https://raw.githubusercontent.com/youngjunFe/BookAgent/main/assets/images/slides/slide2.png', 
      'https://raw.githubusercontent.com/youngjunFe/BookAgent/main/assets/images/slides/slide3.png',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          // PageView - 328:476 비율 유지 및 상단 정렬
          Align(
            alignment: Alignment.topCenter,
            child: AspectRatio(
              aspectRatio: 328 / 476, // 디자인 비율
              child: Stack(
                children: [
                  // 슬라이드 이미지
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: slideImages.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          slideImages[index],
                          fit: BoxFit.contain, // 비율 유지하면서 전체 이미지 표시
                          alignment: Alignment.topCenter, // 상단 정렬
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ 이미지 로딩 실패: ${slideImages[index]}');
                            print('❌ 에러: $error');
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '이미지 로딩 실패',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  
                  // 이전 버튼 - 슬라이드 중앙 좌측
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (_currentPage > 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Icon(
                          Icons.chevron_left,
                          color: Color(0xFF3D3D3D),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  
                  // 다음 버튼 - 슬라이드 중앙 우측
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (_currentPage < slideImages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Icon(
                          Icons.chevron_right,
                          color: Color(0xFF3D3D3D),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  
                  // '지금 감동을 기록하세요' 버튼 - 슬라이드 내부 최하단
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const BookSearchPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D74B6),
                            foregroundColor: const Color(0xFFFCFCFC),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          child: const Text(
                            '지금 감동을 기록하세요',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFCFCFC),
                              letterSpacing: -0.18,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}