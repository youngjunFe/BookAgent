import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/services/supabase_auth_service.dart';
import 'settings_page.dart';
import 'profile_edit_page.dart';

class MyPageV2 extends StatelessWidget {
  const MyPageV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.myPage),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _ProfileHeader(),
            SizedBox(height: 32),
            _SectionTitle('나의 책장'),
            SizedBox(height: 12),
            _BookshelfSection(),
            SizedBox(height: 32),
            _SectionTitle('나의 대화'),
            SizedBox(height: 12),
            _NotesSection(),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SupabaseAuthService().getSafeCurrentUserInfo(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.person, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                user?.nickname ?? '게스트',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileEditPage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                side: BorderSide(color: AppColors.dividerColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('수정'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _BookshelfSection extends StatelessWidget {
  const _BookshelfSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 책장 선반
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (index) => _BookSpine(
                  title: _getBookTitle(index),
                  color: _getBookColor(index),
                  height: _getBookHeight(index),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBookTitle(int index) {
    final titles = ['해리포터', '반지의제왕', '어린왕자', '1984', '위대한개츠비', '데미안'];
    return titles[index % titles.length];
  }

  Color _getBookColor(int index) {
    final colors = [
      const Color(0xFF8B0000), // 다크레드
      const Color(0xFF2F4F4F), // 다크그레이
      const Color(0xFF4169E1), // 로얄블루
      const Color(0xFF228B22), // 포레스트그린
      const Color(0xFF800080), // 퍼플
      const Color(0xFFB8860B), // 다크골드
    ];
    return colors[index % colors.length];
  }

  double _getBookHeight(int index) {
    final heights = [140.0, 120.0, 135.0, 125.0, 130.0, 145.0];
    return heights[index % heights.length];
  }
}

class _BookSpine extends StatelessWidget {
  final String title;
  final Color color;
  final double height;

  const _BookSpine({
    required this.title,
    required this.color,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: height,
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(2),
          topRight: Radius.circular(2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(1, 0),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color,
            color.withOpacity(0.8),
            color,
          ],
          stops: const [0.0, 0.1, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 책 등뼈의 세로 라인들
          Positioned(
            left: 2,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          Positioned(
            right: 2,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1,
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          // 책 제목 (세로로 회전)
          Positioned.fill(
            child: Center(
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ChatNoteCard(
              character: '해리포터',
              message: '마법의 세계에 대해 이야기해봐요! 호그와트에서의 모험이 궁금해요.',
              color: const Color(0xFFFFF7CC),
              characterColor: const Color(0xFF8B0000),
            ),
            _ChatNoteCard(
              character: '셜록홈즈',
              message: '추리의 기술에 대해 알려드릴까요? 관찰력이 중요합니다.',
              color: const Color(0xFFE8F4FD),
              characterColor: const Color(0xFF2F4F4F),
            ),
            _ChatNoteCard(
              character: '어린왕자',
              message: '정말 중요한 것은 눈에 보이지 않아요. 마음으로 봐야 해요.',
              color: const Color(0xFFF0E6FF),
              characterColor: const Color(0xFF800080),
            ),
            _ChatNoteCard(
              character: '앨리스',
              message: '이상한 나라에서의 모험담을 들려드릴게요!',
              color: const Color(0xFFE8F8E8),
              characterColor: const Color(0xFF228B22),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatNoteCard extends StatelessWidget {
  final String character;
  final String message;
  final Color color;
  final Color characterColor;

  const _ChatNoteCard({
    required this.character,
    required this.message,
    required this.color,
    required this.characterColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 캐릭터 이름
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: characterColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: characterColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              character,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: characterColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 대화 내용
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary.withOpacity(0.8),
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Color color;
  const _NoteCard({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              '예시 대화 내용이 여기에 표시됩니다. 길이에 따라 줄바꿈됩니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


