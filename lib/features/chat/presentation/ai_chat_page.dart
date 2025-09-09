import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../review/presentation/review_creation_page.dart';
import '../../admin/services/admin_config_service.dart';

class AiChatPage extends StatefulWidget {
  final String? initialContext;
  final String? bookTitle;
  final String? bookAuthor;
  final bool isGuestMode;
  final VoidCallback? onChatComplete;
  final Function(String)? onChatCompleteWithHistory;
  
  const AiChatPage({
    super.key,
    this.initialContext,
    this.bookTitle,
    this.bookAuthor,
    this.isGuestMode = false,
    this.onChatComplete,
    this.onChatCompleteWithHistory,
  });

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  int _remainingTurns = 15;
  int _maxChatCount = 15;
  int _minChatCount = 10;
  String _aiWelcomeMessage = '';

  @override
  void initState() {
    super.initState();
    _loadChatSettings();
  }

  Future<void> _loadChatSettings() async {
    try {
      final settings = await AdminConfigService.getChatSettings();
      setState(() {
        _maxChatCount = settings['max_chat_count'] ?? 15;
        _minChatCount = settings['min_chat_count'] ?? 10;
        _remainingTurns = _maxChatCount;
        _aiWelcomeMessage = settings['ai_welcome_message'] ?? '';
      });
      
      print('✅ 채팅 설정 로드: 최소 $_minChatCount, 최대 $_maxChatCount');
      _addInitialMessage();
    } catch (e) {
      print('❌ 채팅 설정 로드 실패: $e');
      _addInitialMessage();
    }
  }

  void _addInitialMessage() async {
    // 책 정보가 있는 경우 AI 한줄평과 함께 메시지 생성
    if (widget.bookTitle != null && widget.bookTitle!.isNotEmpty) {
      await _addBookBasedMessage();
    } else {
      // 책 정보가 없는 경우 기본 환영 메시지
      _addDefaultWelcomeMessage();
    }
  }

