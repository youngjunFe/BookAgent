import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/review.dart';
import '../../chat/presentation/character_selection_page.dart';
import 'review_editor_page.dart';

class ReviewDetailPage extends StatelessWidget {
  final Review review;

  const ReviewDetailPage({
    super.key,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '나의 서재',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 버튼들
            Row(
              children: [
                _buildTopButton(
                  context,
                  label: '데이안',
                  isSelected: false,
                  onTap: () => _showComingSoon(context, '데이안'),
                ),
                const SizedBox(width: 12),
                _buildTopButton(
                  context,
                  label: '완료',
                  isSelected: true,
                  onTap: () => _showComingSoon(context, '완료'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 책 제목과 감동문 제목
            Text(
              '${review.bookTitle}의 철학적 사유가 녹아있는 이 책은 처음에 어렵게 다가왔다.',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // 작성 시간
            Text(
              '${_formatDateTime(review.updatedAt)} 전 작성',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
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
                border: Border.all(
                  color: const Color(0xFFFFE0B2).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 감동문 제목
                  Text(
                    review.title.isNotEmpty 
                        ? review.title 
                        : '헤르만 헤세의 철학적 사유가 녹아있는 이 책은 처음에 어렵게 다가왔다.',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5D4E37), // 어두운 갈색
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 감동문 내용
                  Text(
                    review.content.isNotEmpty 
                        ? review.content 
                        : '''헤르만 헤세의 철학적 사유가 녹아있는 이 책은 처음에 어렵게 다가왔다. '새는 알에서 나오려고 투쟁한다'는 문장처럼, 난해한 은유들이 가득했다. 하지만 읽어갈수록 이상하게도 위로받는 기분이 들었다.

지금의 나 역시 무언가를 깨고 나와야 하는 시기를 보내고 있지 때문일까. 주인공 싱클레어를 이끌어주는 데미안의 모습에서, 내게도 그런 조력자가 있었으면 하는 바람과 동시에 나 또한 누군가의 데미안이 되고 싶다는 생각이 들었다. 이 책은 진정한 '나'를 찾아가는 여정에 대한 이야기다.''',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF5D4E37),
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
                  child: _buildBottomButton(
                    context,
                    label: '대화내역',
                    onTap: () => _navigateToChat(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBottomButton(
                    context,
                    label: '감동문 공유',
                    onTap: () => _shareReview(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildTopButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9BB5D6) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF9BB5D6) : AppColors.dividerColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.dividerColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
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
        builder: (context) => const CharacterSelectionPage(),
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
