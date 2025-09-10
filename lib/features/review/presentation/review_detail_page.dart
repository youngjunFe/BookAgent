import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/review.dart';
import '../../chat/presentation/character_selection_page.dart';
import 'review_editor_page.dart';
import 'chat_history_page.dart';

class ReviewDetailPage extends StatelessWidget {
  final Review review;

  const ReviewDetailPage({
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
                      '나의 서재',
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
            
            // 스크롤 가능한 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 태그들
                    Row(
                      children: [
                        _buildTag('📖 데미안', false),
                        const SizedBox(width: 8),
                        _buildTag('완료', true),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 제목
                    const Text(
                      '헤르만 헤세의 철학적 사유가 녹아있는 이 책은 처음에 어렵게 다가왔다.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 작성 시간
                    const Text(
                      '10시간 전 작성',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 감동문 내용 박스
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1), // 연한 노란색 배경
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '헤르만 헤세의 철학적 사유가 녹아있는 이 책은 처음에 어렵게 다가왔다.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A4A4A),
                              height: 1.5,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          Text(
                            review.content.isNotEmpty 
                                ? review.content 
                                : '''헤르만 헤세의 철학적 사유가 녹아있는 이 책은 처음에 어렵게 다가왔다. '새는 알에서 나오려고 투쟁한다'는 문장처럼, 난해한 은유들이 가득했다. 하지만 읽어갈수록 이상하게도 위로받는 기분이 들었다.

지금의 나 역시 무언가를 깨고 나와야 하는 시기를 보내고 있지 때문일까. 주인공 싱클레어를 이끌어주는 데미안의 모습에서, 내게도 그런 조력자가 있었으면 하는 바람과 동시에 나 또한 누군가의 데미안이 되고 싶다는 생각이 들었다. 이 책은 진정한 '나'를 찾아가는 여정에 대한 이야기다.''',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF4A4A4A),
                              height: 1.6,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // 하단 버튼들
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            '대화내역',
                            onTap: () => _navigateToChat(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            '감동문 공유',
                            onTap: () => _shareReview(context),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF9BB5D6) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일';
    } else {
      return '${dateTime.month}월 ${dateTime.day}일';
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 기능은 준비 중입니다.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatHistoryPage(review: review),
      ),
    );
  }

  void _shareReview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
              '감동문 공유하기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.primary),
              title: const Text('링크 복사'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, '링크 복사');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.primary),
              title: const Text('다른 앱으로 공유'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, '다른 앱으로 공유');
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: AppColors.primary),
              title: const Text('이미지로 저장'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, '이미지로 저장');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
