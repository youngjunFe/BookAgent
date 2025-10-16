import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../models/review.dart';
import '../data/review_repository.dart';
import 'review_editor_page.dart';
import '../../chat/presentation/ai_chat_page.dart';
import '../services/review_ai_service.dart';
import '../../../shared/widgets/main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/services/supabase_auth_service.dart';
import '../../auth/presentation/login_page.dart';

// 웹에서만 사용 가능한 import
import 'dart:html' as html;

class ReviewCreationPage extends StatefulWidget {
  final String? chatHistory;
  final String? bookTitle;
  final String? bookAuthor;
  final String? bookPublisher;
  final String? bookIsbn;
  final String? bookDescription;

  const ReviewCreationPage({
    super.key,
    this.chatHistory,
    this.bookTitle,
    this.bookAuthor,
    this.bookPublisher,
    this.bookIsbn,
    this.bookDescription,
  });

  @override
  State<ReviewCreationPage> createState() => _ReviewCreationPageState();
}

class _ReviewCreationPageState extends State<ReviewCreationPage> {
  bool _isGenerating = false;
  String? _generatedContent;
  String? _bookTitle;
  String? _bookAuthor;
  int _selectedBackgroundIndex = 0;
  final GlobalKey _repaintKey = GlobalKey();

  // 배경색 옵션들
  final List<Color> _backgroundColors = [
    Color(0xFFFFF8DC), // 크림색 (기본)
    Color(0xFFE8F5E8), // 연한 초록색
    Color(0xFFE3F2FD), // 연한 파란색
    Color(0xFFFCE4EC), // 연한 핑크색
    Color(0xFFF3E5F5), // 연한 보라색
  ];

