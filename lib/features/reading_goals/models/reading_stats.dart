class ReadingStats {
  final int totalBooksRead;
  final int totalPagesRead;
  final int totalReadingTime; // 분 단위
  final int currentStreak;
  final int longestStreak;
  final double averageRating;
  final int goalAchievements;
  final List<MonthlyStats> monthlyStats;
  final Map<String, int> genreStats;

  const ReadingStats({
    required this.totalBooksRead,
    required this.totalPagesRead,
    required this.totalReadingTime,
    required this.currentStreak,
    required this.longestStreak,
    required this.averageRating,
    required this.goalAchievements,
    required this.monthlyStats,
    required this.genreStats,
  });

  // 이번 달 읽은 책 수
  int get thisMonthBooks {
    final now = DateTime.now();
    final thisMonth = monthlyStats.firstWhere(
      (stats) => stats.year == now.year && stats.month == now.month,
      orElse: () => const MonthlyStats(year: 0, month: 0, booksRead: 0, pagesRead: 0),
    );
    return thisMonth.booksRead;
  }

  // 올해 읽은 책 수
  int get thisYearBooks {
    final now = DateTime.now();
    return monthlyStats
        .where((stats) => stats.year == now.year)
        .fold(0, (sum, stats) => sum + stats.booksRead);
  }

  // 평균 독서 시간 (일 단위)
  double get averageDailyReadingTime {
    if (monthlyStats.isEmpty) return 0;
    final totalDays = monthlyStats.length * 30; // 대략적 계산
    return totalReadingTime / totalDays;
  }

  static ReadingStats get sample => ReadingStats(
    totalBooksRead: 23,
    totalPagesRead: 6842,
    totalReadingTime: 3420, // 57시간
    currentStreak: 7,
    longestStreak: 15,
    averageRating: 4.2,
    goalAchievements: 5,
    monthlyStats: [
      MonthlyStats(year: 2024, month: 1, booksRead: 3, pagesRead: 890),
      MonthlyStats(year: 2024, month: 2, booksRead: 2, pagesRead: 567),
      MonthlyStats(year: 2024, month: 3, booksRead: 4, pagesRead: 1234),
      MonthlyStats(year: 2024, month: 4, booksRead: 3, pagesRead: 876),
      MonthlyStats(year: 2024, month: 5, booksRead: 5, pagesRead: 1456),
      MonthlyStats(year: 2024, month: 6, booksRead: 2, pagesRead: 623),
      MonthlyStats(year: 2024, month: 7, booksRead: 4, pagesRead: 1196),
    ],
    genreStats: {
      '소설': 8,
      '에세이': 4,
      '자기계발': 3,
      '과학': 2,
      '역사': 3,
      '철학': 2,
      '기타': 1,
    },
  );
}

class MonthlyStats {
  final int year;
  final int month;
  final int booksRead;
  final int pagesRead;

  const MonthlyStats({
    required this.year,
    required this.month,
    required this.booksRead,
    required this.pagesRead,
  });

  String get monthName {
    const months = [
      '', '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    return months[month];
  }
}


