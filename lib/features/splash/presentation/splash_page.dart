import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/main_navigation.dart';
import '../../auth/services/supabase_auth_service.dart';
import '../../auth/presentation/login_page.dart';
import 'intro_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 스플래시 화면을 2.5초 동안 보여줌
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    // 로그인 상태 확인
    final authService = SupabaseAuthService();
    final isLoggedIn = await authService.restoreLoginState();
    
    if (isLoggedIn) {
      // 로그인된 사용자 - 메인 내비게이션으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } else {
      // 비로그인 사용자 - 온보딩으로 이동 (첫 방문) 또는 메인으로 이동 (재방문)
      final hasSeenOnboarding = await _checkOnboardingSeen();
      
      if (hasSeenOnboarding) {
        // 재방문 - 바로 메인화면 (게스트 모드)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        // 첫 방문 - 온보딩 표시
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const IntroPage()),
        );
      }
    }
  }
  
  Future<bool> _checkOnboardingSeen() async {
    // 비로그인 사용자는 항상 온보딩 표시
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 메인 로고/제목
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '스플래시',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 로딩 인디케이터
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
            
            const SizedBox(height: 20),
            
            Text(
              '감동의 순간을 놓치지 마세요',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
