import 'package:flutter/material.dart';
import 'dart:convert';
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
  // 화면/저장 전체에서 일관되게 사용할 책 메타
  String? _bookTitle;
  String? _bookAuthor;

  @override
  void initState() {
    super.initState();
    // 위젯으로 전달된 값을 우선 적용
    _bookTitle = widget.bookTitle;
    _bookAuthor = widget.bookAuthor;
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
        String reviewContent = tempReview;
        
        // JSON 형태로 저장된 경우 파싱
        try {
          if (tempReview.startsWith('{"review":')) {
            final data = json.decode(tempReview);
            if (data is Map && data['review'] is String) {
              reviewContent = data['review'] as String;
            }
          }
        } catch (_) {
          // JSON 파싱 실패 시 원본 사용
        }
        
        // 본문은 항상 정제된 결과만 보이도록 강제
        final sanitized = _sanitizeContent(reviewContent);
        setState(() {
          _generatedContent = sanitized;
          // 위젯으로 전달되지 않았고 임시 저장 값이 있으면 보강
          if ((_bookTitle == null || _bookTitle!.isEmpty) &&
              (tempBookTitle != null && !_isBannedTitle(tempBookTitle))) {
            _bookTitle = tempBookTitle.trim();
          }
          if ((_bookAuthor == null || _bookAuthor!.isEmpty) &&
              (tempBookAuthor != null && tempBookAuthor.trim().isNotEmpty)) {
            _bookAuthor = tempBookAuthor.trim();
          }
        });

        print('🧭 [ReviewCreationPage] Loaded from temp: '
            'title="${_bookTitle ?? '(none)'}", author="${_bookAuthor ?? '(none)'}"');
        
        // 임시 저장된 데이터가 있음을 사용자에게 알림
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('임시 저장된 "${tempBookTitle ?? '책'}" 발제문을 불러왔습니다.'),
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
                  if (_bookTitle != null && !_isBannedTitle(_bookTitle!)) ...[
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
                                  _bookTitle!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_bookAuthor != null)
                                  Text(
                                    _bookAuthor!,
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
    final sanitized = _sanitizeContent(content);
    _inferMetaFromContent(sanitized);
    setState(() {
      _isGenerating = false;
      _generatedContent = sanitized;
    });
    print('🧹 [ReviewCreationPage] Generated + sanitized content length: '
        '${_generatedContent!.length}');
  }

  void _regenerateReview() {
    setState(() {
      _generatedContent = null;
    });
    _generateReview();
  }

  // 불필요한 Markdown/따옴표/별표 정리
  String _stripMarkdown(String text) {
    String t = text;
    // 굵게 **텍스트** 제거
    t = t.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');
    // 인라인 코드, 백틱 제거
    t = t.replaceAll('```', '').replaceAll('`', '');
    // 따옴표/책제목 기호 정리
    t = t.replaceAll(RegExp('[“”]'), '"');
    t = t.replaceAll('『', '').replaceAll('』', '');
    t = t.replaceAll('《', '').replaceAll('》', '');
    // 라인 양끝 따옴표/별표 제거
    t = t.replaceAll(RegExp(r'^\*+'), '');
    t = t.replaceAll(RegExp(r'\*+$'), '');
    t = t.replaceAll(RegExp(r'^\"+|\"+$'), '');
    // 공백 정리
    t = t.replaceAll(RegExp('[ \t]+\n'), '\n');
    return t.trim();
  }

  // 금지된/무의미한 제목값 식별
  bool _isBannedTitle(String value) {
    String t = value
        .replaceAll(RegExp('[\u200B-\u200D\uFEFF\u00A0]'), '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('*', '')
        .trim();
    return t.isEmpty || t == '안녕하세요' || t == '책';
  }

  // 본문 정리: 제목/섹션 머리글 제거, 마크다운 기호 제거
  String _sanitizeContent(String content) {
    final lines = content.split('\n');
    final List<String> out = [];
    for (var line in lines) {
      String l = line.trim();
      // 제로폭 문자 제거 (BOM 포함)
      l = l.replaceAll(RegExp('[\u200B-\u200D\uFEFF]'), '');
      // 1) 발제문 제목 라인 제거: "제목:" 혹은 굵게 처리된 제목 패턴
      if (RegExp(r'^[\*\s\"\-·>]{0,8}(제\s*목|TITLE|Title|title)\s*[:：\-]').hasMatch(l)) {
        continue; // 제목은 별도 필드에서만 관리
      }
      // 2) 서론/본론/결론 머리글(별표 유무 포함) 라인 제거
      if (RegExp(r'^[\*\s>\-·]{0,8}(서\s*론|본\s*론|결\s*론|인\s*용\s*구|요\s*약|요\s*점|마\s*무\s*리)\s*[:：\-\.]*\s*\*{0,3}\s*$').hasMatch(l)) {
        continue;
      }
      // 3) 라인 내 마크다운 강조 제거(**..**, *..*, ~~..~~) + 헤딩 해시 제거
      l = l.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');
      l = l.replaceAll(RegExp(r'(?<!\*)\*(?!\s)(.*?)(?<!\s)\*(?!\*)'), r'$1');
      l = l.replaceAll(RegExp(r'~~(.*?)~~'), r'$1');
      l = l.replaceAll(RegExp(r'^#{1,6}\s*'), '');
      // 4) 라인 앞뒤 별표/공백 정리
      l = l.replaceAll(RegExp(r'^\*+'), '');
      l = l.replaceAll(RegExp(r'\*+$'), '');
      l = _stripMarkdown(l);
      if (l.isEmpty) continue; // 정리 후 빈 줄은 생략
      out.add(l);
    }
    // 5) 연속 빈 줄은 1개로 축약
    String collapsed = out.join('\n').replaceAll(RegExp('\n{3,}'), '\n\n');
    return collapsed.trim();
  }

  // 생성된 본문에서 책 제목/저자 유추
  void _inferMetaFromContent(String content) {
    String text = content;
    // 저자 패턴: 저자:, 지은이:, 글:, by ...
    final authorMatch = RegExp(r'(저자|지은이|글)\s*[:：]\s*([^\n]+)').firstMatch(text)
        ?? RegExp(r'\bby\s+([^\n]+)', caseSensitive: false).firstMatch(text);
    if (authorMatch != null) {
      final author = authorMatch.group(authorMatch.groupCount)!.trim();
      if (_bookAuthor == null || _bookAuthor!.isEmpty) {
        _bookAuthor = author;
      }
    }

    // 내용 속 따옴표로 감싼 책 제목 패턴
    if (_bookTitle == null || _bookTitle!.isEmpty || _isBannedTitle(_bookTitle!)) {
      final titleMatch = RegExp(r'"([^\"]{2,50})"').firstMatch(text)
          ?? RegExp(r'『([^』]{2,50})』').firstMatch(text)
          ?? RegExp(r'《([^》]{2,50})》').firstMatch(text);
      if (titleMatch != null) {
        _bookTitle = titleMatch.group(1)!.trim();
      }
    }
  }

  // AI 생성 발제문에서 제목 추출
  String _extractTitleFromContent(String content) {
    // 전체를 먼저 정제한 뒤 첫 줄로 판단
    final sanitized = _sanitizeContent(content);
    final head = sanitized.split('\n').firstWhere((_) => true, orElse: () => '').trim();
    // 패턴 1: **제목: "..."** 또는 제목: "..."
    final m1 = RegExp(r'^\**\s*제목\s*[:：]\s*\"?([^\"]+)\"?').firstMatch(head);
    if (m1 != null) {
      final t = _stripMarkdown(m1.group(1)!.trim());
      if (t.isNotEmpty && t != '안녕하세요' && t != '제목') return t;
    }
    // 패턴 2: 첫 줄이 비교적 짧은 문장 → 제목으로 간주
    if (head.isNotEmpty && head.length <= 50) {
      final t = _stripMarkdown(head);
      if (t.isNotEmpty && t != '안녕하세요' && t != '책' && !t.startsWith('서론') && !t.startsWith('본문')) {
        return t;
      }
    }
    // 기본값: 금지된 제목값이면 안전한 대체값 사용
    final base = (_bookTitle == null || _isBannedTitle(_bookTitle!))
        ? '새로운 책'
        : _bookTitle!;
    return _stripMarkdown('$base에 대한 발제문');
  }

  Future<void> _saveReview() async {
    if (_generatedContent == null || _generatedContent!.isEmpty) return;
    
    try {
      // 저장 직전 한 번 더 정제해 안전 보장
      final cleaned = _sanitizeContent(_generatedContent!);
      final extractedTitle = _extractTitleFromContent(cleaned);
      
      final review = Review(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // API에서 자동으로 현재 사용자 ID로 설정됨
        title: extractedTitle,
        content: cleaned,
        bookTitle: _bookTitle ?? '알 수 없음',
        bookAuthor: _bookAuthor,
        status: ReviewStatus.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        chatHistory: widget.chatHistory,
      );

      print('💾 [ReviewCreationPage] Save review: '
          'bookTitle="${review.bookTitle}", bookAuthor="${review.bookAuthor ?? '(none)'}", '
          'title="${review.title}", contentLen=${review.content.length}');

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
      print('🚨 [ReviewCreationPage._saveReview] 저장 실패: $e');
      print('📍 [ReviewCreationPage._saveReview] 에러 세부사항: ${e.runtimeType}');
      
      String errorMessage = '저장에 실패했습니다.';
      if (e.toString().contains('user_id')) {
        errorMessage = '사용자 인증 오류. 로그인을 다시 시도하세요.';
      } else if (e.toString().contains('relation') || e.toString().contains('column')) {
        errorMessage = '데이터베이스 오류. 관리자에게 문의하세요.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _editReview() {
    final cleaned = _sanitizeContent(_generatedContent!);
    final extractedTitle = _extractTitleFromContent(cleaned);
    
    // AI 생성 발제문에서 실제 책 제목 추출 시도
    String actualBookTitle = _bookTitle ?? '';
    if (_bookTitle != null && _isBannedTitle(_bookTitle!)) {
      actualBookTitle = '';
    }
    
    // 발제문 내용에서 책 제목을 찾아보기
    if ((actualBookTitle.isEmpty) && _generatedContent!.contains('서론:')) {
      final lines = _generatedContent!.split('\n');
      for (String line in lines) {
        if (line.contains('"') && line.contains('을 읽으면서')) {
          // "책제목"을 읽으면서 패턴에서 책 제목 추출
          final match = RegExp(r'"([^"]+)"을? 읽으면서').firstMatch(line);
          if (match != null) {
            actualBookTitle = match.group(1) ?? actualBookTitle;
            break;
          }
        }
      }
    }
    
    print('📚 편집용 Review 생성 - 책 제목: "$actualBookTitle", 발제문 제목: "$extractedTitle"');
    
    final review = Review(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // API에서 자동으로 현재 사용자 ID로 설정됨
      title: extractedTitle,
      content: cleaned,
      bookTitle: actualBookTitle.isEmpty ? '' : actualBookTitle,
      bookAuthor: _bookAuthor,
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
          initialContext: '발제문: ${_bookTitle ?? ''}\n\n${_sanitizeContent(_generatedContent!)}',
          bookTitle: _bookTitle,
          bookAuthor: _bookAuthor,
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
      userId: '', // API에서 자동으로 현재 사용자 ID로 설정됨
      title: '새로운 발제문',
      content: '',
      bookTitle: _bookTitle ?? '',
      bookAuthor: _bookAuthor,
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