  @override
  void initState() {
    super.initState();
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
        
        setState(() {
          _generatedContent = reviewContent;
          if ((_bookTitle == null || _bookTitle!.isEmpty) &&
              (tempBookTitle != null && tempBookTitle.isNotEmpty)) {
            _bookTitle = tempBookTitle.trim();
          }
          if ((_bookAuthor == null || _bookAuthor!.isEmpty) &&
              (tempBookAuthor != null && tempBookAuthor.trim().isNotEmpty)) {
            _bookAuthor = tempBookAuthor.trim();
          }
        });
      }
    } catch (e) {
      print('임시 저장 데이터 로드 실패: $e');
    }
  }

  // 임시 저장 기능
  Future<void> _saveTempReview() async {
    if (_generatedContent == null || _generatedContent!.trim().isEmpty) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_review', _generatedContent!);
      if (_bookTitle != null) {
        await prefs.setString('temp_book_title', _bookTitle!);
      }
      if (_bookAuthor != null) {
        await prefs.setString('temp_book_author', _bookAuthor!);
      }
      if (widget.chatHistory != null) {
        await prefs.setString('temp_chat_history', widget.chatHistory!);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('감동문이 임시 저장되었습니다'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('임시 저장 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('임시 저장에 실패했습니다'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _generateReview() async {
    if (widget.chatHistory == null) return;

    // 디버깅: 모든 책 정보 출력
    print('🔍 ReviewCreationPage._generateReview 호출');
    print('  📚 widget.bookTitle: ${widget.bookTitle}');
    print('  📚 widget.bookAuthor: ${widget.bookAuthor}');
    print('  📚 widget.bookPublisher: ${widget.bookPublisher}');
    print('  📚 widget.bookIsbn: ${widget.bookIsbn}');
    print('  📚 widget.bookDescription: ${widget.bookDescription != null ? widget.bookDescription!.substring(0, widget.bookDescription!.length > 50 ? 50 : widget.bookDescription!.length) + "..." : "null"}');
    print('  💬 chatHistory length: ${widget.chatHistory!.length}');
    print('  💬 chatHistory preview: ${widget.chatHistory!.substring(0, widget.chatHistory!.length > 100 ? 100 : widget.chatHistory!.length)}...');
    print('  📖 _bookTitle (state): $_bookTitle');
    print('  ✍️ _bookAuthor (state): $_bookAuthor');

    setState(() {
      _isGenerating = true;
    });

    try {
      final content = await ReviewAiService.generateReview(
        chatHistory: widget.chatHistory!,
        bookTitle: widget.bookTitle ?? _bookTitle ?? '',
        bookAuthor: widget.bookAuthor ?? _bookAuthor,
        bookPublisher: widget.bookPublisher,
        bookIsbn: widget.bookIsbn,
        bookDescription: widget.bookDescription,
      );

      setState(() {
        _generatedContent = content;
        _isGenerating = false;
      });
    } catch (e) {
      print('❌ 감동문 생성 실패: $e');
      setState(() {
        _isGenerating = false;
        _generatedContent = _generateFallbackContent();
      });
    }
  }

  String _generateFallbackContent() {
    final title = _bookTitle ?? '책';
    final author = _bookAuthor ?? '작가';
    
    return '$author의 철학적 사유가 녹아있는 이 책은 처음엔 어렵게 다가왔다.\n\n'
           '$author의 철학적 사유가 녹아있는 이 책은 처음엔 어렵게 다가왔다. \'세는 알에서 나오려고 투쟁한다\'는 문장처럼, 난해한 은유들이 가득했다. 하지만 읽어감수록 이상하게도 위로받는 기분이 들었다.\n\n'
           '지금의 나 역시 무언가를 깨고 나와야 하는 시기를 보내고 있기 때문일까. 주인공 싱클레어를 이끌어주는 데미안의 모습에서, 내게도 그런 조력자가 있었으면 하는 바람과 동시에 나 또한 누군가의 데미안이 되고 싶다는 생각이 들었다. 이 책은 진정한 나를 찾아가는 여정에 대한 이야기다.';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            _buildHeader(),
            
            // 메인 콘텐츠 영역
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 감동문 콘텐츠 카드
                    _buildContentCard(),
                    
                    const SizedBox(height: 24),
                    
                    // 하단 버튼들
                    _buildBottomButtons(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상단 헤더
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // 임시 저장 버튼
          GestureDetector(
            onTap: _saveTempReview,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.save_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '임시 저장',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // 타이틀
          Text(
            '감동문',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          
          const Spacer(),
          
          // 우측 여백 (균형을 위해)
          const SizedBox(width: 70),
        ],
      ),
    );
  }

  // 감동문 콘텐츠 카드
  Widget _buildContentCard() {
    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _backgroundColors[_selectedBackgroundIndex],
          borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // 메인 콘텐츠
            if (_isGenerating)
              _buildLoadingState()
            else if (_generatedContent != null)
              _buildGeneratedContent()
            else
              _buildEmptyState(),
            
            const SizedBox(height: 32),
            
            // 하단 정보
                  Row(
                    children: [
                      Text(
                  _getCurrentDate(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 4),
                  Text(
              '${_bookAuthor ?? '작가'}의 ${_bookTitle ?? '책'}을 읽고',
              style: TextStyle(
                fontSize: 12,
                      color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 로딩 상태
  Widget _buildLoadingState() {
    return Container(
      height: 300,
      child: Center(
                            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                              children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
                                  Text(
              '감동문을 생성하고 있어요...',
              style: TextStyle(
                fontSize: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
    );
  }

  // 생성된 콘텐츠
  Widget _buildGeneratedContent() {
    final authService = SupabaseAuthService();
    final isLoggedIn = authService.isLoggedIn;
    
    // 로그인 안 한 경우 블러 처리
    if (!isLoggedIn) {
      final fullText = _generatedContent!;
      final previewLength = (fullText.length * 0.4).toInt(); // 40%만 보여주기
      final previewText = fullText.substring(0, previewLength.clamp(0, fullText.length));
      final blurredText = fullText.substring(previewLength.clamp(0, fullText.length));
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 보이는 부분 (40%)
          Text(
            previewText,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.8,
              letterSpacing: -0.2,
            ),
          ),
          
          // 블러 처리된 나머지 부분
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Stack(
              children: [
                Text(
                  blurredText,
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.3),
                    fontSize: 16,
                    height: 1.8,
                    letterSpacing: -0.2,
                  ),
                ),
                // 그라데이션 오버레이
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _backgroundColors[_selectedBackgroundIndex].withOpacity(0.1),
                        _backgroundColors[_selectedBackgroundIndex].withOpacity(0.9),
                        _backgroundColors[_selectedBackgroundIndex],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 로그인 유도 메시지
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  '전체 감동문을 확인하려면',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '로그인이 필요합니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    // 로그인한 경우 전체 텍스트 표시
    return Text(
      _generatedContent!,
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.8,
        letterSpacing: -0.2,
      ),
    );
  }

  // 빈 상태
  Widget _buildEmptyState() {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '대화 내용을 바탕으로\n감동문을 생성해보세요',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 하단 버튼들
  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
      children: [
          // 수정 & 배경 선택 버튼들
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editContent,
                  icon: Icon(Icons.edit, size: 16),
                  label: Text('수정'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showBackgroundSelector,
                  icon: Icon(Icons.palette, size: 16),
                  label: Text('배경 선택'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
        ),
        
        const SizedBox(height: 16),
        
          // 저장하기 메인 버튼
        SizedBox(
          width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _generatedContent != null ? _saveReview : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                '이 내용으로 저장하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 이미지 공유하기 버튼
          TextButton.icon(
            onPressed: _shareAsImage,
            icon: Icon(
              Icons.photo_library_outlined,
              size: 20,
              color: AppColors.primary,
            ),
            label: Text(
              '이미지 공유하기',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
      ),
    );
  }

  // 콘텐츠 수정
  void _editContent() {
    if (_generatedContent == null) return;
    
    final authService = SupabaseAuthService();
    final currentUser = authService.currentUserInfo;
    
    final review = Review(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser?.id ?? 'temp_user', // 실제 사용자 ID 사용
      title: '${_bookAuthor ?? '작가'}의 ${_bookTitle ?? '책'}을 읽고',
      content: _generatedContent!,
      bookTitle: _bookTitle ?? '책',
      bookAuthor: _bookAuthor,
      status: ReviewStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      chatHistory: widget.chatHistory,
    );
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewEditorPage(
          review: review,
        ),
      ),
    );
  }

  // 배경 선택 (1단계: 기본 이미지 vs 갤러리)
  void _showBackgroundSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
      child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
            // 상단 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
          Text(
              '배경 이미지 선택',
              style: TextStyle(
                fontSize: 18,
              fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            
            // 기본 이미지 버튼
            _buildBackgroundOptionButton(
              title: '기본 이미지',
              icon: Icons.image,
              onTap: () {
                Navigator.of(context).pop();
                _showDefaultImagesSelector();
              },
            ),
            
            const SizedBox(height: 16),
            
            // 갤러리 버튼
            _buildBackgroundOptionButton(
              title: '갤러리',
              icon: Icons.photo_library,
              onTap: () {
                Navigator.of(context).pop();
                _showGalleryPicker();
              },
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // 배경 선택 옵션 버튼
  Widget _buildBackgroundOptionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      child: Material(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
      children: [
        Container(
                  width: 48,
                  height: 48,
          decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 기본 이미지들 선택 (2단계)
  void _showDefaultImagesSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // 상단 핸들
        Container(
              width: 40,
              height: 4,
          decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // 헤더
              Row(
                children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back_ios, size: 20),
                ),
                Expanded(
                  child: Text(
                    '배경 이미지 선택',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    '선택',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
        ),

        const SizedBox(height: 24),

            // 기본 이미지와 갤러리 옵션
        Row(
          children: [
            Expanded(
                  child: _buildImageTypeButton(
                    title: '기본 이미지',
                    isSelected: true,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageTypeButton(
                    title: '갤러리',
                    isSelected: false,
                    onTap: _showGalleryPicker,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 기본 이미지 그리드
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _backgroundColors.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBackgroundIndex = index;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _backgroundColors[index],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedBackgroundIndex == index 
                              ? AppColors.primary 
                              : Colors.grey[300]!,
                          width: _selectedBackgroundIndex == index ? 3 : 1,
                        ),
                      ),
                      child: _selectedBackgroundIndex == index
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 32,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 이미지 타입 선택 버튼
  Widget _buildImageTypeButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 44,
      child: Material(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 갤러리에서 이미지 선택
  void _showGalleryPicker() {
    // TODO: image_picker 패키지를 사용한 갤러리 연결
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('갤러리 연결 기능을 준비 중입니다.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // 이미지로 공유
  Future<void> _shareAsImage() async {
    try {
      // RepaintBoundary로 위젯을 이미지로 캡처
      RenderRepaintBoundary boundary = _repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 웹에서 이미지 다운로드
      if (kIsWeb) {
        final blob = html.Blob([pngBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = '감동문_${_bookTitle ?? '책'}_${_getCurrentDate()}.png';
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('감동문 이미지가 다운로드되었습니다!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        // 모바일에서는 추후 share_plus 패키지 사용
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('모바일 공유 기능을 준비 중입니다.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      print('이미지 공유 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 생성에 실패했습니다.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // 감동문 저장
  Future<void> _saveReview() async {
    if (_generatedContent == null) return;
    
    // 로그인 상태 체크
    final authService = SupabaseAuthService();
    if (!authService.isLoggedIn) {
      // 로그인하지 않은 경우 임시 저장 후 로그인 페이지로 이동
      await _saveTempReview();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              '로그인이 필요해요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              '감동문을 저장하려면 로그인이 필요합니다.\n현재 내용은 임시 저장되었으니 안심하세요!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  '취소',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('로그인'),
              ),
            ],
          ),
        );
      }
      return;
    }
    
    try {
      final repository = ReviewRepository();
      final currentUser = authService.currentUserInfo;
      
      final review = Review(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser?.id ?? 'temp_user', // 실제 사용자 ID 사용
        title: '${_bookAuthor ?? '작가'}의 ${_bookTitle ?? '책'}을 읽고',
        content: _generatedContent!,
        bookTitle: _bookTitle ?? '책',
        bookAuthor: _bookAuthor,
        status: ReviewStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        chatHistory: widget.chatHistory,
      );

      await repository.create(review);
      
      // 임시 저장 데이터 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('temp_review');
      await prefs.remove('temp_book_title');
      await prefs.remove('temp_book_author');
      await prefs.remove('temp_chat_history');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('감동문이 저장되었습니다!'),
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
          content: Text('저장 중 오류가 발생했습니다: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}