  void _addDefaultWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text: _aiWelcomeMessage.isNotEmpty 
            ? _aiWelcomeMessage
            : '안녕하세요! 저는 독서 도우미 AI입니다 📚\n\n'
              '어떤 책에 대해 이야기하고 싶으신가요?\n'
              '책의 제목을 알려주시면, 함께 깊이 있는 대화를 나눠보아요!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _addBookBasedMessage() async {
    // 로딩 메시지 먼저 추가
    setState(() {
      _messages.add(
        ChatMessage(
          text: '안녕하세요! 저는 독서 도우미 AI입니다 📚',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    try {
      // AI에게 책에 대한 한줄평 요청
      final bookSummary = await _generateBookSummary(widget.bookTitle!, widget.bookAuthor);
      
      // 기존 로딩 메시지 제거하고 새 메시지 추가
      setState(() {
        _messages.removeLast();
        _messages.add(
          ChatMessage(
            text: '${widget.bookTitle}을 읽으셨다니..! ( \' - \' ) /\n'
                '$bookSummary 라고 하던데, 지금 무슨 감정을 느끼고 있나요?',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
      });
    } catch (e) {
      print('❌ 책 한줄평 생성 실패: $e');
      // 한줄평 생성 실패 시 기본 메시지
      setState(() {
        _messages.removeLast();
        _messages.add(
          ChatMessage(
            text: '${widget.bookTitle}을 읽으셨다니..! ( \' - \' ) /\n'
                '정말 흥미로운 작품 라고 하던데, 지금 무슨 감정을 느끼고 있나요?',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
      });
    }
  }

  Future<String> _generateBookSummary(String bookTitle, String? bookAuthor) async {
    final prompt = '다음 책에 대한 간단한 한줄평을 작성해주세요. 감정적이고 공감할 수 있는 표현으로 20자 이내로 써주세요.\n\n'
        '책 제목: $bookTitle\n'
        '${bookAuthor != null ? '저자: $bookAuthor\n' : ''}'
        '\n예시: "정말 감동적인 이야기", "마음을 울리는 작품", "생각할 거리가 많은 책"';

    try {
      final response = await _callRealAiApi(prompt);
      // AI 응답에서 따옴표나 불필요한 문구 제거
      String cleanSummary = response
          .replaceAll('"', '')
          .replaceAll("'", '')
          .replaceAll('"', '')
          .replaceAll('"', '')
          .replaceAll('한줄평:', '')
          .replaceAll('요약:', '')
          .trim();
      
      // 길이가 너무 길면 자르기
      if (cleanSummary.length > 30) {
        cleanSummary = cleanSummary.substring(0, 30) + '...';
      }
      
      return cleanSummary.isNotEmpty ? cleanSummary : '인상 깊은 작품';
    } catch (e) {
      print('❌ AI 한줄평 생성 실패: $e');
      return '인상 깊은 작품';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // 커스텀 헤더
            _buildCustomHeader(),
            
            // 진행률 바
            _buildProgressBar(),
            
            // 사용자 정보
            _buildUserInfo(),
            
            // 채팅 영역
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _messages.length) {
                            return _buildMessageBubble(_messages[index]);
                          } else {
                            return _buildTypingIndicator();
                          }
                        },
                      ),
                    ),
                    _buildMessageInput(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 커스텀 헤더
  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              widget.bookTitle ?? 'AI 채팅',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // 좌우 균형을 위한 여백
        ],
      ),
    );
  }

  // 진행률 바 (스크린샷 디자인)
  Widget _buildProgressBar() {
    final completedTurns = _maxChatCount - _remainingTurns;
    final progressPercent = completedTurns / _maxChatCount;
    final canGenerateReview = completedTurns >= _minChatCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // 상단 텍스트와 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '감상이 쌓이고 있어요!',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      '${_remainingTurns}번 남음',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 발제문 생성 가능 시 표시
                  if (canGenerateReview)
                    GestureDetector(
                      onTap: () {
                        // 발제문 생성 페이지로 이동
                        final chatHistory = _messages.map((msg) => 
                          '${msg.isUser ? "사용자" : "AI"}: ${msg.text}'
                        ).join('\n\n');
                        
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => ReviewCreationPage(
                              bookTitle: widget.bookTitle,
                              bookAuthor: widget.bookAuthor,
                              chatHistory: chatHistory,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.description,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 진행률 바
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final milestonePosition = (10 / 15) * barWidth;
              
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    // 진행률 표시
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progressPercent,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // 발제문 생성 가능 지점 마커 (10번째)
                    Positioned(
                      left: milestonePosition - 4,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: canGenerateReview ? AppColors.success : Colors.grey[400],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 사용자 정보
  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: Colors.grey[600],
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '치웃',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // 메시지 입력창 (디자이너 스타일)
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: '치웃과 감상을 나누어보세요',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 14),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 메시지 버블 (디자이너 스타일)
  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 14,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser ? AppColors.primary : Colors.grey[100],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: message.isUser ? Colors.white : AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                // 액션 버튼들 (15번째 대화 완료 시)
                if (!message.isUser && message.showActionButtons) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _showDeletionWarningDialog(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          '싫어요',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _createReviewFromChat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          '지금 만들기',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 타이핑 인디케이터 (디자이너 스타일)
  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.primary,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 단순한 점 3개 애니메이션
                  _buildDotAnimation(0),
                  const SizedBox(width: 4),
                  _buildDotAnimation(1),
                  const SizedBox(width: 4),
                  _buildDotAnimation(2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 점 애니메이션
  Widget _buildDotAnimation(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeInOut,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
      _isTyping = true;
      if (_remainingTurns > 0) _remainingTurns--;
    });

    _scrollToBottom();
    
    // 최소 대화 완료 시 팝업 표시
    if (_remainingTurns == (_maxChatCount - _minChatCount)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMinChatCompletedDialog();
      });
    }
    
    // 최대 대화 완료 시 AI 완료 메시지
    if (_remainingTurns == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addMaxChatCompletionMessage();
      });
      return; // AI 응답 대신 완료 메시지만 표시
    }
    
    _simulateAiResponse(text);
  }

  void _simulateAiResponse(String userMessage) async {
    try {
      print('🤖 AI API 호출 시작: $userMessage');
      // 더 짧은 타임아웃으로 빠른 fallback
      String aiResponse = await _callRealAiApi(userMessage).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('API 타임아웃'),
      );
      print('🤖 AI API 성공: ${aiResponse.length > 50 ? aiResponse.substring(0, 50) + '...' : aiResponse}');
      
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: aiResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      print('❌ AI API 실패: $e');
      // 더 자연스러운 fallback 응답
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: _generateSmartAiResponse(userMessage),
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
    
    _scrollToBottom();
  }

  Future<String> _callRealAiApi(String userMessage) async {
    try {
      final baseUrl = 'https://bookagent-production.up.railway.app';
      print('🔍 Base URL: $baseUrl');
      print('🔍 서버에서 DB 프롬프트를 직접 로드합니다');
      
      // 이전 메시지들을 컨텍스트로 포함
      final recentMessages = _messages.length > 6 
          ? _messages.sublist(_messages.length - 6) 
          : _messages;
      final context = recentMessages
          .map((msg) => '${msg.isUser ? '사용자' : 'AI'}: ${msg.text}')
          .join('\n');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': userMessage,
          'context': context,
          'bookTitle': widget.bookTitle,
          'bookAuthor': widget.bookAuthor,
        }),
      ).timeout(const Duration(seconds: 8));

      print('🔍 API 응답 상태코드: ${response.statusCode}');
      print('🔍 API 응답 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 파싱된 JSON: $data');
        
        // 다양한 응답 형태 시도
        String? aiResponse = data['response'] ?? 
                            data['message'] ?? 
                            data['reply'] ?? 
                            data['answer'] ??
                            data['content'];
        
        print('🔍 추출된 AI 응답: $aiResponse');
        
        if (aiResponse != null && aiResponse.isNotEmpty) {
          return aiResponse;
        } else {
          print('❌ 응답 필드를 찾을 수 없음. 전체 응답을 반환.');
          // JSON 전체가 문자열인 경우
          return response.body.isNotEmpty ? response.body : '응답을 처리할 수 없습니다.';
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ AI API 호출 실패: $e');
      rethrow;
    }
  }

