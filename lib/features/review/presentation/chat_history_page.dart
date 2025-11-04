import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/review.dart';

class ChatHistoryPage extends StatelessWidget {
  final Review review;

  const ChatHistoryPage({
    super.key,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      '대화내역',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // AppBar leading과 균형 맞추기
                ],
              ),
            ),
            
            // 책 정보 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.bookTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (review.bookAuthor != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      review.bookAuthor!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${review.title}에 대한 대화',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            // 대화내역 리스트
            Expanded(
              child: review.chatHistory != null && review.chatHistory!.isNotEmpty
                  ? _buildChatHistory()
                  : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHistory() {
    // 실제 chatHistory 데이터 파싱
    List<Map<String, String>> chatMessages = [];
    
    if (review.chatHistory != null && review.chatHistory!.isNotEmpty) {
      try {
        final text = review.chatHistory!;
        print('🔍 대화내역 파싱 시작: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');
        
        // 모든 "사용자:" 와 "AI:" 위치를 찾음
        final userPattern = RegExp(r'\n\n사용자: ');
        final aiPattern = RegExp(r'\n\nAI: ');
        
        List<_MessageMarker> markers = [];
        
        // 첫 메시지 체크 (맨 앞에 \n\n 없음)
        if (text.startsWith('사용자: ')) {
          markers.add(_MessageMarker(0, '사용자'));
        } else if (text.startsWith('AI: ')) {
          markers.add(_MessageMarker(0, 'AI'));
        }
        
        // \n\n사용자: 찾기
        for (final match in userPattern.allMatches(text)) {
          markers.add(_MessageMarker(match.start + 2, '사용자')); // \n\n 다음 위치
        }
        
        // \n\nAI: 찾기  
        for (final match in aiPattern.allMatches(text)) {
          markers.add(_MessageMarker(match.start + 2, 'AI')); // \n\n 다음 위치
        }
        
        // 위치순으로 정렬
        markers.sort((a, b) => a.position.compareTo(b.position));
        
        print('🔍 찾은 메시지 마커 개수: ${markers.length}');
        
        // 각 마커 사이의 텍스트를 메시지로 변환
        for (int i = 0; i < markers.length; i++) {
          final marker = markers[i];
          final nextPosition = i < markers.length - 1 
              ? markers[i + 1].position 
              : text.length;
          
          final messageText = text.substring(marker.position, nextPosition).trim();
          
          // "사용자: " 또는 "AI: " 제거
          String content;
          if (messageText.startsWith('사용자: ')) {
            content = messageText.substring(4).trim();
          } else if (messageText.startsWith('AI: ')) {
            content = messageText.substring(4).trim();
          } else {
            content = messageText;
          }
          
          if (content.isNotEmpty) {
            chatMessages.add({
              'role': marker.role == '사용자' ? 'user' : 'ai',
              'message': content,
            });
            print('✅ 메시지 추가 [${marker.role}]: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
          }
        }
        
        print('✅ 파싱 완료: 총 ${chatMessages.length}개 메시지');
      } catch (e) {
        print('❌ 대화내역 파싱 실패: $e');
        // 파싱 실패 시 원본 텍스트를 하나의 메시지로 표시
        chatMessages = [
          {'role': 'ai', 'message': review.chatHistory!}
        ];
      }
    }
    
    // 대화내역이 없으면 빈 상태 표시
    if (chatMessages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: chatMessages.length,
      itemBuilder: (context, index) {
        final message = chatMessages[index];
        final isUser = message['role'] == 'user';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                // AI 아바타
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              Expanded(
                child: Column(
                  crossAxisAlignment: isUser 
                      ? CrossAxisAlignment.end 
                      : CrossAxisAlignment.start,
                  children: [
                    // 발신자 라벨
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        isUser ? '나' : '치읓',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    
                    // 메시지 버블
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser 
                            ? AppColors.primary
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message['message']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isUser ? Colors.white : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (isUser) ...[
                const SizedBox(width: 12),
                // 사용자 아바타
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '대화내역이 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '이 감동문은 대화 없이 작성되었습니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// 메시지 위치 마커 헬퍼 클래스
class _MessageMarker {
  final int position;
  final String role; // '사용자' 또는 'AI'
  
  _MessageMarker(this.position, this.role);
}
