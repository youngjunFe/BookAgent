import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../models/character.dart';
import 'character_chat_page.dart';

class CharacterSelectionPage extends StatefulWidget {
  const CharacterSelectionPage({super.key});

  @override
  State<CharacterSelectionPage> createState() => _CharacterSelectionPageState();
}

class _CharacterSelectionPageState extends State<CharacterSelectionPage> {
  String _selectedGenre = '전체';
  final List<String> _genres = ['전체', '소설', '판타지', '로맨스', '추리', '역사'];

  // 더미 캐릭터 데이터
  final List<Character> _characters = [
    Character(
      id: '1',
      name: '해리 포터',
      bookTitle: '해리 포터와 마법사의 돌',
      author: 'J.K. 롤링',
      genre: '판타지',
      personality: '용감하고 정의로우며, 친구들을 아끼는 마음이 깊습니다.',
      description: '호그와트 마법학교의 학생으로, 볼드모트와 맞서 싸우는 소년 마법사입니다.',
      imageUrl: null,
      popularityScore: 95,
    ),
    Character(
      id: '2',
      name: '셜록 홈즈',
      bookTitle: '셜록 홈즈의 모험',
      author: '아서 코난 도일',
      genre: '추리',
      personality: '논리적이고 예리한 추리력을 가지고 있으며, 때로는 냉정합니다.',
      description: '런던 베이커가 221B에 거주하는 세계 최고의 사설 탐정입니다.',
      imageUrl: null,
      popularityScore: 92,
    ),
    Character(
      id: '3',
      name: '엘리자베스 베넷',
      bookTitle: '오만과 편견',
      author: '제인 오스틴',
      genre: '로맨스',
      personality: '똑똑하고 독립적이며, 자신의 신념을 굽히지 않는 강한 여성입니다.',
      description: '19세기 영국의 젊은 여성으로, 진정한 사랑을 찾아가는 이야기의 주인공입니다.',
      imageUrl: null,
      popularityScore: 88,
    ),
    Character(
      id: '4',
      name: '아라곤',
      bookTitle: '반지의 제왕',
      author: 'J.R.R. 톨킨',
      genre: '판타지',
      personality: '고귀하고 용감하며, 책임감이 강한 리더십을 가지고 있습니다.',
      description: '곤도르의 왕이 될 운명을 가진 레인저이자 전사입니다.',
      imageUrl: null,
      popularityScore: 90,
    ),
    Character(
      id: '5',
      name: '김춘삼',
      bookTitle: '김춘삼의 모험',
      author: '현진건',
      genre: '소설',
      personality: '순진하고 낙천적이며, 모험심이 강합니다.',
      description: '한국 근대 문학의 대표적인 인물로, 새로운 세상에 대한 꿈을 가지고 있습니다.',
      imageUrl: null,
      popularityScore: 75,
    ),
  ];

  List<Character> get _filteredCharacters {
    if (_selectedGenre == '전체') {
      return _characters;
    }
    return _characters.where((character) => character.genre == _selectedGenre).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.selectCharacter),
        backgroundColor: AppColors.background,
        elevation: 1,
        shadowColor: AppColors.dividerColor,
      ),
      body: Column(
        children: [
          // 장르 필터
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '장르별 캐릭터',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _genres.length,
                    itemBuilder: (context, index) {
                      final genre = _genres[index];
                      final isSelected = genre == _selectedGenre;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(genre),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedGenre = genre;
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
              ],
            ),
          ),
          
          // 캐릭터 리스트
          Expanded(
            child: _filteredCharacters.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCharacters.length,
                    itemBuilder: (context, index) {
                      return _CharacterCard(
                        character: _filteredCharacters[index],
                        onTap: () => _startChatWithCharacter(_filteredCharacters[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            '해당 장르의 캐릭터가 없습니다',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 장르를 선택해보세요!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  void _startChatWithCharacter(Character character) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CharacterChatPage(character: character),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final Character character;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.character,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 캐릭터 아바타
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getCharacterColor(character.genre),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      character.name[0],
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 캐릭터 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              character.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getCharacterColor(character.genre).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              character.genre,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getCharacterColor(character.genre),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        '${character.bookTitle} - ${character.author}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        character.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '인기도 ${character.popularityScore}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '대화하기',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCharacterColor(String genre) {
    switch (genre) {
      case '판타지':
        return Colors.purple;
      case '로맨스':
        return Colors.pink;
      case '추리':
        return Colors.indigo;
      case '역사':
        return Colors.brown;
      case '소설':
        return AppColors.primary;
      default:
        return AppColors.secondary;
    }
  }
}