  String _generateSmartAiResponse(String userMessage) {
    // 사용자 메시지 키워드 분석
    final message = userMessage.toLowerCase();
    
    // 감정 관련 키워드
    if (message.contains('슬프') || message.contains('눈물') || message.contains('우울') || message.contains('아프')) {
      final responses = [
        '그런 감정을 느끼셨군요. 책을 읽으면서 마음이 많이 흔들렸을 것 같아요. 어떤 장면에서 특히 그런 감정을 느끼셨나요?',
        '마음이 아프셨겠어요. 책 속 인물들의 감정이 고스란히 전해진 것 같네요. 그 부분을 다시 생각해보면 어떤 기분이 드시나요?',
        '그 슬픔이 어디서 나온 건지 함께 생각해봐요. 혹시 자신의 경험과 겹치는 부분이 있었나요?',
      ];
      return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
    }
    
    // 기쁨, 감동 관련 키워드  
    if (message.contains('감동') || message.contains('기쁘') || message.contains('행복') || message.contains('좋았')) {
      final responses = [
        '정말 좋은 감정을 느끼셨네요! 그 감동이 어떤 부분에서 나왔는지 더 자세히 들어보고 싶어요.',
        '책에서 그런 긍정적인 에너지를 받으셨군요. 어떤 메시지가 특히 마음에 와닿았나요?',
        '그 기쁨을 느낀 순간이 궁금해요. 책의 어떤 부분이 그런 감정을 불러일으켰을까요?',
      ];
      return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
    }
    
    // 생각, 철학 관련 키워드
    if (message.contains('생각') || message.contains('철학') || message.contains('의미') || message.contains('깨달')) {
      final responses = [
        '정말 깊이 있게 생각해보셨네요. 그 깨달음이 일상생활에서 어떤 변화를 가져다줄 것 같나요?',
        '책을 통해 새로운 관점을 얻으신 것 같아요. 그 생각을 더 구체적으로 나눠보실 수 있나요?',
        '철학적인 부분에 관심을 갖고 계시는군요. 작가의 메시지 중에서 가장 공감되는 부분은 무엇인가요?',
      ];
      return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
    }
    
    // 인물, 캐릭터 관련 키워드
    if (message.contains('주인공') || message.contains('인물') || message.contains('캐릭터')) {
      final responses = [
        '그 인물에 대해 어떤 인상을 받으셨나요? 혹시 닮고 싶거나 이해가 안 되는 부분이 있었나요?',
        '인물의 행동이나 선택에 대해 어떻게 생각하시나요? 만약 같은 상황이라면 어떻게 하셨을까요?',
        '그 캐릭터가 겪은 변화 과정이 흥미로우셨을 것 같아요. 어떤 부분에서 가장 공감하셨나요?',
      ];
      return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
    }
    
    // 스토리, 줄거리 관련 키워드
    if (message.contains('스토리') || message.contains('줄거리') || message.contains('사건') || message.contains('전개')) {
      final responses = [
        '그 부분의 전개가 어떠셨나요? 예상했던 대로였나요, 아니면 의외였나요?',
        '스토리의 흐름에 대해 어떤 생각이 드셨는지 궁금해요. 가장 흥미진진했던 순간은 언제였나요?',
        '그 사건이 이야기 전체에서 어떤 의미를 갖는다고 생각하시나요?',
      ];
      return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
    }
    
    // 기본 응답들
    final generalResponses = [
      '그 부분에 대해 더 자세히 말해보실 수 있나요? 어떤 감정이 들었는지 궁금해요.',
      '정말 흥미로운 관점이네요! 그 장면에서 어떤 생각이 들었나요?',
      '책을 읽으면서 가장 인상 깊었던 부분은 무엇이었나요?',
      '작가의 메시지에 대해 어떻게 생각하시나요?',
      '이 책이 당신에게 어떤 의미로 다가왔는지 궁금해요.',
      '그런 느낌을 받으셨군요. 비슷한 경험이나 생각을 해본 적이 있으신가요?',
      '정말 좋은 포인트네요! 그 부분을 조금 더 깊이 파보면 어떨까요?',
    ];
    
    return generalResponses[DateTime.now().millisecondsSinceEpoch % generalResponses.length];
  }

