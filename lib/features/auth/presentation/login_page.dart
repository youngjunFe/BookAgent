import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../services/supabase_auth_service.dart';
import '../../../shared/widgets/main_navigation.dart';

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
                        onPressed: () => _showTermsDialog(context),
                        child: Text(
                          '이용약관',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        ' | ',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showPrivacyDialog(context),
                        child: Text(
                          '개인정보 처리방침',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
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

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '서비스 이용약관',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '''제1조 (목적)
본 약관은 BookAgent(이하 "회사")가 제공하는 AI 기반 독서 서비스(이하 "서비스")의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (정의)
1. "서비스"란 회사가 제공하는 AI 독서 도우미, 책 검색, 독서 감상문 작성 지원 등의 서비스를 말합니다.
2. "이용자"란 본 약관에 따라 회사가 제공하는 서비스를 받는 회원 및 비회원을 말합니다.
3. "회원"란 회사에 개인정보를 제공하여 회원등록을 한 자로서, 회사의 정보를 지속적으로 제공받으며 회사가 제공하는 서비스를 계속적으로 이용할 수 있는 자를 말합니다.

제3조 (약관의 효력 및 변경)
1. 본 약관은 서비스를 이용하고자 하는 모든 이용자에 대하여 그 효력을 발생합니다.
2. 회사는 필요한 경우 본 약관을 변경할 수 있으며, 변경된 약관은 서비스 내 공지사항을 통해 공지됩니다.

제4조 (서비스의 제공)
1. 회사는 다음과 같은 서비스를 제공합니다:
   - AI 독서 도우미 채팅 서비스
   - 도서 검색 및 추천 서비스
   - 독서 감상문 작성 지원 서비스
   - 기타 독서 관련 부가 서비스

제5조 (서비스 이용의 제한)
회사는 다음 각 호에 해당하는 경우 서비스 이용을 제한할 수 있습니다:
1. 타인의 개인정보를 도용한 경우
2. 서비스의 안정적 운영을 방해하는 행위를 한 경우
3. 기타 관련 법령을 위반한 경우

제6조 (면책조항)
1. 회사는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 관한 책임이 면제됩니다.
2. 회사는 이용자의 귀책사유로 인한 서비스 이용의 장애에 대하여는 책임을 지지 않습니다.

본 약관은 2024년 1월 1일부터 시행됩니다.''',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '개인정보 처리방침',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '''제1조 (개인정보의 처리목적)
BookAgent(이하 "회사")는 다음의 목적을 위하여 개인정보를 처리합니다:
1. 회원가입 및 관리
2. 서비스 제공 및 개선
3. 고객 문의 및 불만 처리
4. 서비스 이용 통계 분석

제2조 (개인정보의 처리 및 보유기간)
1. 회사는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집시에 동의받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.
2. 각각의 개인정보 처리 및 보유 기간은 다음과 같습니다:
   - 회원가입 및 관리: 회원 탈퇴시까지
   - 서비스 제공: 서비스 이용 종료시까지

제3조 (개인정보의 제3자 제공)
회사는 정보주체의 개인정보를 제1조(개인정보의 처리목적)에서 명시한 범위 내에서만 처리하며, 정보주체의 동의, 법률의 특별한 규정 등 개인정보보호법 제17조 및 제18조에 해당하는 경우에만 개인정보를 제3자에게 제공합니다.

제4조 (개인정보처리의 위탁)
회사는 원활한 개인정보 업무처리를 위하여 다음과 같이 개인정보 처리업무를 위탁하고 있습니다:
1. Supabase: 사용자 인증 및 데이터 저장
2. OpenAI: AI 채팅 서비스 제공
3. Naver: 도서 검색 서비스 제공

제5조 (정보주체의 권리·의무 및 행사방법)
정보주체는 회사에 대해 언제든지 다음 각 호의 개인정보 보호 관련 권리를 행사할 수 있습니다:
1. 개인정보 처리현황 통지요구
2. 개인정보 열람요구
3. 개인정보 정정·삭제요구
4. 개인정보 처리정지요구

제6조 (개인정보의 안전성 확보조치)
회사는 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다:
1. 개인정보 취급 직원의 최소화 및 교육
2. 개인정보에 대한 접근 제한
3. 개인정보를 안전하게 저장·전송할 수 있는 암호화 기술의 사용
4. 해킹이나 컴퓨터 바이러스 등에 의한 개인정보 유출 및 훼손을 막기 위한 보안시스템 구축

제7조 (개인정보 보호책임자)
회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.

개인정보 보호책임자
- 성명: 준페
- 연락처: jun.fe.dev@gmail.com

본 개인정보 처리방침은 2024년 1월 1일부터 시행됩니다.''',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
