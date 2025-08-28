class AppSpacing {
  // 기본 간격 단위 (8px 기반)
  static const double unit = 8.0;
  
  // 간격 스케일
  static const double xs = unit * 0.5;    // 4px
  static const double sm = unit;          // 8px  
  static const double md = unit * 2;      // 16px
  static const double lg = unit * 3;      // 24px
  static const double xl = unit * 4;      // 32px
  static const double xxl = unit * 6;     // 48px
  static const double xxxl = unit * 8;    // 64px
  
  // 특정 용도별 간격
  static const double cardPadding = md;       // 16px
  static const double screenPadding = md;    // 16px
  static const double sectionSpacing = lg;   // 24px
  static const double itemSpacing = sm;      // 8px
  static const double buttonSpacing = md;    // 16px
  
  // 보더 반지름
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  
  // 아이콘 크기
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;
  
  // 그림자 높이
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double elevationVeryHigh = 16.0;
}
