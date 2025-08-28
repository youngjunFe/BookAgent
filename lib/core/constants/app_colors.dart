import 'package:flutter/material.dart';

class AppColors {
  // ✨ "사유의 온기" 디자인 시스템 색상 팔레트
  
  // === Solid Colors ===
  
  // Primary Colors - Ink Blue (디지털 플랫폼의 안정성과 지속적인 신뢰감)
  static const Color primary = Color(0xFF3D7486); // Ink Blue 500
  static const Color primaryLight = Color(0xFFAEC9E6); // Ink Blue 300
  static const Color primaryDark = Color(0xFF1C3A50); // Ink Blue 900
  static const Color primarySurface = Color(0xFFE2EAF4); // Ink Blue 100
  
  // Secondary Colors - Brick Red (창작욕과 감성을 자극)
  static const Color secondary = Color(0xFFDF452C); // Brick Red 500
  static const Color secondaryLight = Color(0xFFF29F90); // Brick Red 300
  static const Color secondaryDark = Color(0xFF8C2616); // Brick Red 900
  static const Color secondarySurface = Color(0xFFFBE3DE); // Brick Red 100
  
  // Tertiary Colors - Clay (사유의 온기)
  static const Color tertiary = Color(0xFFEAC8A6); // Clay 500
  static const Color tertiaryLight = Color(0xFFF8F50E); // Clay 300
  static const Color tertiaryDark = Color(0xFFB18861); // Clay 900
  static const Color tertiarySurface = Color(0xFFFDFCF9); // Clay 100
  
  // === Background Colors - Neutral ===
  static const Color background = Color(0xFFFEFEFE); // Neutral 50
  static const Color surface = Color(0xFFFCFCFC); // Neutral 100
  static const Color surfaceVariant = Color(0xFFF5F5F5); // Neutral 300
  static const Color surfaceBright = Color(0xFFFBFBFA); // Neutral 200
  static const Color surfaceDim = Color(0xFFEEEEEE); // Neutral 400
  
  // === Text Colors ===
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onTertiary = Color(0xFF212121);
  static const Color onBackground = Color(0xFF212121); // Neutral 800
  static const Color onSurface = Color(0xFF212121); // Neutral 800
  static const Color onSurfaceVariant = Color(0xFF757575); // Neutral 600
  
  // Neutral Text Colors
  static const Color textPrimary = Color(0xFF212121); // Neutral 800
  static const Color textSecondary = Color(0xFF757575); // Neutral 600
  static const Color textHint = Color(0xFFBDBDBD); // Neutral 500
  static const Color textDisabled = Color(0xFF3D3D3D); // Neutral 700
  
  // === Functional Colors ===
  static const Color success = Color(0xFF66BB6A); // Success 500
  static const Color successLight = Color(0xFFB5E0C3); // Success 300
  static const Color successDark = Color(0xFF0D6C14); // Success 900
  static const Color successSurface = Color(0xFFE7F6ED); // Success 100
  
  static const Color warning = Color(0xFFFFD453); // Warning 500
  static const Color warningLight = Color(0xFFFFE699); // Warning 300
  static const Color warningDark = Color(0xFFF2AD00); // Warning 900
  static const Color warningSurface = Color(0xFFFFF8E1); // Warning 100
  
  static const Color error = Color(0xFFF2483F); // Error 500
  static const Color errorLight = Color(0xFFFFACAC); // Error 300
  static const Color errorDark = Color(0xFFB71C1C); // Error 900
  static const Color errorSurface = Color(0xFFFFE5E3); // Error 100
  
  static const Color info = Color(0xFF2196F3); // Blue 500
  static const Color infoLight = Color(0xFF90CAF9); // Blue 300
  static const Color infoDark = Color(0xFF0D47A1); // Blue 900
  static const Color infoSurface = Color(0xFFE3F2FD); // Blue 100
  
  // === Accent Colors (카테고리별 특별한 색상) ===
  static const Color accentSageGreen = Color(0xFFB2C5B2); // 핵심 UI나 아이콘, 태그
  static const Color accentBurgundy = Color(0xFF8C263A); // 배경 포인트 등
  static const Color accentLemonZest = Color(0xFFFDEEAA); // 100/30/15% 투명도 활용
  static const Color accentSteelBlue = Color(0xFFA7BFDE);
  static const Color accentLavenderPurple = Color(0xFFD0C2E8);
  
  // === Card & Divider Colors ===
  static const Color cardColor = Color(0xFFFCFCFC); // Neutral 100
  static const Color dividerColor = Color(0xFFEEEEEE); // Neutral 400
  static const Color borderColor = Color(0xFFBDBDBD); // Neutral 500
  
  // === Navigation & Tab Colors ===
  static const Color navigationBackground = Color(0xFFFCFCFC); // Neutral 100
  static const Color selectedTab = Color(0xFF3D7486); // Primary
  static const Color unselectedTab = Color(0xFF757575); // Neutral 600
  
  // === Book Status Colors (독서 상태별) ===
  static const Color wantToRead = Color(0xFFEAC8A6); // Tertiary - 읽고싶은
  static const Color reading = Color(0xFF3D7486); // Primary - 읽고있는
  static const Color completed = Color(0xFF66BB6A); // Success - 완독한
  static const Color paused = Color(0xFFFFD453); // Warning - 쉬고있는
  
  // === Review Status Colors (발제문 상태별) ===
  static const Color draft = Color(0xFFB2C5B2); // Accent Sage Green - 초안
  static const Color completedReview = Color(0xFF66BB6A); // Success - 완료
  static const Color published = Color(0xFF2196F3); // Info - 게시
}

