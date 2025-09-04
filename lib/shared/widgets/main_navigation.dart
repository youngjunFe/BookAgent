import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/elevation_levels.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/library/presentation/library_page.dart';
import '../../features/auth/services/supabase_auth_service.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/nickname_test_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client_provider.dart';

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

  // 🚨🚨🚨 최강 인증 체크: 앱 전체 접근 제어 + 탈퇴 계정 차단
  Future<void> _checkAuthenticationStatus() async {
    try {
      print('🔒 [MainNavigation] 인증 상태 확인 시작');
      
      final authService = SupabaseAuthService();
      final isLoggedIn = await authService.restoreLoginState();
      
      print('📋 [MainNavigation] 기본 로그인 상태: $isLoggedIn');
      
      // 🔄 탈퇴 감지 로직 임시 비활성화 (테스트를 위해)
      bool finalLoginStatus = isLoggedIn;
      // TODO: 탈퇴 기능 완성 후 다시 활성화
      /*
      if (isLoggedIn) {
        final isDeleted = await authService.isDeletedAccount();
        if (isDeleted) {
          print('🔄 [MainNavigation] 탈퇴 계정 재가입 처리');
        }
      }
      */
      
      print('📋 [MainNavigation] 최종 로그인 상태: $finalLoginStatus');
      
      setState(() {
        _isLoggedIn = finalLoginStatus;
        _isAuthChecked = true;
      });
      
      // 🚨 비로그인 사용자만 로그인 페이지로 리다이렉트 (탈퇴 계정은 재가입 허용)
      if (!finalLoginStatus && mounted) {
        print('🚨 [MainNavigation] 비인증 사용자 감지 - 로그인 페이지로 리디렉션');
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
        decoration: BoxDecoration(
          boxShadow: ElevationLevels.level2, // Level2 Elevation - 메인 인터랙션 요소
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
class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
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
                          // 닉네임 (메인 표시)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  user?.nickname ?? '닉네임 없음',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _showNicknameEditDialog(context, user),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 실명 (보조 표시)
                          if (user?.name != null && user?.name != user?.nickname)
                            Text(
                              '(${user?.name})',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 이메일
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 로그인 제공자
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
                // 임시 테스트 메뉴 (개발용)
                _MenuItem(
                  icon: Icons.bug_report,
                  title: '닉네임 API 테스트',
                  textColor: Colors.purple,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NicknameTestPage(),
                      ),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.logout,
                  title: AppStrings.logout,
                  textColor: AppColors.error,
                  onTap: () => _handleLogout(context),
                ),
                const SizedBox(height: 16),
                // 위험한 작업 구분선
                Container(
                  height: 1,
                  color: AppColors.dividerColor,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                const SizedBox(height: 8),
                _MenuItem(
                  icon: Icons.delete_forever,
                  title: '회원 탈퇴',
                  textColor: Colors.red[700],
                  onTap: () => _handleDeleteAccount(context),
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
    // 임시: 탈퇴 체크 비활성화 (테스트를 위해)
    return SupabaseAuthService().currentUserInfo;
  }

  // 닉네임 편집 다이얼로그
  Future<void> _showNicknameEditDialog(BuildContext context, dynamic user) async {
    final TextEditingController controller = TextEditingController();
    controller.text = user?.nickname ?? '';
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;
          
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.edit, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text('닉네임 변경'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  maxLength: 20,
                  decoration: InputDecoration(
                    hintText: '새로운 닉네임을 입력하세요',
                    hintStyle: TextStyle(color: AppColors.textHint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                    counterStyle: TextStyle(color: AppColors.textHint),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '• 2-20자 사이로 입력해주세요\n• 한글, 영문, 숫자만 사용 가능합니다\n• 다른 사용자와 중복될 수 없습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: Text(
                  AppStrings.cancel,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final newNickname = controller.text.trim();
                  
                  if (newNickname.isEmpty) {
                    _showSnackBar(context, '닉네임을 입력해주세요', isError: true);
                    return;
                  }
                  
                  if (newNickname == user?.nickname) {
                    Navigator.of(context).pop();
                    return;
                  }
                  
                  setState(() => isLoading = true);
                  
                  try {
                    final authService = SupabaseAuthService();
                    final user = authService.currentUser;
                    
                    if (user == null) {
                      _showSnackBar(context, '로그인 정보를 찾을 수 없습니다', isError: true);
                      return;
                    }
                    
                    // 🔍 중복 체크: profiles 테이블에서 다른 사용자가 사용 중인지 확인
                    final existingUser = await SupabaseClientProvider.client
                        .from('profiles')
                        .select('id')
                        .eq('nickname', newNickname)
                        .neq('id', user.id)  // 자신은 제외
                        .maybeSingle();
                    
                    if (existingUser != null) {
                      _showSnackBar(context, '이미 다른 사용자가 사용 중인 닉네임입니다', isError: true);
                      setState(() => isLoading = false);
                      return;
                    }
                    
                    // 🔥 중복 없으니까 메타데이터 업데이트!
                    await SupabaseClientProvider.client.auth.updateUser(
                      UserAttributes(
                        data: {
                          'nickname': newNickname,
                          'full_name': newNickname,
                          'name': newNickname,
                        }
                      )
                    );
                    
                    // profiles 테이블도 동기화 (중복 체크 용도)
                    try {
                      await SupabaseClientProvider.client
                          .from('profiles')
                          .upsert({
                            'id': user.id,
                            'email': user.email,
                            'nickname': newNickname,
                            'full_name': newNickname,
                            'updated_at': DateTime.now().toIso8601String(),
                          });
                    } catch (profileError) {
                      print('⚠️ profiles 동기화 실패 (메타데이터는 업데이트됨): $profileError');
                    }
                    
                    Navigator.of(context).pop(newNickname);
                    _showSnackBar(context, '닉네임이 변경되었습니다! 🎉');
                    
                    // UI 새로고침을 위한 setState 
                    setState(() {});
                    
                  } catch (e) {
                    _showSnackBar(context, '닉네임 변경 중 오류가 발생했습니다: $e', isError: true);
                  }
                  
                  setState(() => isLoading = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('변경하기'),
              ),
            ],
          );
        },
      ),
    );
    
    // 닉네임이 변경된 경우 UI 새로고침
    if (result != null && context.mounted) {
      setState(() {}); // MyPage 위젯을 다시 빌드하여 새로운 닉네임을 표시
    }
  }
  
  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // 회원 탈퇴 처리
  Future<void> _handleDeleteAccount(BuildContext context) async {
    final authService = SupabaseAuthService();
    final currentUser = authService.currentUserInfo;
    
    if (currentUser == null) {
      _showSnackBar(context, '로그인 정보를 찾을 수 없습니다', isError: true);
      return;
    }

    // 1단계: 탈퇴 확인 다이얼로그
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 24),
            const SizedBox(width: 8),
            Text(
              '회원 탈퇴',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '정말로 탈퇴하시겠습니까?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red[700], size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '탈퇴 시 삭제되는 데이터',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 모든 감동문과 독서 기록\n• 독서 목표 및 통계\n• 저장된 도서 정보\n• 채팅 기록 및 AI 대화',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '이 작업은 되돌릴 수 없습니다.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // 2단계: 최종 확인 (더블 체크)
    final finalConfirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '정말 마지막 확인',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.red[700],
          ),
        ),
        content: Text(
          '"${currentUser.nickname}"님의 모든 데이터가 영구적으로 삭제됩니다.\n\n정말로 탈퇴하시겠습니까?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '아니오, 유지하겠습니다',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('네, 탈퇴합니다'),
          ),
        ],
      ),
    );

    if (finalConfirm != true || !context.mounted) return;

    // 3단계: 탈퇴 처리 (로딩 다이얼로그 표시)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red[700]!),
              ),
              const SizedBox(height: 16),
              Text(
                '계정을 삭제하고 있습니다...\n잠시만 기다려주세요.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 실제 탈퇴 처리
      final deleteSuccess = await authService.deleteAccount();
      
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        
        if (deleteSuccess) {
          // 탈퇴 성공 - 로그인 페이지로 이동
          _showSnackBar(context, '회원 탈퇴가 완료되었습니다. 그동안 이용해주셔서 감사합니다.');
          
          await Future.delayed(const Duration(seconds: 1));
          
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            );
          }
        } else {
          // 탈퇴 실패
          _showSnackBar(context, '탈퇴 처리 중 오류가 발생했습니다. 다시 시도해주세요.', isError: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        _showSnackBar(context, '탈퇴 처리 중 오류가 발생했습니다: $e', isError: true);
      }
    }
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
