import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../review/presentation/review_creation_page.dart';

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
  int _remainingTurns = 10;

  @override
  void initState() {
    super.initState();
    _addInitialMessage();
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
        text: '안녕하세요! 저는 독서 도우미 AI입니다 📚\n\n'
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

  // 진행률 바
  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 텍스트와 버튼
          Row(
            children: [
              Text(
                '감상을 나누다보면 감동도',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '들어져요',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_remainingTurns}번 남음',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 진행률 바
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (10 - _remainingTurns) / 10,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 사용자 정보
  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: Colors.grey[600],
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '치웃',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // 메시지 입력창
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: '치웃과 감상을 나누어보세요.',
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
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 메시지 버블
  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser ? AppColors.primary : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  color: message.isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 타이핑 인디케이터
  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '생각 중...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    _simulateAiResponse(text);
  }

  void _simulateAiResponse(String userMessage) async {
    try {
      print('🤖 AI API 호출 시작: $userMessage');
      // 실제 AI API 호출
      String aiResponse = await _callRealAiApi(userMessage);
      print('🤖 AI API 성공: ${aiResponse.substring(0, 50)}...');
      
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
      // API 실패 시 fallback
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: '죄송합니다. AI 서비스에 일시적인 문제가 있습니다. ${_generateAiResponse(userMessage)}',
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
      // 임시로 하드코딩
      final baseUrl = 'https://bookagent-production.up.railway.app';
      print('🔍 Base URL: $baseUrl');
      
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
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'AI 응답을 받을 수 없습니다.';
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ AI API 호출 실패: $e');
      rethrow;
    }
  }

  String _generateAiResponse(String userMessage) {
    // AI 서비스 실패 시 사용할 간단한 응답들
    final responses = [
      '그 부분에 대해 더 자세히 말해보실 수 있나요? 어떤 감정이 들었는지 궁금해요.',
      '정말 흥미로운 관점이네요! 그 장면에서 어떤 생각이 들었나요?',
      '책을 읽으면서 가장 인상 깊었던 부분은 무엇이었나요?',
      '작가의 메시지에 대해 어떻게 생각하시나요?',
      '이 책이 당신에게 어떤 의미로 다가왔는지 궁금해요.',
    ];
    
    final random = DateTime.now().millisecondsSinceEpoch % responses.length;
    return responses[random];
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

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}