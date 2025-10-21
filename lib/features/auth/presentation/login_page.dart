import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../services/supabase_auth_service.dart';
import '../../../shared/widgets/main_navigation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatelessWidget {
  static const bool _showAppleLogin = false;
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
              
              // App Logo & Headline
              Column(
                children: [
                  // App Logo (same as Splash)
                  SvgPicture.string(
                    _inlineSplashSvg,
                    width: 120,
                    height: 120,
                  ),
                  
                  const SizedBox(height: 28),
                  // Headline two lines
                  Text(
                    AppStrings.loginHeadlineLine1,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.loginHeadlineLine2,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              const SizedBox(height: 48),
              
              // Social Login Buttons
              Column(
                children: [
                  // Kakao (first)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _handleKakaoSignIn(context);
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, color: Colors.black, size: 20),
                      label: Text(AppStrings.continueWithKakao),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE812),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Apple (second, black) - temporarily hidden via flag
                  if (_showAppleLogin) ...[
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
                        label: Text(AppStrings.continueWithApple),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Google (third, light gray)
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
                      label: Text(AppStrings.continueWithGoogle),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceVariant,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Terms & Privacy (moved to bottom)
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
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNotionPage(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('URL 열기 오류: $e');
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

  // Inline SVG (same as Splash logo)
  static const String _inlineSplashSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="0 0 120 120" fill="none">
  <path d="M103.33 58.5496C109.5 49.8391 97.7303 42.997 81.8621 42.997L37.8213 67.884C60.5916 72.4381 92.7529 73.482 103.33 58.5496Z" fill="#2189F9" fill-opacity="0.3"/>
  <path d="M64.441 95.8822C72.2209 100.858 80.9315 104.591 90.8863 101.48C107.095 96.4146 95.2416 53.5721 81.8621 42.9969L37.8213 67.8841C46.3978 82.8164 59.1995 92.53 64.441 95.8822Z" fill="#2189F9" fill-opacity="0.3"/>
  <path d="M62.5746 96.5044C75.6142 85.805 84.3513 58.5447 81.8627 42.9902L37.8214 67.8842C37.8214 67.8842 31.135 78.235 31.1829 94.4282C31.2264 109.16 49.535 107.204 62.5746 96.5044Z" fill="#2189F9" fill-opacity="0.3"/>
  <path d="M45.1535 20.5983C34.9726 30.9392 33.3321 54.1961 37.8212 67.8846L81.8621 42.9966C75.5064 9.39845 53.7302 11.8868 45.1535 20.5983Z" fill="#2189F9" fill-opacity="0.3"/>
  <path d="M37.8214 67.8838C26.1797 66.0158 8.45022 55.4372 17.4693 47.3502C34.3601 32.2051 68.1742 38.6418 81.8622 42.9971L37.8214 67.8838Z" fill="#2189F9" fill-opacity="0.3"/>
</svg>
''';
}