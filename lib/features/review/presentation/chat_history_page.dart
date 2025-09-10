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
    // 실제로는 JSON 파싱해서 대화 목록을 보여줘야 함
    // 임시로 더미 데이터 사용
    final chatMessages = [
      {'role': 'user', 'message': '데미안이라는 책에 대해 어떻게 생각해?'},
      {'role': 'ai', 'message': '헤르만 헤세의 "데미안"은 성장과 자아 발견에 대한 깊이 있는 작품입니다. 주인공 싱클레어가 데미안을 통해 진정한 자아를 찾아가는 과정이 인상적이죠.'},
      {'role': 'user', 'message': '특히 인상깊었던 구절이 있어. "새는 알에서 나오려고 투쟁한다"는 부분 말이야.'},
      {'role': 'ai', 'message': '정말 의미깊은 구절이네요! 이 문장은 우리가 기존의 틀을 벗어나 새로운 자아로 태어나기 위해서는 고통스러운 투쟁이 필요하다는 것을 상징적으로 표현하고 있어요. 어떤 부분에서 특히 공감하셨나요?'},
      {'role': 'user', 'message': '지금의 내 상황과 비슷해서 그런 것 같아. 무언가를 깨고 나와야 하는 시기를 보내고 있거든.'},
      {'role': 'ai', 'message': '그런 시기를 보내고 계시는군요. 변화의 과정은 쉽지 않지만, 그 과정 자체가 성장의 증거라고 생각해요. 데미안처럼 당신을 이끌어줄 조력자나 멘토가 있으신가요?'},
    ];

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
