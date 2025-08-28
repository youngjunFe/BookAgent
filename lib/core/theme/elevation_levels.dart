import 'package:flutter/material.dart';

/// 디자인 시스템의 정확한 Elevation 레벨 정의
/// 각 레벨은 Drop Shadow 1 + Drop Shadow 2 조합으로 구성
class ElevationLevels {
  
  /// Level0: No shadow - 기본 평면 상태
  static const List<BoxShadow> level0 = [];
  
  /// Level1 (1dp): 낮은 강조 컴포넌트, 기본 카드, 툴팁 등에 그래픽 효과
  static const List<BoxShadow> level1 = [
    // Drop Shadow 1: X: 0, Y: 1, Blur: 2, Spread: 0, Opacity: 30%
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
      color: Color.fromRGBO(0, 0, 0, 0.30),
    ),
    // Drop Shadow 2: X: 0, Y: 1, Blur: 3, Spread: 1, Opacity: 15%
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 1,
      color: Color.fromRGBO(0, 0, 0, 0.15),
    ),
  ];
  
  /// Level2 (3dp): 중간 강조 컴포넌트, 메인 인터랙션 요소의 그래픽 효과
  static const List<BoxShadow> level2 = [
    // Drop Shadow 1: X: 0, Y: 1, Blur: 2, Spread: 0, Opacity: 30%
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
      color: Color.fromRGBO(0, 0, 0, 0.30),
    ),
    // Drop Shadow 2: X: 0, Y: 2, Blur: 6, Spread: 2, Opacity: 15%
    BoxShadow(
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 2,
      color: Color.fromRGBO(0, 0, 0, 0.15),
    ),
  ];
  
  /// Level3 (6dp): 높은 강조 컴포넌트, FAB, 메뉴 등의 그래픽 효과
  static const List<BoxShadow> level3 = [
    // Drop Shadow 1: X: 0, Y: 3, Blur: 3, Spread: 0, Opacity: 30%
    BoxShadow(
      offset: Offset(0, 3),
      blurRadius: 3,
      spreadRadius: 0,
      color: Color.fromRGBO(0, 0, 0, 0.30),
    ),
    // Drop Shadow 2: X: 0, Y: 4, Blur: 8, Spread: 3, Opacity: 15%
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 3,
      color: Color.fromRGBO(0, 0, 0, 0.15),
    ),
  ];
  
  /// Level4 (8dp): 매우 높은 강조 컴포넌트, 스낵바, 툴스트립 등의 그래픽 효과
  static const List<BoxShadow> level4 = [
    // Drop Shadow 1: X: 0, Y: 2, Blur: 3, Spread: 0, Opacity: 30%
    BoxShadow(
      offset: Offset(0, 2),
      blurRadius: 3,
      spreadRadius: 0,
      color: Color.fromRGBO(0, 0, 0, 0.30),
    ),
    // Drop Shadow 2: X: 0, Y: 6, Blur: 10, Spread: 4, Opacity: 15%
    BoxShadow(
      offset: Offset(0, 6),
      blurRadius: 10,
      spreadRadius: 4,
      color: Color.fromRGBO(0, 0, 0, 0.15),
    ),
  ];
  
  /// Level5 (12dp): 최상위 Elevation (모달, 다이얼로그)의 그래픽 효과
  static const List<BoxShadow> level5 = [
    // Drop Shadow 1: X: 0, Y: 4, Blur: 4, Spread: 0, Opacity: 30%
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 4,
      spreadRadius: 0,
      color: Color.fromRGBO(0, 0, 0, 0.30),
    ),
    // Drop Shadow 2: X: 0, Y: 8, Blur: 12, Spread: 6, Opacity: 15%
    BoxShadow(
      offset: Offset(0, 8),
      blurRadius: 12,
      spreadRadius: 6,
      color: Color.fromRGBO(0, 0, 0, 0.15),
    ),
  ];
  
  /// Flutter Material elevation을 디자인 시스템 레벨로 매핑
  static double getFlutterElevation(int level) {
    switch (level) {
      case 0: return 0;
      case 1: return 1;
      case 2: return 3;
      case 3: return 6;
      case 4: return 8;
      case 5: return 12;
      default: return 0;
    }
  }
  
  /// 디자인 시스템 레벨에 따른 BoxShadow 반환
  static List<BoxShadow> getShadows(int level) {
    switch (level) {
      case 0: return level0;
      case 1: return level1;
      case 2: return level2;
      case 3: return level3;
      case 4: return level4;
      case 5: return level5;
      default: return level0;
    }
  }
}
