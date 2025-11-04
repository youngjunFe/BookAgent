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
        
        // lookahead를 사용하여 \n\n 뒤에 "사용자: " 또는 "AI: "가 오는 경우만 split
        final parts = text.split(RegExp(r'\n\n(?=사용자: |AI: )'));
        
        for (final part in parts) {
          final trimmed = part.trim();
          if (trimmed.isEmpty) continue;
          
          if (trimmed.startsWith('사용자: ')) {
            chatMessages.add({
              'role': 'user',
              'message': trimmed.substring(4).trim(),
            });
          } else if (trimmed.startsWith('AI: ')) {
            chatMessages.add({
              'role': 'ai',
              'message': trimmed.substring(4).trim(),
            });
          }
        }
      } catch (e) {
        print('대화내역 파싱 실패: $e');
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
