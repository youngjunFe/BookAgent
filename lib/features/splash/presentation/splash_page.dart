import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/main_navigation.dart';
import '../../auth/services/supabase_auth_service.dart';
import '../../auth/presentation/login_page.dart';
import '../../auth/presentation/terms_agreement_page.dart';
import '../../review/presentation/review_creation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'intro_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/supabase/supabase_client_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // 애니메이션 컨트롤러 초기화
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // 애니메이션 시작
    _fadeController.forward();
    _scaleController.forward();
    
    _initializeApp();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // 스플래시 화면을 2.5초 동안 보여줌
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    // 로그인 상태 확인
    final authService = SupabaseAuthService();
    final isLoggedIn = await authService.restoreLoginState();
    
    if (isLoggedIn) {
      // 약관 동의 여부 확인
      final hasAgreedTerms = await _checkTermsAgreement();
      
      if (!hasAgreedTerms) {
        // 약관 미동의 사용자 - 약관 동의 페이지로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TermsAgreementPage()),
        );
        return;
      }
      
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

  Future<bool> _checkTermsAgreement() async {
    try {
      final user = SupabaseClientProvider.client.auth.currentUser;
      if (user == null) return false;
      
      final response = await SupabaseClientProvider.client
          .from('user_profiles')
          .select('terms_agreed')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (response == null) return false;
      
      return response['terms_agreed'] == true;
    } catch (e) {
      print('❌ 약관 동의 확인 실패: $e');
      return false; // 에러 시 약관 동의 페이지로 이동
    }
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8DC), // 크림색/연한 노란색
              Color(0xFFFFE4B5), // 모카신 색
              Color(0xFFFFC0CB), // 핑크색
              Color(0xFFE6E6FA), // 라벤더색
              Color(0xFFADD8E6), // 라이트 블루
              Color(0xFF87CEEB), // 스카이 블루
            ],
            stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 브랜드 로고 (Inline SVG로 로드 이슈 제거)
                    SvgPicture.string(
                      _inlineSplashSvg,
                      width: 120,
                      height: 120,
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // 메인 텍스트
                    Text(
                      '감동의 순간을 놓치지 마세요',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50), // 진한 네이비색
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Inline SVG (자산 로딩 이슈 회피)
  static const String _inlineSplashSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="0 0 120 120" fill="none">
  <path d="M103.33 58.5496C109.5 49.8391 97.7303 42.997 81.8621 42.997L37.8213 67.884C60.5916 72.4381 92.7529 73.482 103.33 58.5496Z" fill="#2189F9" fill-opacity="0.3"/>
  <path d="M64.441 95.8822C72.2209 100.858 80.9315 104.591 90.8863 101.48C107.095 96.4146 95.2416 53.5721 81.8621 42.9969L37.8213 67.8841C46.3978 82.8164 59.1995 92.53 64.441 95.8822Z" fill="#2189F9" fill-opacity="0.3"/>
  <path d="M62.5746 96.5044C75.6142 85.805 84.3513 58.5447 81.8627 42.9902L37.8214 67.8842C37.8214 67.8842 31.135 78.235 31.1829 94.4282C31.2264 109.16 49.535 107.204 62.5746 96.5044Z" fill="#2189F9" fill-opacity="0.3"/>
  <path d="M45.1535 20.5983C34.9726 30.9392 33.3321 54.1961 37.8212 67.8846L81.8621 42.9966C75.5064 9.39845 53.7302 11.8868 45.1535 20.5983Z" fill="#2189F9" fill-opacity="0.3"/>
  <path d="M37.8214 67.8838C26.1797 66.0158 8.45022 55.4372 17.4693 47.3502C34.3601 32.2051 68.1742 38.6418 81.8622 42.9971L37.8214 67.8838Z" fill="#2189F9" fill-opacity="0.3"/>
</svg>
''';

  // 기존 커스텀 레인보우 아이콘은 제거
}