  // 10번째 대화 완료 시 팝업 (첫번째 이미지)
  void _showMinChatCompletedDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '감동문 생성 가능',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '이제 대화 내용을 정리해 감동문을 만들 수 있어요. 바로 만들어 볼까요?',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        '싫어요',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _createReviewFromChat();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '만들기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 15번째 대화 완료 시 AI 메시지 (두번째 이미지)
  void _addMaxChatCompletionMessage() {
    setState(() {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          text: '즐거운 대화였어요. 감상이 쌓아서 이제 감동문을 만들 수 있어요.\n지금 바로 만들어 드릴까요?',
          isUser: false,
          timestamp: DateTime.now(),
          showActionButtons: true, // 특별한 플래그로 버튼 표시
        ),
      );
    });
    _scrollToBottom();
  }

  // 발제문 생성으로 이동
  void _createReviewFromChat() {
    final chatHistory = _messages.map((msg) => 
      '${msg.isUser ? "사용자" : "AI"}: ${msg.text}'
    ).join('\n\n');
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ReviewCreationPage(
          bookTitle: widget.bookTitle,
          bookAuthor: widget.bookAuthor,
          chatHistory: chatHistory,
        ),
      ),
    );
  }

  // 대화 삭제 확인 다이얼로그 (세번째 이미지)
  void _showDeletionWarningDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '대화가 삭제돼요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '지금 감상문을 만들지 않고 대화를 종료하면 감상의 기록이 사라져요.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        '괜찮아요',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _createReviewFromChat();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '지금 감상문 만들기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _addDefaultWelcomeMessage();
    });
  }

  void _exportChat() {
    // TODO: 대화 내용 내보내기 기능
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('대화 내보내기 기능을 준비 중입니다.'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showSaveReviewDialog() {
    final chatHistory = _messages.map((msg) => 
      '${msg.isUser ? "사용자" : "AI"}: ${msg.text}'
    ).join('\n\n');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('발제문으로 저장'),
        content: const Text('지금까지의 대화 내용을 바탕으로 발제문을 작성하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ReviewCreationPage(
                    bookTitle: widget.bookTitle,
                    bookAuthor: widget.bookAuthor,
                    chatHistory: chatHistory,
                  ),
                ),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool showActionButtons;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.showActionButtons = false,
  });
}