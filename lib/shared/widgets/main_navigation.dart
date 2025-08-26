import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/library/presentation/library_page.dart';
import '../../features/auth/services/supabase_auth_service.dart';
import '../../features/auth/presentation/login_page.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  bool _isAuthChecked = false;
  bool _isLoggedIn = false;

  List<Widget> get _pages => [
    const HomeView(),
    const LibraryPage(), 
    _buildMyPageWithAuth(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkAuthenticationStatus();
  }

  // 🚨🚨🚨 최강 인증 체크: 앱 전체 접근 제어
  Future<void> _checkAuthenticationStatus() async {
    try {
      print('🔒 [MainNavigation] 인증 상태 확인 시작');
      
      final authService = SupabaseAuthService();
      final isLoggedIn = await authService.restoreLoginState();
      
      print('📋 [MainNavigation] 로그인 상태: $isLoggedIn');
      
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isAuthChecked = true;
      });
      
      // 🚨🚨🚨 비로그인 사용자는 즉시 로그인 페이지로 리다이렉트
      if (!isLoggedIn && mounted) {
        print('🚨 [MainNavigation] 비인증 사용자 감지 - 로그인 페이지로 강제 리디렉션');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return;
      }
      
      // 🚨 추가 보안: 주기적으로 인증 상태 재확인
      _startPeriodicAuthCheck();
      
    } catch (e) {
      print('❌ [MainNavigation] 인증 상태 확인 실패: $e');
      setState(() {
        _isLoggedIn = false;
        _isAuthChecked = true;
      });
      
      // 에러 발생시에도 로그인 페이지로 리다이렉트
      if (mounted) {
        print('🚨 [MainNavigation] 인증 오류 - 로그인 페이지로 리디렉션');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }
  
  // 🚨 주기적 인증 확인 (30초마다)
  void _startPeriodicAuthCheck() {
    Future.delayed(const Duration(seconds: 30), () async {
      if (!mounted) return;
      
      try {
        final authService = SupabaseAuthService();
        final currentUser = authService.currentUser;
        
        if (currentUser == null) {
          print('🚨 [MainNavigation] 주기적 체크: 세션 만료 감지');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
          return;
        }
        
        // 다음 체크 예약
        _startPeriodicAuthCheck();
      } catch (e) {
        print('❌ [MainNavigation] 주기적 인증 체크 실패: $e');
      }
    });
  }

  Widget _buildMyPageWithAuth() {
    return FutureBuilder<bool>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        
        final isLoggedIn = snapshot.data ?? false;
        
        if (isLoggedIn) {
          return const MyPage();
        } else {
          return _buildLoginPrompt();
        }
      },
    );
  }

  Future<bool> _checkLoginStatus() async {
    try {
      final authService = SupabaseAuthService();
      return await authService.restoreLoginState();
    } catch (e) {
      print('마이페이지 로그인 체크 에러: $e');
      return false;
    }
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '로그인이 필요합니다',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '마이페이지를 이용하려면\n로그인해주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '로그인하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 인증 체크가 완료되지 않았거나 로그인되지 않은 경우 로딩 화면
    if (!_isAuthChecked || !_isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('인증 확인 중...'),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.navigationBackground,
          selectedItemColor: AppColors.selectedTab,
          unselectedItemColor: AppColors.unselectedTab,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: AppStrings.home,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined),
              activeIcon: Icon(Icons.library_books),
              label: AppStrings.library,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: AppStrings.myPage,
            ),
          ],
        ),
      ),
    );
  }
}

// 임시 마이페이지 (추후 별도 파일로 분리)
class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.myPage),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 사용자 정보 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.dividerColor,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder(
                    future: _getUserInfo(),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      return Column(
                        children: [
                          Text(
                            user?.name ?? '사용자',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user?.provider.toUpperCase() ?? '',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 메뉴 리스트
            Column(
              children: [
                _MenuItem(
                  icon: Icons.settings,
                  title: AppStrings.settings,
                  onTap: () {
                    // TODO: 설정 페이지
                  },
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  title: AppStrings.about,
                  onTap: () {
                    // TODO: 앱 정보 페이지
                  },
                ),
                _MenuItem(
                  icon: Icons.logout,
                  title: AppStrings.logout,
                  textColor: AppColors.error,
                  onTap: () => _handleLogout(context),
                ),
              ],
            ),
            
            const Spacer(),
            
            // 앱 버전 정보
            Text(
              '${AppStrings.version} 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<dynamic> _getUserInfo() async {
    // SupabaseAuthService에서 현재 사용자 정보 가져오기
    return SupabaseAuthService().currentUser;
  }
  
  Future<void> _handleLogout(BuildContext context) async {
    // 로그아웃 확인 다이얼로그
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              AppStrings.logout,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    
    if (shouldLogout == true && context.mounted) {
      // 로그아웃 실행
      await SupabaseAuthService().signOut();
      
      // 로그인 페이지로 이동 (스택 전체 교체)
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    }
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? textColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: textColor ?? AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textHint,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: AppColors.surface,
      ),
    );
  }
}
