import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show jsonEncode, jsonDecode;
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/character_themes.dart';
import '../models/character.dart';

class CharacterChatPage extends StatefulWidget {
  final Character character;

  const CharacterChatPage({
    super.key,
    required this.character,
  });

  @override
  State<CharacterChatPage> createState() => _CharacterChatPageState();
}

class _CharacterChatPageState extends State<CharacterChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  
  late CharacterTheme _characterTheme;

  @override
  void initState() {
    super.initState();
    _characterTheme = CharacterThemes.getTheme(widget.character.name);
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text: _getCharacterWelcomeMessage(),
        isUser: false,
        timestamp: DateTime.now(),
        characterName: widget.character.name,
      ),
    );
  }

  String _getCharacterWelcomeMessage() {
    switch (widget.character.name) {
      case '해리 포터':
        return '안녕하세요! 저는 해리 포터예요. 호그와트에서의 모험에 대해 이야기해보고 싶으신가요? 🪄';
      case '셜록 홈즈':
        return '좋은 아침입니다. 셜록 홈즈입니다. 혹시 해결하고 싶은 미스터리가 있으신가요? 🔍';
      case '엘리자베스 베넷':
        return '안녕하세요! 엘리자베스 베넷입니다. 오늘은 어떤 이야기를 나누고 싶으신가요? 💭';
      case '아라곤':
        return '안녕하십니까. 아라곤입니다. 중간계의 모험담을 들려드릴까요? ⚔️';
      case '김춘삼':
        return '안녕하세요! 김춘삼이라고 합니다. 새로운 세상에 대한 이야기를 나눠보시죠! 🌟';
      default:
        return '안녕하세요! ${widget.character.name}입니다. 반가워요! 😊';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: AppSpacing.iconXl,
              height: AppSpacing.iconXl,
              decoration: BoxDecoration(
                gradient: _characterTheme.gradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: _characterTheme.primaryColor.withOpacity(0.3),
                    blurRadius: AppSpacing.elevationMedium,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _characterTheme.emoji,
                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.character.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.character.bookTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 1,
        shadowColor: AppColors.dividerColor,
        actions: [
          IconButton(
            onPressed: _showCharacterInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: '캐릭터 정보',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearChat();
                  break;
                case 'save':
                  _saveFavoriteQuote();
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
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.favorite_border, size: 20),
                    SizedBox(width: 8),
                    Text('명대사 저장'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 캐릭터 소개 카드
          Container(
            margin: EdgeInsets.all(AppSpacing.md),
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _characterTheme.backgroundColor,
                  _characterTheme.backgroundColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: _characterTheme.primaryColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _characterTheme.primaryColor.withOpacity(0.1),
                  blurRadius: AppSpacing.elevationMedium,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: _characterTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.auto_stories,
                    color: _characterTheme.primaryColor,
                    size: AppSpacing.iconSm,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${widget.character.name}${_characterTheme.emoji}와의 특별한 대화를 즐겨보세요!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _characterTheme.primaryColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
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
              width: AppSpacing.iconLg,
              height: AppSpacing.iconLg,
              decoration: BoxDecoration(
                gradient: _characterTheme.gradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: _characterTheme.primaryColor.withOpacity(0.2),
                    blurRadius: AppSpacing.elevationLow,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _characterTheme.emoji,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? _characterTheme.primaryColor
                    : _characterTheme.messageColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl).copyWith(
                  bottomLeft: message.isUser
                      ? Radius.circular(AppSpacing.radiusXl)
                      : Radius.circular(AppSpacing.radiusXs),
                  bottomRight: message.isUser
                      ? Radius.circular(AppSpacing.radiusXs)
                      : Radius.circular(AppSpacing.radiusXl),
                ),
                border: message.isUser
                    ? null
                    : Border.all(
                        color: _characterTheme.primaryColor.withOpacity(0.15),
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: (message.isUser 
                        ? _characterTheme.primaryColor 
                        : _characterTheme.primaryColor).withOpacity(0.1),
                    blurRadius: AppSpacing.elevationLow,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
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
            width: AppSpacing.iconLg,
            height: AppSpacing.iconLg,
            decoration: BoxDecoration(
              gradient: _characterTheme.gradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: _characterTheme.primaryColor.withOpacity(0.2),
                  blurRadius: AppSpacing.elevationLow,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _characterTheme.emoji,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
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
                color: _characterTheme.primaryColor.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.character.name}이 입력 중...',
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
                      _characterTheme.primaryColor.withOpacity(0.7),
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
                hintText: '${widget.character.name}에게 메시지를 보내세요...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                  borderSide: BorderSide(color: _characterTheme.primaryColor, width: 2),
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
                gradient: _characterTheme.gradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                boxShadow: [
                  BoxShadow(
                    color: _characterTheme.primaryColor.withOpacity(0.3),
                    blurRadius: AppSpacing.elevationMedium,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
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
    _simulateCharacterResponse(text);
  }

  void _simulateCharacterResponse(String userMessage) async {
    try {
      print('🎭 Character API 호출 시작: ${widget.character.name} - $userMessage');
      // 실제 Character API 호출
      String characterResponse = await _callRealCharacterApi(userMessage);
      print('🎭 Character API 성공: ${characterResponse.substring(0, 50)}...');
      
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: characterResponse,
            isUser: false,
            timestamp: DateTime.now(),
            characterName: widget.character.name,
          ),
        );
      });
    } catch (e) {
      print('❌ Character API 실패: $e');
      // API 실패 시 fallback
      String characterResponse = _generateCharacterResponse(userMessage);
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: characterResponse,
            isUser: false,
            timestamp: DateTime.now(),
            characterName: widget.character.name,
          ),
        );
      });
    }

    _scrollToBottom();
  }

  Future<String> _callRealCharacterApi(String userMessage) async {
    try {
      final baseUrl = 'https://bookagent-production.up.railway.app';
      print('🔍 Character Base URL: $baseUrl');
      
      // 이전 메시지들을 컨텍스트로 포함
      final recentMessages = _messages.length > 6 
          ? _messages.sublist(_messages.length - 6) 
          : _messages;
      final context = recentMessages
          .map((msg) => '${msg.isUser ? '사용자' : widget.character.name}: ${msg.text}')
          .join('\n');

      final requestBody = {
        'message': userMessage,
        'characterName': widget.character.name,
        'context': context,
      };

      print('🎭 Character API 요청: ${jsonEncode(requestBody)}');

      // Character-specific prompt를 메시지에 포함해서 일반 chat API 사용
      final characterPrompt = _getCharacterPrompt(widget.character.name);
      final enhancedMessage = '$characterPrompt\n\n사용자 질문: $userMessage';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'message': enhancedMessage,
        }),
      ).timeout(const Duration(seconds: 15));

      print('🎭 Character API 응답 코드: ${response.statusCode}');
      print('🎭 Character API 응답 본문: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        
        // JSON 응답인지 확인
        try {
          if (responseBody.startsWith('{') && responseBody.endsWith('}')) {
            // JSON 형태로 응답이 온 경우
            final jsonData = jsonDecode(responseBody);
            final characterResponse = jsonData['reply'] ?? jsonData['response'] ?? responseBody;
            
            if (characterResponse.isNotEmpty) {
              return characterResponse.toString();
            } else {
              print('❌ Character API JSON 파싱 후 빈 응답');
              throw Exception('Empty response after JSON parsing');
            }
          } else {
            // 일반 텍스트 응답인 경우
            if (responseBody.isNotEmpty) {
              return responseBody;
            } else {
              print('❌ Character API 빈 응답');
              throw Exception('Empty response from Character API');
            }
          }
        } catch (jsonError) {
          print('❌ JSON 파싱 실패, 원본 텍스트 반환: $jsonError');
          // JSON 파싱에 실패하면 원본 텍스트를 반환
          return responseBody.isNotEmpty ? responseBody : '응답을 처리할 수 없습니다.';
        }
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Character API 예외: $e');
      throw Exception('Failed to call Character API: $e');
    }
  }

  String _getCharacterPrompt(String characterName) {
    switch (characterName) {
      case '해리 포터':
        return '당신은 해리 포터입니다. 마법 세계에 대한 지식이 풍부하고 용감하며 친구들을 소중히 여깁니다. 호그와트와 마법에 대한 질문에 답하고, 어둠의 마법에 대한 경계를 늦추지 마세요. 해리 포터의 말투와 성격으로 대답해주세요.';
      case '셜록 홈즈':
        return '당신은 셜록 홈즈입니다. 뛰어난 관찰력과 추리력을 가진 탐정입니다. 논리적이고 분석적인 태도로 질문에 답하며, 사건 해결에 대한 힌트를 줄 수 있습니다. 감정보다는 사실에 집중하고 셜록 홈즈의 말투로 대답해주세요.';
      case '엘리자베스 베넷':
        return '당신은 오만과 편견의 엘리자베스 베넷입니다. 재치 있고 독립적이며 편견에 맞서는 여성입니다. 사회적 관습이나 결혼에 대한 질문에 당신의 견해를 밝히고, 엘리자베스 베넷의 우아하고 재치있는 말투로 대답해주세요.';
      case '아라곤':
        return '당신은 반지의 제왕의 아라곤입니다. 곤도르의 왕위 계승자이자 뛰어난 전사입니다. 용감하고 현명하며 백성을 사랑합니다. 중간계의 역사, 전투, 그리고 운명에 대한 질문에 답하고, 아라곤의 고결하고 현명한 말투로 대답해주세요.';
      case '김춘삼':
        return '당신은 소설 "난장이가 쏘아올린 작은 공"의 김춘삼입니다. 가난하고 소외된 이들의 삶과 애환을 대변하는 인물입니다. 사회의 부조리함과 인간적인 고뇌에 대해 이야기할 수 있습니다. 김춘삼의 현실적이고 고뇌에 찬 말투로 대답해주세요.';
      default:
        return '당신은 친절하고 지식이 풍부한 AI 어시스턴트입니다. 어떤 질문이든 성심성의껏 답변해 드리겠습니다.';
    }
  }

  String _generateCharacterResponse(String userMessage) {
    switch (widget.character.name) {
      case '해리 포터':
        return _getHarryPotterResponse(userMessage);
      case '셜록 홈즈':
        return _getSherlockResponse(userMessage);
      case '엘리자베스 베넷':
        return _getElizabethResponse(userMessage);
      case '아라곤':
        return _getAragornResponse(userMessage);
      case '김춘삼':
        return _getKimChunsanResponse(userMessage);
      default:
        return '흥미로운 말씀이네요! 더 자세히 이야기해주시겠어요?';
    }
  }

  String _getHarryPotterResponse(String message) {
    if (message.contains('마법') || message.contains('호그와트')) {
      return '호그와트는 정말 마법 같은 곳이에요! 처음 그곳에 도착했을 때의 경이로움을 아직도 잊을 수 없어요. 어떤 마법에 대해 궁금하신가요? 🪄';
    } else if (message.contains('친구') || message.contains('론') || message.contains('헤르미온느')) {
      return '론과 헤르미온느는 제 인생에서 가장 소중한 친구들이에요. 진정한 친구가 있다는 것이 얼마나 큰 힘이 되는지 모르실 거예요!';
    } else {
      return '그렇군요! 저도 처음엔 마법 세계에 대해 아무것도 몰랐어요. 궁금한 게 있으시면 언제든 물어보세요!';
    }
  }

  String _getSherlockResponse(String message) {
    if (message.contains('추리') || message.contains('사건')) {
      return '흥미로운 관찰이군요. 모든 세부사항이 중요합니다. 가장 작은 단서라도 놓치지 않는 것이 추리의 핵심이죠. 🔍';
    } else if (message.contains('왓슨') || message.contains('친구')) {
      return '왓슨은 훌륭한 동반자입니다. 그의 의학적 지식과 충성심은 많은 사건 해결에 큰 도움이 되었죠.';
    } else {
      return '논리적으로 생각해봅시다. 당신이 말씀하신 내용에서 몇 가지 흥미로운 점을 발견할 수 있네요.';
    }
  }

  String _getElizabethResponse(String message) {
    if (message.contains('사랑') || message.contains('결혼')) {
      return '진정한 사랑은 단순한 감정 이상의 것이라고 생각해요. 서로를 존중하고 이해하는 것이 중요하죠. 💕';
    } else if (message.contains('다아시') || message.contains('오만')) {
      return '처음에는 다아시 씨를 오만하다고 생각했지만, 사람을 겉모습만으로 판단해서는 안 된다는 것을 배웠어요.';
    } else {
      return '흥미로운 견해네요! 저는 항상 독립적인 사고를 중요하게 생각해요. 당신의 의견을 더 들어보고 싶어요.';
    }
  }

  String _getAragornResponse(String message) {
    if (message.contains('왕') || message.contains('곤도르')) {
      return '왕이 되는 것은 큰 책임을 의미합니다. 백성들을 지키고 평화를 유지하는 것이 제 사명이죠. ⚔️';
    } else if (message.contains('반지') || message.contains('모험')) {
      return '반지 원정대와 함께한 여정은 험난했지만, 중간계의 평화를 위해서는 반드시 필요한 일이었습니다.';
    } else {
      return '용기와 명예는 진정한 전사의 덕목입니다. 어떤 시련이 와도 포기하지 않는 마음이 중요해요.';
    }
  }

  String _getKimChunsanResponse(String message) {
    if (message.contains('모험') || message.contains('새로운')) {
      return '새로운 세상은 정말 흥미진진해요! 매일매일이 새로운 발견의 연속이죠. 🌟';
    } else if (message.contains('꿈') || message.contains('희망')) {
      return '꿈을 가지는 것은 참 중요한 일이에요. 꿈이 있어야 앞으로 나아갈 힘이 생기거든요!';
    } else {
      return '그래요? 정말 재미있는 이야기네요! 저도 그런 경험을 해보고 싶어요.';
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

  void _saveFavoriteQuote() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('명대사 저장 기능을 준비 중입니다.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showCharacterInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:           Row(
          children: [
            Container(
              width: AppSpacing.iconXl,
              height: AppSpacing.iconXl,
              decoration: BoxDecoration(
                gradient: _characterTheme.gradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: _characterTheme.primaryColor.withOpacity(0.3),
                    blurRadius: AppSpacing.elevationMedium,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _characterTheme.emoji,
                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(widget.character.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              label: '작품',
              value: widget.character.bookTitle,
            ),
            _InfoRow(
              label: '저자',
              value: widget.character.author,
            ),
            _InfoRow(
              label: '장르',
              value: widget.character.genre,
            ),
            const SizedBox(height: 8),
            Text(
              '성격',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              widget.character.personality,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '설명',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              widget.character.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
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
  final String? characterName;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.characterName,
  });
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}


