import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../services/supabase_auth_service.dart';
import '../../../shared/widgets/main_navigation.dart';
import 'dart:html' as html if (dart.library.html) 'dart:html';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Top spacer
              const Spacer(),
              
              // App Logo & Welcome
              Column(
                children: [
                  // App Icon/Logo placeholder
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // App Name
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 48,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // App Tagline
                  Text(
                    AppStrings.appTagline,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              const SizedBox(height: 64),
              
              // Welcome Message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.dividerColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '환영합니다!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI와 함께하는 특별한 독서 여행을\n시작하려면 로그인해주세요',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Social Login Buttons
              Column(
                children: [
                  // Google Login
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _handleGoogleSignIn(context);
                      },
                      icon: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      label: Text(AppStrings.googleLogin),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: AppColors.dividerColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Apple Login
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _handleAppleSignIn(context);
                      },
                      icon: const Icon(
                        Icons.apple,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(AppStrings.appleLogin),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Kakao Login
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _handleKakaoSignIn(context);
                      },
                      icon: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.brown,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'K',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      label: Text(AppStrings.kakaoLogin),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE812),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Terms & Privacy
              Column(
                children: [
                  Text(
                    '로그인하면 다음 약관에 동의하는 것으로 간주됩니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _openNotionPage('https://laivdata.notion.site/ebd/2704d0474fac80d4b84fd40b5d2cde30'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '이용약관',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      Text(
                        ' | ',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openNotionPage('https://laivdata.notion.site/ebd/2704d0474fac8015a578d6c7bc6cfbdb'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '개인정보 처리방침',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _openNotionPage(String url) {
    if (kIsWeb) {
      // 웹에서 새 탭으로 노션 페이지 열기
      _openWebUrl(url);
    } else {
      // 모바일에서는 URL 런처 사용 (추후 구현)
      // 현재는 안내 메시지만 표시
    }
  }

  // 웹에서만 사용되는 URL 열기 함수
  void _openWebUrl(String url) {
    try {
      html.window.open(url, '_blank');
    } catch (e) {
      print('웹 URL 열기 오류: $e');
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      // 웹에서는 OAuth 리다이렉트가 발생하므로 로딩 다이얼로그 표시하지 않음
      await SupabaseAuthService().signInWithGoogle();
      
      // 웹에서는 리다이렉트가 발생하므로 이 코드는 실행되지 않음
      // 리다이렉트 후 앱이 다시 로드될 때 AuthWrapper에서 로그인 상태 확인
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google 로그인 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleAppleSignIn(BuildContext context) async {
    try {
      // 로딩 표시
      _showLoadingDialog(context, 'Apple 로그인 중...');
      
      final result = await SupabaseAuthService().signInWithApple();
      
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        
        if (result.isSuccess) {
          // 로그인 성공 - 메인 페이지로 이동
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainNavigation()),
          );
        } else if (result.isCancelled) {
          // 사용자가 취소한 경우는 메시지 표시 안함
        } else {
          // 로그인 실패
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Apple 로그인에 실패했습니다.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleKakaoSignIn(BuildContext context) async {
    try {
      // 웹에서는 OAuth 리다이렉트가 발생하므로 로딩 다이얼로그 표시하지 않음
      await SupabaseAuthService().signInWithKakao();
      
      // 웹에서는 리다이렉트가 발생하므로 이 코드는 실행되지 않음
      // 리다이렉트 후 앱이 다시 로드될 때 AuthWrapper에서 로그인 상태 확인
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kakao 로그인 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
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
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}