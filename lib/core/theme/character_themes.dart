import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CharacterTheme {
  final Color primaryColor;
  final Color backgroundColor;
  final Color messageColor;
  final Color accentColor;
  final String emoji;
  final LinearGradient gradient;
  
  const CharacterTheme({
    required this.primaryColor,
    required this.backgroundColor,
    required this.messageColor,
    required this.accentColor,
    required this.emoji,
    required this.gradient,
  });
}

class CharacterThemes {
  static const Map<String, CharacterTheme> themes = {
    '해리 포터': CharacterTheme(
      primaryColor: Color(0xFF7B2D8E), // 마법의 보라색
      backgroundColor: Color(0xFFF3E5F5),
      messageColor: Color(0xFFE1BEE7),
      accentColor: Color(0xFFFFD700), // 골드
      emoji: '🪄',
      gradient: LinearGradient(
        colors: [Color(0xFF7B2D8E), Color(0xFF9C27B0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    
    '셜록 홈즈': CharacterTheme(
      primaryColor: Color(0xFF1A237E), // 짙은 파랑
      backgroundColor: Color(0xFFE8EAF6),
      messageColor: Color(0xFFC5CAE9),
      accentColor: Color(0xFF4FC3F7), // 하늘색
      emoji: '🔍',
      gradient: LinearGradient(
        colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    
    '엘리자베스 베넷': CharacterTheme(
      primaryColor: Color(0xFFAD1457), // 로맨틱 핑크
      backgroundColor: Color(0xFFFCE4EC),
      messageColor: Color(0xFFF8BBD9),
      accentColor: Color(0xFFFF4081), // 선명한 핑크
      emoji: '💕',
      gradient: LinearGradient(
        colors: [Color(0xFFAD1457), Color(0xFFE91E63)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    
    '아라곤': CharacterTheme(
      primaryColor: Color(0xFF2E7D32), // 포레스트 그린
      backgroundColor: Color(0xFFE8F5E8),
      messageColor: Color(0xFFC8E6C9),
      accentColor: Color(0xFFFFB300), // 골드
      emoji: '⚔️',
      gradient: LinearGradient(
        colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    
    '김춘삼': CharacterTheme(
      primaryColor: Color(0xFFE65100), // 따뜻한 오렌지
      backgroundColor: Color(0xFFFFF3E0),
      messageColor: Color(0xFFFFE0B2),
      accentColor: Color(0xFFFF9800), // 밝은 오렌지
      emoji: '🌟',
      gradient: LinearGradient(
        colors: [Color(0xFFE65100), Color(0xFFFF9800)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  };
  
  // 기본 테마 (캐릭터가 없을 때)
  static const CharacterTheme defaultTheme = CharacterTheme(
    primaryColor: AppColors.primary,
    backgroundColor: AppColors.background,
    messageColor: AppColors.surface,
    accentColor: AppColors.secondary,
    emoji: '📚',
    gradient: LinearGradient(
      colors: [AppColors.primary, AppColors.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
  
  // 캐릭터별 테마 가져오기
  static CharacterTheme getTheme(String characterName) {
    return themes[characterName] ?? defaultTheme;
  }
  
  // 캐릭터 테마로 ThemeData 생성
  static ThemeData createCharacterTheme(String characterName, ThemeData baseTheme) {
    final characterTheme = getTheme(characterName);
    
    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: characterTheme.primaryColor,
        surface: characterTheme.backgroundColor,
      ),
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: characterTheme.backgroundColor,
        foregroundColor: characterTheme.primaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: characterTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
