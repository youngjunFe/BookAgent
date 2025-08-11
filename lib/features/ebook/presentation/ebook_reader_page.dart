import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../models/ebook.dart';

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

  @override
  void initState() {
    super.initState();
    _currentBook = widget.ebook;
    _pageController = PageController(initialPage: _currentBook.currentPage);
    
    // 3초 후 자동으로 컨트롤 숨기기
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
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
                
                // TODO: 진행률 저장
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
                        ],
                      ),
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


