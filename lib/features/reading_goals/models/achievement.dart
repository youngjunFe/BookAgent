class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final String iconName;
  final String badgeColor;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int requiredValue;
  final int currentValue;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.iconName,
    required this.badgeColor,
    required this.isUnlocked,
    this.unlockedAt,
    required this.requiredValue,
    required this.currentValue,
  });

  double get progress => currentValue / requiredValue;
  bool get isCompleted => currentValue >= requiredValue;

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    AchievementType? type,
    String? iconName,
    String? badgeColor,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? requiredValue,
    int? currentValue,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      badgeColor: badgeColor ?? this.badgeColor,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      requiredValue: requiredValue ?? this.requiredValue,
      currentValue: currentValue ?? this.currentValue,
    );
  }

  // 샘플 배지들
  static List<Achievement> get sampleAchievements => [
    Achievement(
      id: '1',
      title: '첫 번째 책',
      description: '첫 번째 책을 완독했습니다!',
      type: AchievementType.milestone,
      iconName: 'book',
      badgeColor: '#4CAF50',
      isUnlocked: true,
      unlockedAt: DateTime(2024, 1, 5),
      requiredValue: 1,
      currentValue: 1,
    ),
    Achievement(
      id: '2',
      title: '독서 입문자',
      description: '5권의 책을 완독했습니다!',
      type: AchievementType.milestone,
      iconName: 'menu_book',
      badgeColor: '#2196F3',
      isUnlocked: true,
      unlockedAt: DateTime(2024, 1, 15),
      requiredValue: 5,
      currentValue: 5,
    ),
    Achievement(
      id: '3',
      title: '꾸준한 독서가',
      description: '7일 연속으로 독서했습니다!',
      type: AchievementType.streak,
      iconName: 'local_fire_department',
      badgeColor: '#FF5722',
      isUnlocked: true,
      unlockedAt: DateTime(2024, 1, 22),
      requiredValue: 7,
      currentValue: 7,
    ),
    Achievement(
      id: '4',
      title: '독서 마니아',
      description: '10권의 책을 완독했습니다!',
      type: AchievementType.milestone,
      iconName: 'auto_stories',
      badgeColor: '#9C27B0',
      isUnlocked: false,
      requiredValue: 10,
      currentValue: 8,
    ),
    Achievement(
      id: '5',
      title: '스피드 리더',
      description: '하루에 100페이지를 읽었습니다!',
      type: AchievementType.special,
      iconName: 'flash_on',
      badgeColor: '#FFC107',
      isUnlocked: false,
      requiredValue: 100,
      currentValue: 76,
    ),
    Achievement(
      id: '6',
      title: '장르 탐험가',
      description: '5개의 다른 장르를 읽었습니다!',
      type: AchievementType.collection,
      iconName: 'explore',
      badgeColor: '#00BCD4',
      isUnlocked: false,
      requiredValue: 5,
      currentValue: 3,
    ),
    Achievement(
      id: '7',
      title: '월간 챌린저',
      description: '한 달 목표를 달성했습니다!',
      type: AchievementType.goal,
      iconName: 'emoji_events',
      badgeColor: '#FF9800',
      isUnlocked: false,
      requiredValue: 1,
      currentValue: 0,
    ),
  ];
}

enum AchievementType {
  milestone,
  streak,
  goal,
  special,
  collection,
}

extension AchievementTypeExtension on AchievementType {
  String get displayName {
    switch (this) {
      case AchievementType.milestone:
        return '이정표';
      case AchievementType.streak:
        return '연속 독서';
      case AchievementType.goal:
        return '목표 달성';
      case AchievementType.special:
        return '특별 성취';
      case AchievementType.collection:
        return '컬렉션';
    }
  }
}


