import 'package:flutter/foundation.dart';

/// 시간대별 개인화 메시지 서비스
class TimeBasedMessageService {
  /// 현재 시간에 맞는 메시지를 가져옵니다
  static TimeBasedMessage getMessageForCurrentTime({
    required bool isLoggedIn,
    String nickname = '독서가',
  }) {
    final now = DateTime.now();
    final hour = now.hour;
    
    debugPrint('🕐 [TimeBasedMessage] 현재 시간: ${hour}시, 로그인 상태: $isLoggedIn, 닉네임: $nickname');
    
    if (isLoggedIn) {
      return _getLoggedInMessage(hour, nickname);
    } else {
      return _getGuestMessage(hour);
    }
  }
  
  /// 로그인 사용자용 메시지 (시간대별 상세 구분)
  static TimeBasedMessage _getLoggedInMessage(int hour, String nickname) {
    if (hour >= 6 && hour < 9) {
      // 아침 (06:00-08:59)
      return TimeBasedMessage(
        message1: '$nickname님, 좋은 아침이에요!',
        message2: '오늘의 첫 감동 치읓과 함께 하세요✨',
      );
    } else if (hour >= 9 && hour < 12) {
      // 오전 (09:00-11:59)
      return TimeBasedMessage(
        message1: '$nickname님, 치읓은 아직 잠이 덜 깼어요.',
        message2: '오늘의 감동을 함께 깨워볼까요?👀',
      );
    } else if (hour >= 12 && hour < 15) {
      // 점심 (12:00-14:59)
      return TimeBasedMessage(
        message1: '$nickname님, 점심 드셨나요?🍚',
        message2: '치읓과의 대화로 마음 한끼 어떠요?',
      );
    } else if (hour >= 15 && hour < 18) {
      // 오후 (15:00-17:59)
      return TimeBasedMessage(
        message1: '$nickname님, 잠이 쏟아지는 나른한 오후에요🥱',
        message2: '치읓과 감동 나누고 집중력 회복해요!',
      );
    } else if (hour >= 18 && hour < 21) {
      // 저녁 (18:00-20:59)
      return TimeBasedMessage(
        message1: '$nickname님, 저녁 거르지 마세요😋',
        message2: '마음까지 감동으로 든든하게 채워요!',
      );
    } else if (hour >= 21 || hour < 0) {
      // 밤 (21:00-23:59)
      return TimeBasedMessage(
        message1: '$nickname님, 술술 하루를 마무리할 시간이에요.',
        message2: '감동을 나누고 생각 정리 어떠요?🧠',
      );
    } else if (hour >= 0 && hour < 3) {
      // 밤 (00:00-02:59)
      return TimeBasedMessage(
        message1: '$nickname님, 밤이 깊었어요🌙',
        message2: '치읓에게 감동을 들려주세요.',
      );
    } else {
      // 새벽 (03:00-05:59)
      return TimeBasedMessage(
        message1: '$nickname님, 잠 못 드는 새벽인가요?🦉',
        message2: '새벽의 사색 치읓과 나눠보세요.',
      );
    }
  }
  
  /// 비로그인 사용자용 메시지 (간소화된 시간대 구분)
  static TimeBasedMessage _getGuestMessage(int hour) {
    if (hour >= 6 && hour < 12) {
      // 오전 (06:00-11:59)
      return TimeBasedMessage(
        message1: '상쾌한 오전이에요!',
        message2: '치읓ㅕ과의 대화로 감동을 깨워보세요.🌱',
      );
    } else if (hour >= 12 && hour < 20) {
      // 오후 (12:00-19:59)
      return TimeBasedMessage(
        message1: '분주한 오후에요!❄️',
        message2: '잠시 쉬어 감동을 나눠볼래요?',
      );
    } else {
      // 밤/새벽 (20:00-05:59)
      return TimeBasedMessage(
        message1: '조용히 찾아온 밤의 시간!',
        message2: '깊은 대화로 기록해 보세요.🐺',
      );
    }
  }
}

/// 시간대별 메시지 데이터 클래스
class TimeBasedMessage {
  final String message1; // 첫 번째 줄 (닉네임 포함)
  final String message2; // 두 번째 줄
  
  const TimeBasedMessage({
    required this.message1,
    required this.message2,
  });
  
  /// 전체 메시지를 줄바꿈으로 연결한 문자열
  String get fullMessage => '$message1\n$message2';
  
  @override
  String toString() => 'TimeBasedMessage(message1: "$message1", message2: "$message2")';
}
