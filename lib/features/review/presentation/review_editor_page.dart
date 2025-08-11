import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../models/review.dart';
import 'background_selection_page.dart';
import '../../../shared/widgets/main_navigation.dart';
import '../data/review_repository.dart';

class ReviewEditorPage extends StatefulWidget {
  final Review review;

  const ReviewEditorPage({
    super.key,
    required this.review,
  });

  @override
  State<ReviewEditorPage> createState() => _ReviewEditorPageState();
}

class _ReviewEditorPageState extends State<ReviewEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _bookTitleController;
  late TextEditingController _bookAuthorController;
  late TextEditingController _tagsController;
  
  late Review _currentReview;
  bool _hasChanges = false;
  final _repo = ReviewRepository();

  @override
  void initState() {
    super.initState();
    _currentReview = widget.review;
    _titleController = TextEditingController(text: _currentReview.title);
    _contentController = TextEditingController(text: _currentReview.content);
    _bookTitleController = TextEditingController(text: _currentReview.bookTitle);
    _bookAuthorController = TextEditingController(text: _currentReview.bookAuthor ?? '');
    _tagsController = TextEditingController(text: _currentReview.tags.join(', '));

    // 변경 사항 감지
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
    _bookTitleController.addListener(_onChanged);
    _bookAuthorController.addListener(_onChanged);
    _tagsController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _bookTitleController.dispose();
    _bookAuthorController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('발제문 편집'),
        backgroundColor: AppColors.background,
        elevation: 1,
        shadowColor: AppColors.dividerColor,
        leading: IconButton(
          onPressed: _onBackPressed,
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          // 상태 표시
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _currentReview.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _currentReview.statusText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _currentReview.statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 더보기 메뉴
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'background':
                  _selectBackground();
                  break;
                case 'preview':
                  _previewReview();
                  break;
                case 'status':
                  _changeStatus();
                  break;
                case 'delete':
                  _deleteReview();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'background',
                child: Row(
                  children: [
                    Icon(Icons.image, size: 20),
                    SizedBox(width: 8),
                    Text('배경 이미지'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'preview',
                child: Row(
                  children: [
                    Icon(Icons.preview, size: 20),
                    SizedBox(width: 8),
                    Text('미리보기'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 20),
                    SizedBox(width: 8),
                    Text('상태 변경'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('삭제', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 변경 사항 알림
          if (_hasChanges)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.warning.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '변경 사항이 있습니다. 저장하지 않으면 손실됩니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),

          // 편집 폼
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 책 정보 섹션
                  _buildSection(
                    title: '책 정보',
                    icon: Icons.book,
                    child: Column(
                      children: [
                        TextField(
                          controller: _bookTitleController,
                          decoration: const InputDecoration(
                            labelText: '책 제목',
                            hintText: '책의 제목을 입력하세요',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _bookAuthorController,
                          decoration: const InputDecoration(
                            labelText: '저자',
                            hintText: '저자명을 입력하세요',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 발제문 제목
                  _buildSection(
                    title: '발제문 제목',
                    icon: Icons.title,
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: '발제문의 제목을 입력하세요',
                        border: InputBorder.none,
                      ),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 발제문 내용
                  _buildSection(
                    title: '발제문 내용',
                    icon: Icons.article,
                    child: TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: '발제문의 내용을 작성하세요...\n\n감상, 질문, 토론 주제 등을 자유롭게 써보세요.',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      minLines: 10,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 태그
                  _buildSection(
                    title: '태그',
                    icon: Icons.tag,
                    child: TextField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        hintText: '태그를 쉼표로 구분해서 입력하세요 (예: 성장, 우정, 모험)',
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 배경 이미지 선택
                  _buildSection(
                    title: '배경 이미지',
                    icon: Icons.image,
                    child: GestureDetector(
                      onTap: _selectBackground,
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _currentReview.backgroundImage != null
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: _currentReview.backgroundImage != null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '배경 이미지 선택됨',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '탭해서 변경',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: AppColors.textHint,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '배경 이미지 선택',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '탭해서 선택',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // 하단 저장 버튼
          Container(
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
                  child: OutlinedButton(
                    onPressed: _saveDraft,
                    child: const Text('임시저장'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveReview,
                    child: const Text('저장'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.dividerColor,
              width: 1,
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  void _onBackPressed() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('변경 사항이 있습니다'),
          content: const Text('저장하지 않고 나가시겠습니까?\n변경 사항이 손실됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                '나가기',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _saveDraft() {
    _updateReview(ReviewStatus.draft);
    _saveReview();
  }

  Future<void> _saveReview() async {
    _updateReview(_currentReview.status);
    try {
      // UUID(36자, 하이픈 포함)이면 업데이트, 아니면 새로 생성
      final isUuid = RegExp(r'^[0-9a-fA-F\-]{36} ?$').hasMatch(_currentReview.id);
      if (isUuid) {
        await _repo.update(_currentReview);
      } else {
        final created = await _repo.create(_currentReview);
        _currentReview = created;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('발제문이 저장되었습니다.'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: '서재로 이동',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 1),
                ),
                (route) => false,
              );
            },
          ),
        ),
      );

      setState(() {
        _hasChanges = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _updateReview(ReviewStatus status) {
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    _currentReview = _currentReview.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      bookTitle: _bookTitleController.text,
      bookAuthor: _bookAuthorController.text.isEmpty ? null : _bookAuthorController.text,
      status: status,
      tags: tags,
      updatedAt: DateTime.now(),
    );
  }

  void _selectBackground() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BackgroundSelectionPage(
          onSelected: (backgroundImage) {
            setState(() {
              _currentReview = _currentReview.copyWith(
                backgroundImage: backgroundImage,
              );
              _hasChanges = true;
            });
          },
        ),
      ),
    );
  }

  void _previewReview() {
    _updateReview(_currentReview.status);
    // TODO: 미리보기 페이지 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('미리보기 기능을 준비 중입니다.'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _changeStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('상태 변경'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReviewStatus.values.map((status) {
            return ListTile(
              leading: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
              ),
              title: Text(_getStatusText(status)),
              onTap: () {
                setState(() {
                  _currentReview = _currentReview.copyWith(status: status);
                  _hasChanges = true;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _deleteReview() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('발제문 삭제'),
        content: const Text('정말로 이 발제문을 삭제하시겠습니까?\n삭제된 발제문은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _repo.delete(_currentReview.id);
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('발제문이 삭제되었습니다.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('삭제 실패: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.draft:
        return Icons.edit;
      case ReviewStatus.completed:
        return Icons.check_circle;
      case ReviewStatus.published:
        return Icons.public;
    }
  }

  Color _getStatusColor(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.draft:
        return Colors.orange;
      case ReviewStatus.completed:
        return Colors.green;
      case ReviewStatus.published:
        return Colors.blue;
    }
  }

  String _getStatusText(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.draft:
        return '초안';
      case ReviewStatus.completed:
        return '완료';
      case ReviewStatus.published:
        return '게시';
    }
  }
}
