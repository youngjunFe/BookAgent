class ReadingGoal {
  final String id;
  final String userId; // 🚨 보안: 사용자 ID 추가
  final String title;
  final GoalType type;
  final int targetValue;
  final int currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final DateTime createdAt;

  const ReadingGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.endDate,
    required this.isCompleted,
    required this.createdAt,
  });

  double get progress => currentValue / targetValue;
  
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  bool get isOverdue => DateTime.now().isAfter(endDate) && !isCompleted;

  ReadingGoal copyWith({
    String? id,
    String? userId,
    String? title,
    GoalType? type,
    int? targetValue,
    int? currentValue,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return ReadingGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // 샘플 데이터 (보안상 사용 금지)
  static List<ReadingGoal> getSampleGoalsForUser(String userId) => [
    ReadingGoal(
      id: '1',
      userId: userId,
      title: '이번 달 3권 읽기',
      type: GoalType.monthly,
      targetValue: 3,
      currentValue: 1,
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 31),
      isCompleted: false,
      createdAt: DateTime(2024, 1, 1),
    ),
    ReadingGoal(
      id: '2',
      userId: userId,
      title: '올해 24권 읽기',
      type: GoalType.yearly,
      targetValue: 24,
      currentValue: 8,
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 12, 31),
      isCompleted: false,
      createdAt: DateTime(2024, 1, 1),
    ),
    ReadingGoal(
      id: '3',
      userId: userId,
      title: '10일 연속 독서',
      type: GoalType.streak,
      targetValue: 10,
      currentValue: 7,
      startDate: DateTime(2024, 1, 15),
      endDate: DateTime(2024, 1, 25),
      isCompleted: false,
      createdAt: DateTime(2024, 1, 15),
    ),
  ];
}

enum GoalType {
  daily,
  weekly,
  monthly,
  yearly,
  streak,
  pages,
  time,
}

extension GoalTypeExtension on GoalType {
  String get displayName {
    switch (this) {
      case GoalType.daily:
        return '일간';
      case GoalType.weekly:
        return '주간';
      case GoalType.monthly:
        return '월간';
      case GoalType.yearly:
        return '연간';
      case GoalType.streak:
        return '연속 독서';
      case GoalType.pages:
        return '페이지';
      case GoalType.time:
        return '시간';
    }
  }

  String get unit {
    switch (this) {
      case GoalType.daily:
      case GoalType.weekly:
      case GoalType.monthly:
      case GoalType.yearly:
        return '권';
      case GoalType.streak:
        return '일';
      case GoalType.pages:
        return '페이지';
      case GoalType.time:
        return '분';
    }
  }
}







