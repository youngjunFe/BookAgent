import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BackgroundSelectionPage extends StatefulWidget {
  final Function(String) onSelected;

  const BackgroundSelectionPage({
    super.key,
    required this.onSelected,
  });

  @override
  State<BackgroundSelectionPage> createState() => _BackgroundSelectionPageState();
}

class _BackgroundSelectionPageState extends State<BackgroundSelectionPage> {
  String? _selectedBackground;

  // 더미 배경 이미지 데이터
  final List<BackgroundOption> _backgrounds = [
    BackgroundOption(
      id: 'book_vintage',
      name: '빈티지 책',
      description: '따뜻한 느낌의 빈티지 책 배경',
      category: '클래식',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD4A574), Color(0xFF8B4513)],
      ),
    ),
    BackgroundOption(
      id: 'library_cozy',
      name: '아늑한 도서관',
      description: '책으로 둘러싸인 편안한 공간',
      category: '클래식',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF654321), Color(0xFF2F1B14)],
      ),
    ),
    BackgroundOption(
      id: 'nature_forest',
      name: '숲속 독서',
      description: '자연 속에서 책을 읽는 느낌',
      category: '자연',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF228B22), Color(0xFF006400)],
      ),
    ),
    BackgroundOption(
      id: 'sunset_reading',
      name: '황혼 독서',
      description: '노을이 지는 하늘과 함께',
      category: '자연',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
      ),
    ),
    BackgroundOption(
      id: 'coffee_minimal',
      name: '커피와 책',
      description: '심플하고 깔끔한 카페 분위기',
      category: '모던',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5F5DC), Color(0xFFDEB887)],
      ),
    ),
    BackgroundOption(
      id: 'night_study',
      name: '밤의 서재',
      description: '조용한 밤 독서 시간',
      category: '모던',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF191970), Color(0xFF000080)],
      ),
    ),
    BackgroundOption(
      id: 'spring_garden',
      name: '봄날의 정원',
      description: '꽃이 피는 정원에서',
      category: '자연',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFB6C1), Color(0xFF98FB98)],
      ),
    ),
    BackgroundOption(
      id: 'geometric_modern',
      name: '기하학적 모던',
      description: '현대적이고 세련된 디자인',
      category: '모던',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4169E1), Color(0xFF1E90FF)],
      ),
    ),
  ];

  List<String> get _categories {
    return _backgrounds.map((bg) => bg.category).toSet().toList()..insert(0, '전체');
  }

  String _selectedCategory = '전체';

  List<BackgroundOption> get _filteredBackgrounds {
    if (_selectedCategory == '전체') {
      return _backgrounds;
    }
    return _backgrounds.where((bg) => bg.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('배경 이미지 선택'),
        backgroundColor: AppColors.background,
        elevation: 1,
        shadowColor: AppColors.dividerColor,
        actions: [
          TextButton(
            onPressed: _selectedBackground != null ? _confirmSelection : null,
            child: Text(
              '완료',
              style: TextStyle(
                color: _selectedBackground != null 
                    ? AppColors.primary 
                    : AppColors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 필터
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.dividerColor,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 배경 이미지 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _filteredBackgrounds.length,
              itemBuilder: (context, index) {
                final background = _filteredBackgrounds[index];
                final isSelected = background.id == _selectedBackground;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedBackground = background.id;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primary 
                            : AppColors.dividerColor,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        children: [
                          // 배경 그라디언트
                          Container(
                            decoration: BoxDecoration(
                              gradient: background.gradient,
                            ),
                          ),
                          
                          // 오버레이 패턴 (선택적)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                          
                          // 선택 표시
                          if (isSelected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          
                          // 제목과 설명
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    background.name,
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    background.description,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 하단 안내
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              '배경 이미지를 선택하면 발제문이 더욱 아름답게 꾸며집니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedBackground != null) {
      widget.onSelected(_selectedBackground!);
      Navigator.of(context).pop();
    }
  }
}

class BackgroundOption {
  final String id;
  final String name;
  final String description;
  final String category;
  final LinearGradient gradient;

  BackgroundOption({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.gradient,
  });
}





