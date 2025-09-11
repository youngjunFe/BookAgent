import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  
  // 책 추가 관련 컨트롤러
  final TextEditingController _bookTitleController = TextEditingController();
  final TextEditingController _bookAuthorController = TextEditingController();
  final TextEditingController _bookDescriptionController = TextEditingController();
  final TextEditingController _bookContentController = TextEditingController();
  
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
    'book_management': '📚 책 관리',
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
    _bookTitleController.dispose();
    _bookAuthorController.dispose();
    _bookDescriptionController.dispose();
    _bookContentController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPrompts() async {
    try {
      final chatSettings = await AdminConfigService.getChatSettings();
      
      setState(() {
        // DB에서 실제 값 로드 (빈 값이 아닌 경우에만)
        if (chatSettings['ai_chat_prompt']?.isNotEmpty == true) {
          _aiPromptController.text = chatSettings['ai_chat_prompt']!;
        }
        
        if (chatSettings['character_chat_prompt']?.isNotEmpty == true) {
          _characterPromptController.text = chatSettings['character_chat_prompt']!;
        }
        
        if (chatSettings['review_generation_prompt']?.isNotEmpty == true) {
          _reviewPromptController.text = chatSettings['review_generation_prompt']!;
        }
        
        if (chatSettings['ai_welcome_message']?.isNotEmpty == true) {
          _aiWelcomeController.text = chatSettings['ai_welcome_message']!;
        }
        
        if (chatSettings['character_welcome_message_template']?.isNotEmpty == true) {
          _characterWelcomeController.text = chatSettings['character_welcome_message_template']!;
        }

        // 대화 설정 로드
        _minChatCountController.text = chatSettings['min_chat_count'].toString();
        _maxChatCountController.text = chatSettings['max_chat_count'].toString();
      });
      
      print('✅ DB에서 설정 로드 완료');
      print('AI 프롬프트 길이: ${_aiPromptController.text.length}');
      print('최소 대화수: ${_minChatCountController.text} (DB값: ${chatSettings['min_chat_count']})');
      print('최대 대화수: ${_maxChatCountController.text} (DB값: ${chatSettings['max_chat_count']})');
      print('AI 인사말 길이: ${_aiWelcomeController.text.length}');
      
    } catch (e) {
      print('❌ 프롬프트 로드 실패: $e');
      
      // 에러 발생시 사용자에게 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정 로드 실패: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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

            // 책 관리 영역 (책 관리일 때만 표시)
            if (_selectedConfigType == 'book_management') ...[
              const Text(
                '새 책 추가',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              // 책 제목
              TextField(
                controller: _bookTitleController,
                decoration: InputDecoration(
                  labelText: '책 제목',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.book),
                ),
              ),
              const SizedBox(height: 12),
              
              // 저자
              TextField(
                controller: _bookAuthorController,
                decoration: InputDecoration(
                  labelText: '저자',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              
              // 책 설명
              TextField(
                controller: _bookDescriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '책 설명',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 12),
              
              // 책 내용 (간단한 샘플)
              TextField(
                controller: _bookContentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: '책 내용 (샘플 텍스트)',
                  hintText: '첫 번째 페이지나 프롤로그 내용을 입력하세요...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.article),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 책 추가 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addBook,
                  icon: const Icon(Icons.add),
                  label: const Text('책 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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

  Future<void> _addBook() async {
    if (_bookTitleController.text.trim().isEmpty || 
        _bookAuthorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('책 제목과 저자는 필수입니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 간단한 책 내용 생성 (페이지별로 분할)
      final content = _bookContentController.text.trim().isNotEmpty 
          ? _bookContentController.text.trim()
          : '${_bookTitleController.text}의 내용이 여기에 표시됩니다.\n\n이는 ${_bookAuthorController.text} 작가의 작품으로, 독자들에게 깊은 감동을 선사할 것입니다.';
      
      // 내용을 페이지별로 분할 (약 500자씩)
      final pages = <String>[];
      final words = content.split(' ');
      String currentPage = '';
      
      for (final word in words) {
        if (currentPage.length + word.length > 500 && currentPage.isNotEmpty) {
          pages.add(currentPage.trim());
          currentPage = word + ' ';
        } else {
          currentPage += word + ' ';
        }
      }
      
      if (currentPage.trim().isNotEmpty) {
        pages.add(currentPage.trim());
      }

      // Supabase에 책 추가
      await _supabaseClient.from('ebooks').insert({
        'title': _bookTitleController.text.trim(),
        'author': _bookAuthorController.text.trim(),
        'description': _bookDescriptionController.text.trim().isEmpty 
            ? '${_bookAuthorController.text}의 ${_bookTitleController.text}'
            : _bookDescriptionController.text.trim(),
        'file_type': 'txt',
        'file_size': content.length,
        'total_pages': pages.length,
        'language': 'ko',
        'status': 'active',
        'chapters': pages.map((page) => {
          'title': '페이지 ${pages.indexOf(page) + 1}',
          'content': page,
        }).toList(),
        'metadata': {
          'addedBy': 'admin',
          'isPublic': true,
          'source': 'admin_panel'
        },
        'created_by': null, // 관리자가 추가한 책은 created_by를 null로 설정
      });

      // 입력 필드 초기화
      _bookTitleController.clear();
      _bookAuthorController.clear();
      _bookDescriptionController.clear();
      _bookContentController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('책이 성공적으로 추가되었습니다! 모든 사용자가 볼 수 있습니다.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('책 추가 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('책 추가 실패: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Supabase 클라이언트 getter 추가
  static const _supabaseUrl = 'https://gagbvtfrsvheaubbjijb.supabase.co';
  static const _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdhZ2J2dGZyc3ZoZWF1YmJqaWpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjEwMTI5MDgsImV4cCI6MjAzNjU4ODkwOH0.PNxYOIUEtGGCmJgMGWCRxSjbSMWnJe4sNUE4aBfhvb8';
  
  late final _supabaseClient = SupabaseClient(_supabaseUrl, _supabaseKey);
}
