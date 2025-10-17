import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:html' as html if (dart.library.html) 'dart:html';
import '../../../core/constants/app_colors.dart';
import '../models/review.dart';
import '../../chat/presentation/character_selection_page.dart';
import 'review_editor_page.dart';
import 'chat_history_page.dart';

class ReviewDetailPage extends StatelessWidget {
  final Review review;
  static final GlobalKey _repaintKey = GlobalKey();

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
                    // 상단 태그들 (말줄임표 처리)
                    Row(
                      children: [
                        Flexible(
                          child: _buildTag('📖 ${review.bookTitle}', false),
                        ),
                        const SizedBox(width: 8),
                        _buildTag(review.statusText, true),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 제목
                    Text(
                      review.title.isNotEmpty ? review.title : '${review.bookTitle}에 대한 감동문',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 작성 시간
                    Text(
                      '${_formatDateTime(review.updatedAt)} 전 작성',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 감동문 내용 박스 (이미지 캡처용)
                    RepaintBoundary(
                      key: _repaintKey,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1), // 연한 노란색 배경
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            // 감동문 내용
                            Text(
                              review.content.isNotEmpty 
                                  ? review.content 
                                  : '${review.bookTitle}에 대한 감동문이 아직 작성되지 않았습니다.',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF4A4A4A),
                                height: 1.6,
                                letterSpacing: -0.2,
                              ),
                            ),
                            
                            // 하단 서명
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '- 치읓과 함께 -',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF4A4A4A).withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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

  Future<void> _saveAsImage(BuildContext context) async {
    try {
      // RepaintBoundary로 감싼 위젯을 이미지로 캡처
      RenderRepaintBoundary boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        
        // 웹에서 파일 다운로드
        _downloadImageWeb(bytes, review.bookTitle);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('감동문이 이미지로 저장되었습니다!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('이미지 저장 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지 저장에 실패했습니다.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              '감동문 저장하기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.image, color: AppColors.primary),
              title: const Text('이미지로 저장'),
              subtitle: const Text('감동문을 이미지 파일로 저장합니다'),
              onTap: () {
                Navigator.pop(context);
                _saveAsImage(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 웹에서만 사용되는 이미지 다운로드 함수
  static void _downloadImageWeb(Uint8List bytes, String bookTitle) {
    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = '감동문_${bookTitle}_${DateTime.now().millisecondsSinceEpoch}.png';
      
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('웹 다운로드 오류: $e');
    }
  }
}
