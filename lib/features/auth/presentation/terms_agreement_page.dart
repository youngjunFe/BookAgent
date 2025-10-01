import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../services/supabase_auth_service.dart';
import '../../../shared/widgets/main_navigation.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import 'dart:html' as html if (dart.library.html) 'dart:html';

class TermsAgreementPage extends StatefulWidget {
  const TermsAgreementPage({super.key});

  @override
  State<TermsAgreementPage> createState() => _TermsAgreementPageState();
}

class _TermsAgreementPageState extends State<TermsAgreementPage> {
  bool _agreeAll = false;
  bool _agreeAge = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () async {
            // 뒤로가기 시 로그아웃
            await SupabaseAuthService().signOut();
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 로고
              Text(
                '대대대',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 제목
              Text(
                '서비스 이용 약관을\n확인해주세요',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 모두 동의
              _buildCheckboxItem(
                title: '모두 동의합니다',
                value: _agreeAll,
                onChanged: (value) {
                  setState(() {
                    _agreeAll = value ?? false;
                    _agreeAge = _agreeAll;
                    _agreeTerms = _agreeAll;
                    _agreePrivacy = _agreeAll;
                  });
                },
                isBold: true,
              ),
              
              const Divider(height: 32),
              
              // 만 14세 이상
              _buildCheckboxItem(
                title: '만 14세 이상입니다. (필수)',
                value: _agreeAge,
                onChanged: (value) {
                  setState(() {
                    _agreeAge = value ?? false;
                    _updateAgreeAll();
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // 서비스 이용약관
              _buildCheckboxItem(
                title: '서비스 이용약관 동의 (필수)',
                value: _agreeTerms,
                onChanged: (value) {
                  setState(() {
                    _agreeTerms = value ?? false;
                    _updateAgreeAll();
                  });
                },
                hasArrow: true,
                onArrowTap: () => _openNotionPage('https://laivdata.notion.site/ebd/2704d0474fac80d4b84fd40b5d2cde30'),
              ),
              
              const SizedBox(height: 16),
              
              // 개인정보 수집 및 이용 동의
              _buildCheckboxItem(
                title: '개인정보 수집 및 이용 동의 (필수)',
                value: _agreePrivacy,
                onChanged: (value) {
                  setState(() {
                    _agreePrivacy = value ?? false;
                    _updateAgreeAll();
                  });
                },
                hasArrow: true,
                onArrowTap: () => _openNotionPage('https://laivdata.notion.site/ebd/2704d0474fac8015a578d6c7bc6cfbdb'),
              ),
              
              const Spacer(),
              
              // 동의하고 시작하기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed ? _handleAgree : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: Text(
                    '동의하고 시작하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxItem({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool isBold = false,
    bool hasArrow = false,
    VoidCallback? onArrowTap,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (hasArrow)
            IconButton(
              onPressed: onArrowTap,
              icon: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  void _updateAgreeAll() {
    setState(() {
      _agreeAll = _agreeAge && _agreeTerms && _agreePrivacy;
    });
  }

  bool get _canProceed {
    return _agreeAge && _agreeTerms && _agreePrivacy;
  }

  Future<void> _handleAgree() async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Supabase Authentication user metadata에 약관 동의 상태 저장
      await SupabaseClientProvider.client.auth.updateUser(
        UserAttributes(
          data: {
            'terms_agreed': true,
            'terms_agreed_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
        
        // 메인 페이지로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('약관 동의 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _openNotionPage(String url) {
    if (kIsWeb) {
      _openWebUrl(url);
    }
  }

  void _openWebUrl(String url) {
    try {
      html.window.open(url, '_blank');
    } catch (e) {
      print('웹 URL 열기 오류: $e');
    }
  }
}

