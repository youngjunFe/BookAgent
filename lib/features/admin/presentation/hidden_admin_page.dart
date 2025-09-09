import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../services/admin_config_service.dart';

class HiddenAdminPage extends StatefulWidget {
  const HiddenAdminPage({super.key});

  @override
  State<HiddenAdminPage> createState() => _HiddenAdminPageState();
}

class _HiddenAdminPageState extends State<HiddenAdminPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _aiPromptController = TextEditingController();
  final TextEditingController _characterPromptController = TextEditingController();
  final TextEditingController _reviewPromptController = TextEditingController();
  final TextEditingController _aiWelcomeController = TextEditingController();
  final TextEditingController _characterWelcomeController = TextEditingController();
  final TextEditingController _minChatCountController = TextEditingController();
  final TextEditingController _maxChatCountController = TextEditingController();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String _selectedPromptType = 'ai_chat';
  String _selectedConfigType = 'prompts'; // 'prompts' or 'chat_settings'

  // 간단한 패스워드 (실제로는 환경변수나 더 안전한 방법 사용 권장)
  final String _adminPassword = 'bookagent2024admin!';

  final Map<String, String> _promptTypes = {
    'ai_chat': 'AI 채팅 프롬프트',
    'character_chat': '캐릭터 채팅 프롬프트',
    'review_generation': '감동문 생성 프롬프트',
    'ai_welcome': 'AI 첫 인사말',
    'character_welcome': '캐릭터 첫 인사말',
  };

  final Map<String, String> _configTypes = {
    'prompts': '🤖 프롬프트 설정',
    'chat_settings': '💬 대화 설정',
  };

  @override
  void initState() {
    super.initState();
    _loadSavedPrompts();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _aiPromptController.dispose();
    _characterPromptController.dispose();
    _reviewPromptController.dispose();
    _aiWelcomeController.dispose();
    _characterWelcomeController.dispose();
    _minChatCountController.dispose();
    _maxChatCountController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPrompts() async {
    try {
      final chatSettings = await AdminConfigService.getChatSettings();
      
      setState(() {
        _aiPromptController.text = chatSettings['ai_chat_prompt'] ?? 
          '''당신은 독서를 사랑하는 친근한 AI 어시스턴트입니다. 
사용자가 선택한 책에 대해 깊이 있는 대화를 나누며, 감동문 작성을 도와주세요.

다음과 같은 방식으로 대화하세요:
1. 책의 주요 내용과 테마에 대해 질문하기
2. 사용자의 개인적인 감상과 경험 유도하기  
3. 책에서 인상 깊었던 구절이나 장면 물어보기
4. 책이 사용자에게 준 깨달음이나 변화 탐색하기
5. 감정적인 공감과 격려 제공하기

대화는 자연스럽고 따뜻하게, 사용자가 자신의 생각을 깊이 탐구할 수 있도록 도와주세요.''';

        _characterPromptController.text = chatSettings['character_chat_prompt'] ?? 
          '''당신은 {character_name}입니다. 
책 "{book_title}"의 등장인물로서 독자와 대화합니다.

다음 특징을 유지하세요:
- {character_name}의 성격과 말투 반영
- 책 속 상황과 경험을 바탕으로 대화
- 독자에게 책의 교훈과 의미 전달
- 캐릭터다운 따뜻하고 지혜로운 조언

{character_name}가 되어 독자와 의미 있는 대화를 나누세요.''';

        _reviewPromptController.text = chatSettings['review_generation_prompt'] ?? 
          '''사용자와의 대화 내용을 바탕으로 감동적이고 개인적인 감동문을 작성해주세요.

다음 요소를 포함하세요:
1. 책에 대한 첫인상과 기대
2. 읽는 과정에서의 감정 변화
3. 가장 인상 깊었던 장면이나 구절
4. 책이 준 깨달음과 교훈
5. 개인적인 경험과의 연결점
6. 다른 독자들에게 전하고 싶은 메시지

감동문은 진솔하고 따뜻하며, 독자의 개성이 드러나도록 작성해주세요.
길이는 200-500자 정도로 적당하게 작성해주세요.''';

        // 인사말 설정 로드
        _aiWelcomeController.text = chatSettings['ai_welcome_message'] ?? 
          '''안녕하세요! 📚 저는 당신의 독서 여정을 함께할 AI 친구입니다.

선택하신 책에 대해 깊이 있는 대화를 나누며, 여러분만의 특별한 감동문을 만들어보아요!

책을 읽으면서 어떤 느낌이 드셨나요? 궁금한 점이나 인상 깊었던 부분이 있다면 언제든 말씀해 주세요. 😊''';

        _characterWelcomeController.text = chatSettings['character_welcome_message_template'] ?? 
          '''안녕하세요! 저는 "{book_title}"에서 온 {character_name}입니다. ✨

이 책을 읽어주셔서 정말 감사해요. 저와 함께 이야기 속 세계를 더 깊이 탐험해보지 않을래요?

책을 읽으면서 궁금했던 점이나 제게 하고 싶은 말이 있다면 편하게 말씀해 주세요! 🌟''';

        // 대화 설정 로드
        _minChatCountController.text = chatSettings['min_chat_count'].toString();
        _maxChatCountController.text = chatSettings['max_chat_count'].toString();
      });
    } catch (e) {
      print('프롬프트 로드 실패: $e');
    }
  }

  Future<void> _savePrompts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 대화 설정 유효성 검사
      final minCount = int.tryParse(_minChatCountController.text) ?? 10;
      final maxCount = int.tryParse(_maxChatCountController.text) ?? 15;
      
      if (minCount > maxCount) {
        throw Exception('최소 대화 횟수는 최대 대화 횟수보다 작아야 합니다.');
      }

      // Supabase에 설정 저장
      final configs = <String, String>{
        'ai_chat_prompt': _aiPromptController.text,
        'character_chat_prompt': _characterPromptController.text,
        'review_generation_prompt': _reviewPromptController.text,
        'ai_welcome_message': _aiWelcomeController.text,
        'character_welcome_message_template': _characterWelcomeController.text,
        'min_chat_count': minCount.toString(),
        'max_chat_count': maxCount.toString(),
      };

      final success = await AdminConfigService.saveConfigs(configs);
      
      if (!success) {
        throw Exception('데이터베이스 저장에 실패했습니다.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('설정이 성공적으로 저장되었습니다! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _authenticate() {
    if (_passwordController.text == _adminPassword) {
      setState(() {
        _isAuthenticated = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('잘못된 패스워드입니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  TextEditingController _getCurrentController() {
    switch (_selectedPromptType) {
      case 'ai_chat':
        return _aiPromptController;
      case 'character_chat':
        return _characterPromptController;
      case 'review_generation':
        return _reviewPromptController;
      case 'ai_welcome':
        return _aiWelcomeController;
      case 'character_welcome':
        return _characterWelcomeController;
      default:
        return _aiPromptController;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return _buildAuthScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '🔧 프롬프트 관리',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              setState(() {
                _isAuthenticated = false;
                _passwordController.clear();
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 경고 메시지
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '주의: 이 페이지는 관리자 전용입니다. 프롬프트 변경은 앱 전체에 영향을 줍니다.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 설정 타입 선택 (프롬프트 vs 대화 설정)
            const Text(
              '설정 타입',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedConfigType,
                isExpanded: true,
                underline: const SizedBox(),
                items: _configTypes.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedConfigType = value;
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // 프롬프트 타입 선택 (프롬프트 설정일 때만 표시)
            if (_selectedConfigType == 'prompts') ...[
              const Text(
                '프롬프트 타입',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
            
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: _selectedPromptType,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _promptTypes.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPromptType = value;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 프롬프트 편집 영역
              const Text(
                '프롬프트 내용',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surface,
                  ),
                  child: TextField(
                    controller: _getCurrentController(),
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '프롬프트를 입력하세요...',
                    ),
                  ),
                ),
              ),
            ],

            // 대화 설정 영역 (대화 설정일 때만 표시)
            if (_selectedConfigType == 'chat_settings') ...[
              const Text(
                '대화 횟수 설정',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '최소 대화 횟수',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _minChatCountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: '10',
                            suffixText: '회',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '최대 대화 횟수',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _maxChatCountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: '15',
                            suffixText: '회',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '대화 횟수 설정 안내',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 최소 대화 횟수: 감동문 생성을 위해 필요한 최소 대화 수\n• 최대 대화 횟수: 대화할 수 있는 최대 횟수\n• 최소 횟수는 최대 횟수보다 작아야 합니다',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
            ],

            const SizedBox(height: 24),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePrompts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
                        '프롬프트 저장',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              
              const Text(
                '관리자 인증',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              
              const Text(
                '프롬프트 관리를 위해 패스워드를 입력하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '패스워드',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                onSubmitted: (_) => _authenticate(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '인증',
                    style: TextStyle(
                      fontSize: 16,
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
}
