import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../models/review.dart';
import '../data/review_repository.dart';
import 'review_editor_page.dart';
import '../../chat/presentation/ai_chat_page.dart';
import '../services/review_ai_service.dart';
import '../../../shared/widgets/main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewCreationPage extends StatefulWidget {
  final String? chatHistory;
  final String? bookTitle;
  final String? bookAuthor;

  const ReviewCreationPage({
    super.key,
    this.chatHistory,
    this.bookTitle,
    this.bookAuthor,
  });

  @override
  State<ReviewCreationPage> createState() => _ReviewCreationPageState();
}

class _ReviewCreationPageState extends State<ReviewCreationPage> {
  bool _isGenerating = false;
  String? _generatedContent;

  @override
  void initState() {
    super.initState();
    _loadTempReview();
    if (widget.chatHistory != null) {
      _generateReview();
    }
  }

  Future<void> _loadTempReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tempReview = prefs.getString('temp_review');
      final tempBookTitle = prefs.getString('temp_book_title');
      final tempBookAuthor = prefs.getString('temp_book_author');
      
      if (tempReview != null && tempReview.isNotEmpty) {
        setState(() {
          _generatedContent = tempReview;
        });
        
        // 임시 저장된 데이터가 있음을 사용자에게 알림
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('임시 저장된 "$tempBookTitle" 발제문을 불러왔습니다.'),
              backgroundColor: AppColors.primary,
            ),
          );
        });
      }
    } catch (e) {
      print('임시 저장 데이터 로드 실패: $e');
    }
  }

  Future<void> _clearTempReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('temp_review');
      await prefs.remove('temp_book_title');
      await prefs.remove('temp_book_author');
      await prefs.remove('temp_chat_history');
    } catch (e) {
      print('임시 저장 데이터 삭제 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('발제문 생성'),
        backgroundColor: AppColors.background,
        elevation: 1,
        shadowColor: AppColors.dividerColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 정보
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.dividerColor,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI 발제문 생성',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'AI와의 대화를 바탕으로 의미 있는 발제문을 생성합니다.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (widget.bookTitle != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.book,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.bookTitle!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (widget.bookAuthor != null)
                                  Text(
                                    widget.bookAuthor!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 생성 과정 표시
            if (_isGenerating) ...[
              _buildGeneratingView(),
            ] else if (_generatedContent != null) ...[
              _buildGeneratedView(),
            ] else ...[
              _buildInitialView(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.dividerColor,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.article_outlined,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                '발제문을 생성해보세요',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI와의 대화 내용을 바탕으로\n의미 있는 발제문을 자동으로 생성해드립니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateReview,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('발제문 생성하기'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 또는 직접 작성
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _createManually,
            icon: const Icon(Icons.edit),
            label: const Text('직접 작성하기'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratingView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI가 발제문을 생성 중입니다...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '대화 내용을 분석하여\n의미 있는 발제문을 만들고 있어요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 성공 메시지
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.success.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '발제문이 성공적으로 생성되었습니다!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 생성된 발제문 미리보기
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.dividerColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.preview,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '발제문 미리보기',
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
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.dividerColor,
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _generatedContent!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 액션 버튼들
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _regenerateReview,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 생성'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveReview,
                icon: const Icon(Icons.save),
                label: const Text('저장하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _editReview,
                icon: const Icon(Icons.edit),
                label: const Text('편집하기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // AI 대화 시작 버튼
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _startAiChat,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('이 발제문으로 AI와 대화하기'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.secondary),
            ),
          ),
        ),
      ],
    );
  }

  void _generateReview() async {
    setState(() {
      _isGenerating = true;
    });

    final content = await ReviewAiService.generateReview(
      chatHistory: widget.chatHistory,
      bookTitle: widget.bookTitle,
    );

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _generatedContent = content;
    });
  }

  void _regenerateReview() {
    setState(() {
      _generatedContent = null;
    });
    _generateReview();
  }

  // AI 생성 발제문에서 제목 추출
  String _extractTitleFromContent(String content) {
    final lines = content.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines[0].trim();
      // 첫 번째 줄이 제목인 경우 (보통 "제목" 또는 "책 제목에 대한 발제문" 형태)
      if (firstLine.isNotEmpty && 
          (firstLine.contains('발제문') || firstLine.contains('에 대한') || firstLine.length < 50)) {
        return firstLine;
      }
    }
    // 제목을 찾지 못한 경우 기본 제목 사용
    return '${widget.bookTitle ?? '새로운 책'}에 대한 발제문';
  }

  Future<void> _saveReview() async {
    if (_generatedContent == null || _generatedContent!.isEmpty) return;
    
    try {
      final extractedTitle = _extractTitleFromContent(_generatedContent!);
      
      final review = Review(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: extractedTitle,
        content: _generatedContent!,
        bookTitle: widget.bookTitle ?? '알 수 없음',
        bookAuthor: widget.bookAuthor,
        status: ReviewStatus.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        chatHistory: widget.chatHistory,
      );

      // 실제 Supabase에 저장
      final reviewRepository = ReviewRepository();
      await reviewRepository.create(review);
      
      // 임시 저장 데이터 삭제
      await _clearTempReview();
      
      // 저장 완료 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('발제문이 저장되었습니다!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // 메인 페이지로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false,
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('저장에 실패했습니다.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _editReview() {
    final extractedTitle = _extractTitleFromContent(_generatedContent!);
    
    final review = Review(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: extractedTitle,
      content: _generatedContent!,
      bookTitle: widget.bookTitle ?? '알 수 없음',
      bookAuthor: widget.bookAuthor,
      status: ReviewStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      chatHistory: widget.chatHistory,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewEditorPage(review: review),
      ),
    ).then((_) {
      // 편집 페이지에서 돌아온 후 임시 데이터 삭제
      _clearTempReview();
    });
  }

    void _startAiChat() {
    if (_generatedContent == null) return;

    // 발제문 작성으로 책이 완독되었음을 표시
    _markBookAsCompleted();

    // AI 채팅 페이지로 이동하면서 발제문 내용을 초기 컨텍스트로 전달
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiChatPage(
          initialContext: '발제문: ${widget.bookTitle ?? ''}\n\n$_generatedContent',
          bookTitle: widget.bookTitle,
        ),
      ),
    );
  }

  void _markBookAsCompleted() {
    // 발제문을 작성했다는 것은 책을 완독했다는 의미
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('${widget.bookTitle ?? '책'}이 완독으로 기록되었습니다! 🎉'),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _createManually() {
    final review = Review(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '새로운 발제문',
      content: '',
      bookTitle: widget.bookTitle ?? '',
      bookAuthor: widget.bookAuthor,
      status: ReviewStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      chatHistory: widget.chatHistory,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewEditorPage(review: review),
      ),
    );
  }
}

