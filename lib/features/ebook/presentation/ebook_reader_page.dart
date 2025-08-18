import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../models/ebook.dart';
import '../../review/presentation/review_creation_page.dart';
import '../../reading_goals/data/reading_goals_repository.dart';
import '../data/ebook_repository.dart';

class EBookReaderPage extends StatefulWidget {
  final EBook ebook;

  const EBookReaderPage({super.key, required this.ebook});

  @override
  State<EBookReaderPage> createState() => _EBookReaderPageState();
}

class _EBookReaderPageState extends State<EBookReaderPage> {
  late PageController _pageController;
  late EBook _currentBook;
  bool _showControls = true;
  double _fontSize = 16.0;
  Color _backgroundColor = AppColors.background;
  bool _isDarkMode = false;
  final _goalsRepository = ReadingGoalsRepository();
  final _ebookRepository = EBookRepository();

  @override
  void initState() {
    super.initState();
    _currentBook = widget.ebook;
    _pageController = PageController(initialPage: _currentBook.currentPage);
    _loadBookProgress();
    
    // 3초 후 자동으로 컨트롤 숨기기
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  Future<void> _loadBookProgress() async {
    try {
      // 데이터베이스에서 최신 진행률 불러오기
      final books = await _ebookRepository.list();
      final updatedBook = books.firstWhere(
        (b) => b.id == _currentBook.id,
        orElse: () => _currentBook,
      );
      
      setState(() {
        _currentBook = updatedBook;
      });
      
      // 저장된 페이지로 이동
      if (_currentBook.currentPage != 0) {
        _pageController.animateToPage(
          _currentBook.currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      
      print('📖 진행률 로드 완료: ${_currentBook.title} - ${_currentBook.currentPage}페이지 (${(_currentBook.progress * 100).toInt()}%)');
    } catch (e) {
      print('❌ 진행률 로드 실패: $e');
      // 에러 시 기본 페이지에서 시작 (이미 초기화됨)
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      // 3초 후 자동으로 숨기기
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _currentBook.pages.length) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _createReview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewCreationPage(
          bookTitle: _currentBook.title,
          bookAuthor: _currentBook.author,
        ),
      ),
    );
  }

  Future<void> _markAsCompleted() async {
    try {
      // 데이터베이스에 완독 상태 저장
      final completedBook = await _ebookRepository.markAsCompleted(_currentBook.id);
      setState(() {
        _currentBook = completedBook;
      });
      
      // 독서 완료 시 목표 진행률 업데이트
      _updateReadingProgress();
      
      // 완독 축하 다이얼로그 표시
      _showCompletionDialog();
      
      print('✅ 완독 처리 완료: ${_currentBook.title}');
    } catch (e) {
      print('❌ 완독 처리 실패: $e');
      // 실패해도 다이얼로그는 표시
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.celebration, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('완독 축하합니다! 🎉'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('축하합니다! "${_currentBook.title}"을(를) 완독하셨습니다!'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '완독 상태로 기록되었습니다',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '읽은 책에 대한 발제문을 작성해보시겠어요?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('나중에'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _createReview();
              },
              icon: const Icon(Icons.edit_note),
              label: const Text('발제문 작성'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveReadingProgress(int currentPage, int totalPages) async {
    try {
      final progress = (currentPage + 1) / totalPages;
      await _ebookRepository.updateProgress(
        id: _currentBook.id,
        currentPage: currentPage,
        progress: progress,
        lastReadAt: DateTime.now(),
      );
      print('📖 독서 진행률 저장 완료: ${_currentBook.title} - ${(progress * 100).toInt()}%');
    } catch (e) {
      print('❌ 독서 진행률 저장 실패: $e');
    }
  }

  void _updateReadingStatus() {
    // 읽는중 상태 알림 (선택사항)
    if (_currentBook.progress > 0 && _currentBook.progress < 1.0) {
      final percent = (_currentBook.progress * 100).toInt();
      print('📚 읽는중: ${_currentBook.title} - $percent% 완료');
    }
  }

  Future<void> _updateReadingProgress() async {
    try {
      // 책 완료: 1권, 페이지: 총 페이지 수, 독서시간: 추정 시간
      final totalPages = _currentBook.pages.length * 250; // 페이지당 평균 250단어 추정
      final estimatedReadingTime = (totalPages / 250 * 2).round(); // 페이지당 2분 추정
      
      await _goalsRepository.updateReadingProgress(
        booksCompleted: 1,
        pagesRead: totalPages,
        readingTimeMinutes: estimatedReadingTime,
      );
      
      print('독서 진행률 업데이트 완료: 책 1권, 페이지 $totalPages, 시간 ${estimatedReadingTime}분');
    } catch (e) {
      print('독서 진행률 업데이트 실패: $e');
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? AppColors.surface.withOpacity(0.9) : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSettingsSheet(),
    );
  }

  void _showTableOfContents() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? AppColors.surface.withOpacity(0.9) : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildTableOfContents(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _currentBook.pages;
    
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // 책 내용
            PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (page) {
                setState(() {
                  _currentBook = _currentBook.copyWith(
                    currentPage: page,
                    progress: (page + 1) / pages.length,
                    lastReadAt: DateTime.now(),
                  );
                });
                
                // 진행률을 실제 데이터베이스에 저장
                _saveReadingProgress(page, pages.length);
                
                // 마지막 페이지 도달 시 읽기 완료 처리
                if (page == pages.length - 1) {
                  _markAsCompleted();
                } else {
                  // 읽는중 상태 업데이트
                  _updateReadingStatus();
                }
                
                HapticFeedback.lightImpact();
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            pages[index],
                            style: TextStyle(
                              fontSize: _fontSize,
                              height: 1.6,
                              color: _isDarkMode ? Colors.white : AppColors.textPrimary,
                              fontFamily: 'Georgia', // 읽기 좋은 폰트
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 페이지 번호
                      Text(
                        '${index + 1} / ${pages.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: (_isDarkMode ? Colors.white : AppColors.textPrimary).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 상단 컨트롤바
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (_isDarkMode ? Colors.black : AppColors.surface).withOpacity(0.9),
                      (_isDarkMode ? Colors.black : AppColors.surface).withOpacity(0.0),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back,
                        color: _isDarkMode ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentBook.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _isDarkMode ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _currentBook.author,
                            style: TextStyle(
                              fontSize: 12,
                              color: (_isDarkMode ? Colors.white : AppColors.textPrimary).withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // 진행률 표시
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: _currentBook.progress,
                                  backgroundColor: (_isDarkMode ? Colors.white : AppColors.primary).withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _currentBook.isCompleted 
                                        ? AppColors.success 
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _currentBook.isCompleted 
                                    ? '완독' 
                                    : '${(_currentBook.progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _currentBook.isCompleted ? FontWeight.bold : FontWeight.normal,
                                  color: _currentBook.isCompleted 
                                      ? AppColors.success 
                                      : (_isDarkMode ? Colors.white : AppColors.textPrimary).withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                          if (!_currentBook.isCompleted && _currentBook.progress > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '읽는중 • ${_currentBook.currentPage + 1}/${pages.length} 페이지',
                              style: TextStyle(
                                fontSize: 10,
                                color: (_isDarkMode ? Colors.white : AppColors.textPrimary).withOpacity(0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // 발제문 작성 버튼
                    IconButton(
                      onPressed: _createReview,
                      icon: Icon(
                        Icons.edit_note,
                        color: AppColors.primary,
                      ),
                      tooltip: '발제문 작성',
                    ),
                    IconButton(
                      onPressed: _showTableOfContents,
                      icon: Icon(
                        Icons.list,
                        color: _isDarkMode ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: _showSettings,
                      icon: Icon(
                        Icons.settings,
                        color: _isDarkMode ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 컨트롤바
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      (_isDarkMode ? Colors.black : AppColors.surface).withOpacity(0.9),
                      (_isDarkMode ? Colors.black : AppColors.surface).withOpacity(0.0),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 진행률 표시
                    Row(
                      children: [
                        Text(
                          '${(_currentBook.progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: (_isDarkMode ? Colors.white : AppColors.textPrimary).withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _currentBook.progress,
                            backgroundColor: (_isDarkMode ? Colors.white : AppColors.textPrimary).withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_currentBook.currentPage + 1}/${_currentBook.pages.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: (_isDarkMode ? Colors.white : AppColors.textPrimary).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 네비게이션 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: _currentBook.currentPage > 0
                              ? () => _goToPage(_currentBook.currentPage - 1)
                              : null,
                          icon: Icon(
                            Icons.skip_previous,
                            color: _currentBook.currentPage > 0
                                ? (_isDarkMode ? Colors.white : AppColors.textPrimary)
                                : (_isDarkMode ? Colors.white : AppColors.textPrimary).withOpacity(0.3),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _goToPage(0),
                          icon: Icon(
                            Icons.first_page,
                            color: _isDarkMode ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: _currentBook.currentPage < _currentBook.pages.length - 1
                              ? () => _goToPage(_currentBook.currentPage + 1)
                              : null,
                          icon: Icon(
                            Icons.skip_next,
                            color: _currentBook.currentPage < _currentBook.pages.length - 1
                                ? (_isDarkMode ? Colors.white : AppColors.textPrimary)
                                : (_isDarkMode ? Colors.white : AppColors.textPrimary).withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '읽기 설정',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              
              // 폰트 크기
              Text(
                '폰트 크기',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _fontSize > 12 ? () {
                      setSheetState(() {
                        _fontSize -= 2;
                      });
                      setState(() {});
                    } : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 6,
                      label: '${_fontSize.toInt()}pt',
                      onChanged: (value) {
                        setSheetState(() {
                          _fontSize = value;
                        });
                        setState(() {});
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: _fontSize < 24 ? () {
                      setSheetState(() {
                        _fontSize += 2;
                      });
                      setState(() {});
                    } : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // 다크 모드
              SwitchListTile(
                title: const Text('다크 모드'),
                subtitle: const Text('어두운 배경으로 눈의 피로를 줄입니다'),
                value: _isDarkMode,
                onChanged: (value) {
                  setSheetState(() {
                    _isDarkMode = value;
                    _backgroundColor = value ? Colors.black : AppColors.background;
                  });
                  setState(() {});
                },
              ),
              
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableOfContents() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '목차',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          if (_currentBook.chapters.isNotEmpty) ...[
            for (int i = 0; i < _currentBook.chapters.length; i++)
              ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                title: Text(_currentBook.chapters[i]),
                onTap: () {
                  Navigator.of(context).pop();
                  // 챕터별 페이지로 이동 (간단 구현: 전체 페이지를 챕터 수로 나눔)
                  final pagePerChapter = (_currentBook.pages.length / _currentBook.chapters.length).floor();
                  _goToPage(i * pagePerChapter);
                },
              ),
          ] else ...[
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('목차 정보가 없습니다'),
              subtitle: Text('이 책에는 장별 구분이 설정되지 않았습니다.'),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // 페이지별 이동
          Text(
            '페이지로 이동',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _currentBook.currentPage.toDouble(),
                  min: 0,
                  max: (_currentBook.pages.length - 1).toDouble(),
                  divisions: _currentBook.pages.length - 1,
                  label: '${_currentBook.currentPage + 1}페이지',
                  onChanged: (value) {
                    _goToPage(value.toInt());
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}


