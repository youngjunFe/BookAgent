import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/services/supabase_auth_service.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController _nicknameController = TextEditingController();
  final FocusNode _nicknameFocusNode = FocusNode();
  bool _isLoading = false;
  String? _nicknameError;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
    _nicknameController.addListener(_onNicknameChanged);
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_onNicknameChanged);
    _nicknameController.dispose();
    _nicknameFocusNode.dispose();
    super.dispose();
  }

  void _onNicknameChanged() {
    setState(() {
      _hasUnsavedChanges = true;
      _nicknameError = null;
    });
  }

  Future<void> _loadCurrentUserInfo() async {
    try {
      final userInfo = await SupabaseAuthService().getSafeCurrentUserInfo();
      if (userInfo != null && mounted) {
        setState(() {
          _nicknameController.text = userInfo.nickname ?? '';
        });
      }
    } catch (e) {
      print('사용자 정보 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '프로필 정보 수정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => _handleBackPress(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // 프로필 이미지 섹션
            _buildProfileImageSection(),
            
            const SizedBox(height: 60),
            
            // 닉네임 입력 섹션
            _buildNicknameSection(),
            
            const SizedBox(height: 40),
            
            // 닉네임 규칙 안내
            _buildNicknameRules(),
            
            const SizedBox(height: 60),
            
            // 저장 버튼
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        // 프로필 이미지
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF9BB5D6), // 이미지와 같은 파란색
            border: Border.all(
              color: AppColors.dividerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.person,
            size: 60,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 이미지 편집 버튼
        OutlinedButton(
          onPressed: () => _showImageEditOptions(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            side: BorderSide(color: AppColors.dividerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: AppColors.surface,
          ),
          child: const Text(
            '이미지 편집',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNicknameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 닉네임 라벨
        const Text(
          '닉네임',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 닉네임 입력 필드 (빨간 테두리)
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _nicknameError != null ? Colors.red : AppColors.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.surface,
          ),
          child: TextField(
            controller: _nicknameController,
            focusNode: _nicknameFocusNode,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '닉네임을 입력하세요',
              hintStyle: TextStyle(
                color: AppColors.textHint,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: _nicknameError != null
                  ? const Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 20,
                    )
                  : null,
            ),
            onSubmitted: (_) => _validateAndSaveNickname(),
          ),
        ),
        
        // 에러 메시지
        if (_nicknameError != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _nicknameError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNicknameRules() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '닉네임 규칙',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '닉네임은 한글 2-10자까지 사용 가능해요',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading || !_hasUnsavedChanges
            ? null
            : _validateAndSaveNickname,
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasUnsavedChanges
              ? AppColors.primary
              : AppColors.dividerColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                '저장하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showImageEditOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '프로필 이미지 편집',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('갤러리에서 이미지 선택');
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('카메라로 촬영');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('기본 이미지로 변경'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('기본 이미지로 변경');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 기능은 준비 중입니다.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  bool _validateNickname(String nickname) {
    if (nickname.trim().isEmpty) {
      setState(() {
        _nicknameError = '닉네임을 입력해주세요';
      });
      return false;
    }

    // 한글 2-10자 검증
    final koreanRegex = RegExp(r'^[가-힣]{2,10}$');
    if (!koreanRegex.hasMatch(nickname.trim())) {
      setState(() {
        _nicknameError = '도서추천받는티베여우지';
      });
      return false;
    }

    return true;
  }

  Future<void> _validateAndSaveNickname() async {
    final nickname = _nicknameController.text.trim();
    
    if (!_validateNickname(nickname)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 실제 닉네임 업데이트 API 호출
      await Future.delayed(const Duration(seconds: 1)); // 시뮬레이션
      
      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 성공적으로 업데이트되었습니다.'),
            backgroundColor: AppColors.primary,
          ),
        );
        
        Navigator.of(context).pop(true); // 성공 결과 반환
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _nicknameError = '프로필 업데이트에 실패했습니다. 다시 시도해주세요.';
        });
      }
    }
  }

  void _handleBackPress() {
    if (_hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '변경사항이 있습니다',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            '저장하지 않고 나가시겠습니까?\n변경사항이 사라집니다.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                '나가기',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }
}
