import 'package:flutter/material.dart';

class AppAnimations {
  // 애니메이션 지속 시간
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  
  // 커브
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve elastic = Curves.elasticOut;
  
  // 페이지 전환 애니메이션
  static Widget slideTransition(BuildContext context, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: ModalRoute.of(context)!.animation!,
        curve: easeInOut,
      )),
      child: child,
    );
  }
  
  // 페이드 전환
  static Widget fadeTransition(BuildContext context, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: ModalRoute.of(context)!.animation!,
        curve: easeInOut,
      ),
      child: child,
    );
  }
  
  // 스케일 전환 (다이얼로그용)
  static Widget scaleTransition(BuildContext context, Widget child) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: ModalRoute.of(context)!.animation!,
        curve: elastic,
      ),
      child: child,
    );
  }
}
