import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/login_page.dart';
import '../../../shared/widgets/main_navigation.dart';
import '../../chat/presentation/ai_chat_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GuestDemoPage extends StatefulWidget {
  final BookSearchResult? selectedBook;
  
  const GuestDemoPage({super.key, this.selectedBook});

  @override
  State<GuestDemoPage> createState() => _GuestDemoPageState();
}

class _GuestDemoPageState extends State<GuestDemoPage> {
  final TextEditingController _searchController = TextEditingController();
  List<BookSearchResult> _searchResults = [];
  BookSearchResult? _selectedBook;
  bool _isSearching = false;
  int _currentStep = 0; // 0: 검색, 1: AI 대화, 2: 발제문 생성
  String _generatedReview = '';
  String _chatHistory = '';
  
  @override
  void initState() {
    super.initState();
    if (widget.selectedBook != null) {
      _selectedBook = widget.selectedBook;
      _currentStep = 1; // 책이 선택된 상태로 시작하면 AI 대화 단계로
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '둘러보기 데모',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: Text(
              '로그인',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBookSearch();
      case 1:
        return _buildAiChat();
      case 2:
        return _buildReviewGeneration();
      default:
        return _buildBookSearch();
    }
  }

  Widget _buildBookSearch() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '어떤 책을 읽으셨나요?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // 검색 입력창
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '책 제목이나 저자명을 입력하세요',
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: _isSearching 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.search),
                  onPressed: _searchBooks,
                ),
              ),
              onSubmitted: (_) => _searchBooks(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 검색 결과
          Expanded(
            child: _searchResults.isEmpty
              ? Center(
                  child: Text(
                    '책을 검색해보세요',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final book = _searchResults[index];
                    return _buildBookItem(book);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookItem(BookSearchResult book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: InkWell(
        onTap: () => _selectBook(book),
        child: Row(
          children: [
            // 책 표지
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.book,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            
            // 책 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.publisher,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textHint,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiChat() {
    // 실제 AI 채팅 페이지를 임베드
    return AiChatPage(
      initialContext: '선택한 책: ${_selectedBook?.title} (${_selectedBook?.author})\n\n이 책에 대해 대화해보세요!',
      bookTitle: _selectedBook?.title ?? '선택한 책',
      isGuestMode: true,
      onChatComplete: () {
        // AI 대화 완료 후 발제문 생성 단계로
        _generateReviewFromChat();
      },
    );
  }

  Future<void> _generateReviewFromChat() async {
    setState(() {
      _currentStep = 2;
      _generatedReview = ''; // 로딩 상태
    });

    try {
      // 실제 AI 발제문 생성 API 호출
      final response = await http.post(
        Uri.parse('https://bookagent-production.up.railway.app/api/generate-review'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'bookTitle': _selectedBook?.title ?? '',
          'content': '게스트 모드에서 생성된 발제문',
          'chatHistory': _chatHistory.isNotEmpty ? _chatHistory : '${_selectedBook?.title}에 대한 AI 대화 내용',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _generatedReview = data['review'] ?? '발제문 생성에 실패했습니다.';
        });
      } else {
        setState(() {
          _generatedReview = '발제문 생성에 실패했습니다. 다시 시도해주세요.';
        });
      }
    } catch (e) {
      setState(() {
        _generatedReview = '네트워크 오류로 발제문 생성에 실패했습니다.';
      });
      print('Review generation error: $e');
    }
  }

  Widget _buildReviewGeneration() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            _generatedReview.isEmpty ? '발제문 생성 중...' : '발제문이 생성되었습니다!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _generatedReview.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AI가 대화 내용을 바탕으로\n발제문을 생성하고 있습니다...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      // 전체 발제문 (블러 처리됨)
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 미리보기 영역 (처음 두 줄)
                            Text(
                              _getPreviewText(),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            
                            // 블러 처리된 나머지 내용
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              child: Stack(
                                children: [
                                  Text(
                                    _getBlurredText(),
                                    style: TextStyle(
                                      color: AppColors.textSecondary.withOpacity(0.3),
                                      fontSize: 16,
                                      height: 1.5,
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
                                          AppColors.surface.withOpacity(0.1),
                                          AppColors.surface.withOpacity(0.9),
                                          AppColors.surface,
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
                                    '전체 발제문을 확인하려면',
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
                        ),
                      ),
                    ],
                  ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 임시저장 및 로그인 버튼들 (발제문이 생성된 경우에만 표시)
          if (_generatedReview.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saveTemporarily,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      minimumSize: const Size(0, 56),
                    ),
                    child: Text(
                      '임시저장',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _quickSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 56),
                    ),
                    child: const Text(
                      '3초만에 가입하기',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // 발제문 생성 전에는 다시 시작/메인 이동 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep = 0;
                        _selectedBook = null;
                        _searchResults.clear();
                        _searchController.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      minimumSize: const Size(0, 56),
                    ),
                    child: Text(
                      '다시 시작',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const MainNavigation()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 56),
                    ),
                    child: const Text(
                      '메인으로 이동',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _searchBooks() async {
    if (_searchController.text.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://bookagent-production.up.railway.app/api/search-books?query=${_searchController.text}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final books = (data['books'] as List)
            .map((book) => BookSearchResult.fromJson(book))
            .toList();
        
        setState(() {
          _searchResults = books;
        });
      }
    } catch (e) {
      print('Search error: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectBook(BookSearchResult book) {
    setState(() {
      _selectedBook = book;
      _currentStep = 1;
    });
  }

  String _getPreviewText() {
    if (_generatedReview.isEmpty) return '';
    
    final lines = _generatedReview.split('\n');
    final previewLines = lines.take(2).toList();
    return previewLines.join('\n');
  }

  String _getBlurredText() {
    if (_generatedReview.isEmpty) return '';
    
    final lines = _generatedReview.split('\n');
    if (lines.length <= 2) return '';
    
    final remainingLines = lines.skip(2).toList();
    return remainingLines.join('\n');
  }

  Future<void> _saveTemporarily() async {
    try {
      // SharedPreferences에 임시 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_review', _generatedReview);
      await prefs.setString('temp_book_title', _selectedBook?.title ?? '');
      await prefs.setString('temp_book_author', _selectedBook?.author ?? '');
      await prefs.setString('temp_chat_history', _chatHistory);
      
      // 저장 완료 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('발제문이 임시 저장되었습니다!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // 로그인 페이지로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('임시 저장에 실패했습니다.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _quickSignUp() {
    // 3초만에 가입하기도 임시저장 후 로그인 페이지로
    _saveTemporarily();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class BookSearchResult {
  final String title;
  final String author;
  final String publisher;
  final String image;
  final String description;
  final String isbn;

  BookSearchResult({
    required this.title,
    required this.author,
    required this.publisher,
    required this.image,
    required this.description,
    required this.isbn,
  });

  factory BookSearchResult.fromJson(Map<String, dynamic> json) {
    return BookSearchResult(
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      publisher: json['publisher'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      isbn: json['isbn'] ?? '',
    );
  }
}
