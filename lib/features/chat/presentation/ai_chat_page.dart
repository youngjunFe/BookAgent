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

  String _displayTextFor(ChatMessage message) {
    if (message.isUser) return message.text;
    final t = message.text.trim();
    // If the assistant text still contains a JSON-like object with reply, extract it
    final re = RegExp(r'"reply"\s*:\s*"([\s\S]*?)"');
    final m = re.firstMatch(t);
    if (m != null) {
      return m
          .group(1)!
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\r', '\r')
          .replaceAll(r'\t', '\t')
          .replaceAll(r'\"', '"');
    }
    // Strip surrounding braces if it's a one-line object-like string
    if (t.startsWith('{') && t.endsWith('}') && t.length < 400) {
      return t.substring(1, t.length - 1);
    }
    return message.text;
  }

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    
    // 초기 컨텍스트가 있으면 AI가 먼저 발제문에 대해 언급
    if (widget.initialContext != null) {
      _addInitialContextMessage();
    }
  }

  void _addWelcomeMessage() {
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

  void _addInitialContextMessage() {
    _messages.add(
      ChatMessage(
        text: '방금 작성하신 "${widget.bookTitle ?? '책'}"에 대한 발제문을 읽어보았습니다! 📝\n\n'
            '발제문의 내용을 바탕으로 더 깊이 있는 대화를 나눠보시겠어요?\n\n'
            '궁금한 점이나 토론하고 싶은 부분이 있으시면 말씀해 주세요!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 독서 도우미',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '온라인',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 1,
        shadowColor: AppColors.dividerColor,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearChat();
                  break;
                case 'export':
                  _exportChat();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('대화 초기화'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text('대화 내보내기'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 안내 메시지
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI와 대화한 내용을 바탕으로 발제문을 자동 생성할 수 있어요!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 채팅 메시지 리스트
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // 메시지 입력 영역
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                border: message.isUser
                    ? null
                    : Border.all(
                        color: AppColors.dividerColor,
                        width: 1,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayTextFor(message),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: message.isUser
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: message.isUser
                          ? AppColors.onPrimary.withOpacity(0.7)
                          : AppColors.textHint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.secondary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

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
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
              border: Border.all(
                color: AppColors.dividerColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.aiThinking,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: AppStrings.typeMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.send,
                color: AppColors.onPrimary,
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
      );
      
      if (response.statusCode == 200) {
        final body = response.body.trim();
        print('🔍 원본 응답: $body');
        
        // 1단계: 직접 JSON 파싱 시도
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map) {
            // 가능한 응답 키들 체크
            final keys = ['reply', 'message', 'content', 'text', 'response', 'answer'];
            for (final key in keys) {
              if (decoded[key] is String) {
                final result = (decoded[key] as String).trim();
                if (result.isNotEmpty && !result.startsWith('{')) {
                  print('✅ JSON 키 "$key"에서 추출: ${result.substring(0, result.length > 50 ? 50 : result.length)}...');
                  return result;
                }
              }
            }
          }
        } catch (e) {
          print('⚠️ JSON 직접 파싱 실패: $e');
        }
        
        // 2단계: 중첩 JSON 문자열 처리
        if (body.startsWith('"') && body.endsWith('"')) {
          try {
            // 문자열로 인코딩된 JSON 디코딩
            final unescaped = jsonDecode(body) as String;
            print('🔍 문자열 디코딩: $unescaped');
            final decoded = jsonDecode(unescaped);
            if (decoded is Map) {
              final keys = ['reply', 'message', 'content', 'text', 'response', 'answer'];
              for (final key in keys) {
                if (decoded[key] is String) {
                  final result = (decoded[key] as String).trim();
                  if (result.isNotEmpty && !result.startsWith('{')) {
                    print('✅ 중첩 JSON에서 추출: ${result.substring(0, result.length > 50 ? 50 : result.length)}...');
                    return result;
                  }
                }
              }
            }
          } catch (e) {
            print('⚠️ 중첩 JSON 파싱 실패: $e');
          }
        }
        
        // 3단계: 정규식으로 JSON 필드 추출
        final patterns = [
          RegExp(r'"reply"\s*:\s*"([^"]*(?:\\.[^"]*)*)"'),
          RegExp(r'"message"\s*:\s*"([^"]*(?:\\.[^"]*)*)"'),
          RegExp(r'"content"\s*:\s*"([^"]*(?:\\.[^"]*)*)"'),
          RegExp(r'"text"\s*:\s*"([^"]*(?:\\.[^"]*)*)"'),
          RegExp(r'"response"\s*:\s*"([^"]*(?:\\.[^"]*)*)"'),
          RegExp(r'"answer"\s*:\s*"([^"]*(?:\\.[^"]*)*)"'),
        ];
        
        for (final pattern in patterns) {
          final match = pattern.firstMatch(body);
          if (match != null && match.group(1) != null) {
            final raw = match.group(1)!;
            final cleaned = raw
                .replaceAll(r'\"', '"')
                .replaceAll(r'\\n', '\n')
                .replaceAll(r'\\r', '\r')
                .replaceAll(r'\\t', '\t')
                .replaceAll(r'\\\\', '\\');
            if (cleaned.trim().isNotEmpty && !cleaned.trim().startsWith('{')) {
              print('✅ 정규식으로 추출: ${cleaned.substring(0, cleaned.length > 50 ? 50 : cleaned.length)}...');
              return cleaned.trim();
            }
          }
        }
        
        // 4단계: 원본이 순수 텍스트인지 확인
        if (!body.startsWith('{') && !body.startsWith('[') && body.length > 0) {
          print('✅ 순수 텍스트로 반환: ${body.substring(0, body.length > 50 ? 50 : body.length)}...');
          return body;
        }
        
        // 5단계: 마지막 대안 - 원본 반환
        print('⚠️ 모든 파싱 실패, 원본 반환');
        return body.isNotEmpty ? body : '응답을 받을 수 없습니다.';
        
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ AI API 호출 실패: $e');
      throw Exception('Failed to call AI API: $e');
    }
  }

  String _generateAiResponse(String userMessage) {
    // 간단한 AI 응답 시뮬레이션
    if (userMessage.contains('안녕') || userMessage.contains('하이')) {
      return '안녕하세요! 어떤 책에 대해 이야기해보고 싶으신가요? 📚';
    } else if (userMessage.contains('책') || userMessage.contains('소설')) {
      return '흥미로운 선택이네요! 그 책에서 가장 인상 깊었던 부분은 무엇인가요? '
             '또한 주인공의 행동이나 선택에 대해 어떻게 생각하시는지 궁금합니다.';
    } else if (userMessage.contains('감정') || userMessage.contains('느낌')) {
      return '책을 읽으며 느끼신 감정이 정말 소중해요. 그런 감정이 생긴 구체적인 장면이나 '
             '문장이 있다면 공유해주세요. 함께 더 깊이 이야기해볼 수 있을 것 같아요!';
    } else {
      return '정말 좋은 관점이네요! 더 자세히 말씀해주시면, 그 부분에 대해 다양한 각도로 '
             '분석해볼 수 있을 것 같아요. 혹시 다른 등장인물들의 입장에서는 어떻게 보일까요?';
    }
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
      _addWelcomeMessage();
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('발제문으로 저장'),
        content: const Text('현재 대화 내용을 바탕으로 발제문을 생성하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generateReview();
            },
            child: const Text('생성하기'),
          ),
        ],
      ),
    );
  }

  void _generateReview() {
    // 대화 기록을 문자열로 변환
    final chatHistory = _messages
        .map((msg) => '${msg.isUser ? '사용자' : 'AI'}: ${msg.text}')
        .join('\n\n');

    // 책 제목/저자는 검색(선택) 값에 절대 우선권 부여
    String? selectedTitle = widget.bookTitle;
    String? selectedAuthor = widget.bookAuthor;

    // 금지 값 필터링
    bool _isBanned(String? v) {
      if (v == null) return true;
      final t = v.trim();
      return t.isEmpty || t == '안녕하세요' || t == '책';
    }

    if (_isBanned(selectedTitle)) {
      selectedTitle = null; // 의미 없는 기본값은 전달하지 않음
    }
    if (_isBanned(selectedAuthor)) {
      selectedAuthor = null;
    }

    // 로깅: 어떤 값이 전달되는지 추적
    print('📚 [AiChatPage] Navigate to ReviewCreationPage with: '
        'title="${selectedTitle ?? '(none)'}", author="${selectedAuthor ?? '(none)'}"');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewCreationPage(
          chatHistory: chatHistory,
          bookTitle: selectedTitle,
          bookAuthor: selectedAuthor,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
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
