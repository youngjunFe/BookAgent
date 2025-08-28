import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'elevation_levels.dart';

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        // Primary - Ink Blue (사유의 온기)
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primarySurface,
        onPrimaryContainer: AppColors.primaryDark,
        
        // Secondary - Brick Red (창작욕과 감성)
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondarySurface,
        onSecondaryContainer: AppColors.secondaryDark,
        
        // Tertiary - Clay (따뜻한 사유)
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiarySurface,
        onTertiaryContainer: AppColors.tertiaryDark,
        
        // Surface & Background - Neutral
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        surfaceTint: AppColors.primary,
        
        // Functional Colors
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.errorSurface,
        onErrorContainer: AppColors.errorDark,
        
        // System Colors
        outline: AppColors.borderColor,
        outlineVariant: AppColors.dividerColor,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: AppColors.textPrimary,
        onInverseSurface: AppColors.background,
        inversePrimary: AppColors.primaryLight,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      
      // Text Theme - Pretendard 폰트 시스템 (디자인 시스템 정확 매핑)
      textTheme: const TextTheme(
        // Display 레벨 - 가장 큰 텍스트
        displayLarge: TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.w600, // SemiBold
          color: AppColors.textPrimary,
          height: 70/64, // 70px line height
          letterSpacing: -0.02, // -0.02em
        ),
        displayMedium: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w600, // SemiBold
          color: AppColors.textPrimary,
          height: 54/48, // 54px line height
          letterSpacing: -0.02, // -0.02em (-1px)
        ),
        displaySmall: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w600, // SemiBold
          color: AppColors.textPrimary,
          height: 46/40, // 46px line height
          letterSpacing: -0.02, // -0.02em (-0.8px)
        ),
        
        // Headline 레벨 - 주요 제목
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600, // SemiBold
          color: AppColors.textPrimary,
          height: 40/32, // 40px line height
          letterSpacing: -0.01, // -0.01em (-0.4px)
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600, // SemiBold
          color: AppColors.textPrimary,
          height: 36/28, // 36px line height
          letterSpacing: -0.01, // -0.01em (-0.3px)
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600, // SemiBold
          color: AppColors.textPrimary,
          height: 32/24, // 32px line height
          letterSpacing: -0.01, // -0.01em (-0.25px)
        ),
        
        // Title 레벨 - 섹션 제목
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600, // SemiBold
          color: AppColors.textPrimary,
          height: 28/20, // 28px line height
          letterSpacing: -0.01, // -0.01em (-0.2px)
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600, // SemiBold
          color: AppColors.textPrimary,
          height: 24/18, // 24px line height
          letterSpacing: -0.01, // -0.01em (-0.18px)
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600, // SemiBold
          color: AppColors.textPrimary,
          height: 20/14, // 20px line height
          letterSpacing: -0.01, // -0.01em (-0.15px)
        ),
        
        // Body 레벨 - 본문 텍스트
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400, // Regular
          color: AppColors.textPrimary,
          height: 24/16, // 24px line height
          letterSpacing: 0, // 0em
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400, // Regular
          color: AppColors.textPrimary,
          height: 22/14, // 22px line height
          letterSpacing: 0, // 0em
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400, // Regular
          color: AppColors.textSecondary,
          height: 18/12, // 18px line height
          letterSpacing: 0, // 0em
        ),
        
        // Label 레벨 - 레이블, 버튼 텍스트
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500, // Medium
          color: AppColors.textPrimary,
          height: 18/14, // 18px line height
          letterSpacing: -0.01, // -0.01em (-0.14px)
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500, // Medium
          color: AppColors.textSecondary,
          height: 16/12, // 16px line height
          letterSpacing: -0.01, // -0.01em (-0.12px)
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500, // Medium
          color: AppColors.textHint,
          height: 14/10, // 14px line height
          letterSpacing: -0.01, // -0.01em
        ),
      ),
      
      // Button Themes - State Layer 투명도 시스템 적용
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              // Pressed 상태: opacity-0.10 (10%)
              return AppColors.primary.withOpacity(0.90);
            }
            if (states.contains(MaterialState.hovered)) {
              // Hover 상태: opacity-0.08 (8%)  
              return AppColors.primary.withOpacity(0.92);
            }
            if (states.contains(MaterialState.focused)) {
              // Focus 상태: opacity-0.10 (10%)
              return AppColors.primary.withOpacity(0.90);
            }
            if (states.contains(MaterialState.selected) || 
                states.contains(MaterialState.dragged)) {
              // Selected/Dragged 상태: opacity-0.16 (16%)
              return AppColors.primary.withOpacity(0.84);
            }
            return AppColors.primary;
          }),
          foregroundColor: MaterialStateProperty.all(AppColors.onPrimary),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          elevation: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              // Pressed: Level1 (1dp) - 낮은 강조
              return ElevationLevels.getFlutterElevation(1);
            }
            if (states.contains(MaterialState.hovered)) {
              // Hover: Level3 (6dp) - 높은 강조
              return ElevationLevels.getFlutterElevation(3);
            }
            if (states.contains(MaterialState.focused)) {
              // Focus: Level2 (3dp) - 중간 강조
              return ElevationLevels.getFlutterElevation(2);
            }
            // Default: Level2 (3dp) - 기본 버튼 상태
            return ElevationLevels.getFlutterElevation(2);
          }),
          textStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Card Theme - Level1 (1dp) 기본 카드 elevation
      cardTheme: CardThemeData(
        color: AppColors.cardColor,
        surfaceTintColor: AppColors.primary,
        elevation: ElevationLevels.getFlutterElevation(1), // Level1 (1dp)
        shadowColor: Colors.black,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: const EdgeInsets.all(8),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        helperStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 12,
        ),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontSize: 12,
        ),
      ),
      
      // Bottom Navigation Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navigationBackground,
        selectedItemColor: AppColors.selectedTab,
        unselectedItemColor: AppColors.unselectedTab,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      
      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.selectedTab,
        unselectedLabelColor: AppColors.unselectedTab,
        indicatorColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerColor,
        thickness: 1,
        space: 1,
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: AppColors.background,
    );

    // 디자인 시스템 - Pretendard 폰트 적용 (웹 폰트 직접 로드)
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: 'Pretendard',
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: 'Pretendard',
      ),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }
}
