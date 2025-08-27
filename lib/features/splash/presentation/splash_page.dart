import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/main_navigation.dart';
import '../../auth/services/supabase_auth_service.dart';
import '../../auth/presentation/login_page.dart';
import '../../review/presentation/review_creation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      // 로그인된 사용자 - 임시 저장된 발제문 확인
      final hasTempReview = await _checkTempReview();
      
      if (hasTempReview) {
        // 임시 저장된 발제문이 있으면 작성 페이지로 이동 (책 정보도 함께 전달)
        final prefs = await SharedPreferences.getInstance();
        final tempBookTitle = prefs.getString('temp_book_title');
        final tempBookAuthor = prefs.getString('temp_book_author');
        final tempChatHistory = prefs.getString('temp_chat_history');
        bool _isBanned(String? v) {
          if (v == null) return true;
          final t = v.trim();
          return t.isEmpty || t == '안녕하세요' || t == '책';
        }

        print('🚀 [SplashPage] Temp handoff to ReviewCreationPage: '
            'title="${_isBanned(tempBookTitle) ? '(none)' : tempBookTitle}", '
            'author="${_isBanned(tempBookAuthor) ? '(none)' : tempBookAuthor}"');
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ReviewCreationPage(
              bookTitle: _isBanned(tempBookTitle) ? null : tempBookTitle,
              bookAuthor: _isBanned(tempBookAuthor) ? null : tempBookAuthor,
              chatHistory: tempChatHistory,
            ),
          ),
        );
      } else {
        // 임시 저장된 발제문이 없으면 메인 내비게이션으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } else {
      // 비로그인 사용자는 데모 페이지로 이동
      print('🧪 [SplashPage] 비인증 사용자 - 게스트 데모 페이지로 이동');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const IntroPage()),
      );
    }
  }
  
  Future<bool> _checkOnboardingSeen() async {
    // 비로그인 사용자는 항상 온보딩 표시 (강제)
    print('🔍 온보딩 체크: 항상 false 반환 (온보딩 강제 표시)');
    return false;
  }

  Future<bool> _checkTempReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tempReview = prefs.getString('temp_review');
      return tempReview != null && tempReview.isNotEmpty;
    } catch (e) {
      return false;
    }
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
