import 'package:flutter/material.dart';

enum ReviewStatus {
  draft,     // 초안
  completed, // 완료
  published, // 게시
}

enum ReadingStatus {
  wantToRead, // 읽고싶은
  reading,    // 읽고있는
  completed,  // 완독한
  paused,     // 쉬고있는
}

class Review {
  final String id;
  final String title;
  final String content;
  final String bookTitle;
  final String? bookAuthor;
  final String? bookCover;
  final ReviewStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? backgroundImage;
  final List<String> tags;
  final String? mood;
  final List<String> quotes;
  final String? chatHistory; // AI 대화 내용
  
  Review({
    required this.id,
    required this.title,
    required this.content,
    required this.bookTitle,
    this.bookAuthor,
    this.bookCover,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.backgroundImage,
    this.tags = const [],
    this.mood,
    this.quotes = const [],
    this.chatHistory,
  });

  // 상태에 따른 색상 반환
  Color get statusColor {
    switch (status) {
      case ReviewStatus.draft:
        return Colors.orange;
      case ReviewStatus.completed:
        return Colors.green;
      case ReviewStatus.published:
        return Colors.blue;
    }
  }

  // 상태 텍스트 반환
  String get statusText {
    switch (status) {
      case ReviewStatus.draft:
        return '초안';
      case ReviewStatus.completed:
        return '완료';
      case ReviewStatus.published:
        return '게시';
    }
  }

  // 복사본 생성 (수정용)
  Review copyWith({
    String? id,
    String? title,
    String? content,
    String? bookTitle,
    String? bookAuthor,
    String? bookCover,
    ReviewStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? backgroundImage,
    List<String>? tags,
    String? mood,
    List<String>? quotes,
    String? chatHistory,
  }) {
    return Review(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      bookTitle: bookTitle ?? this.bookTitle,
      bookAuthor: bookAuthor ?? this.bookAuthor,
      bookCover: bookCover ?? this.bookCover,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      tags: tags ?? this.tags,
      mood: mood ?? this.mood,
      quotes: quotes ?? this.quotes,
      chatHistory: chatHistory ?? this.chatHistory,
    );
  }

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'bookTitle': bookTitle,
      'bookAuthor': bookAuthor,
      'bookCover': bookCover,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'backgroundImage': backgroundImage,
      'tags': tags,
      'mood': mood,
      'quotes': quotes,
      'chatHistory': chatHistory,
    };
  }

  // JSON에서 생성
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      bookTitle: json['bookTitle'],
      bookAuthor: json['bookAuthor'],
      bookCover: json['bookCover'],
      status: ReviewStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReviewStatus.draft,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      backgroundImage: json['backgroundImage'],
      tags: List<String>.from(json['tags'] ?? []),
      mood: json['mood'],
      quotes: List<String>.from(json['quotes'] ?? []),
      chatHistory: json['chatHistory'],
    );
  }

  @override
  String toString() {
    return 'Review(id: $id, title: $title, bookTitle: $bookTitle, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// 책 모델
class Book {
  final String id;
  final String title;
  final String? author;
  final String? coverImage;
  final String? description;
  final String? isbn;
  final String? publisher;
  final DateTime? publishDate;
  final String? genre;
  final ReadingStatus status;
  final DateTime addedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? currentPage;
  final int? totalPages;

  Book({
    required this.id,
    required this.title,
    this.author,
    this.coverImage,
    this.description,
    this.isbn,
    this.publisher,
    this.publishDate,
    this.genre,
    required this.status,
    required this.addedAt,
    this.startedAt,
    this.completedAt,
    this.currentPage,
    this.totalPages,
  });

  // 읽기 진행률 계산
  double get progress {
    if (totalPages == null || currentPage == null) return 0.0;
    return (currentPage! / totalPages!).clamp(0.0, 1.0);
  }

  // 상태별 색상
  Color get statusColor {
    switch (status) {
      case ReadingStatus.wantToRead:
        return Colors.grey;
      case ReadingStatus.reading:
        return Colors.blue;
      case ReadingStatus.completed:
        return Colors.green;
      case ReadingStatus.paused:
        return Colors.orange;
    }
  }

  // 상태 텍스트
  String get statusText {
    switch (status) {
      case ReadingStatus.wantToRead:
        return '읽고싶은';
      case ReadingStatus.reading:
        return '읽고있는';
      case ReadingStatus.completed:
        return '완독한';
      case ReadingStatus.paused:
        return '쉬고있는';
    }
  }

  // 복사본 생성
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverImage,
    String? description,
    String? isbn,
    String? publisher,
    DateTime? publishDate,
    String? genre,
    ReadingStatus? status,
    DateTime? addedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? currentPage,
    int? totalPages,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverImage: coverImage ?? this.coverImage,
      description: description ?? this.description,
      isbn: isbn ?? this.isbn,
      publisher: publisher ?? this.publisher,
      publishDate: publishDate ?? this.publishDate,
      genre: genre ?? this.genre,
      status: status ?? this.status,
      addedAt: addedAt ?? this.addedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverImage': coverImage,
      'description': description,
      'isbn': isbn,
      'publisher': publisher,
      'publishDate': publishDate?.toIso8601String(),
      'genre': genre,
      'status': status.name,
      'addedAt': addedAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'currentPage': currentPage,
      'totalPages': totalPages,
    };
  }

  // JSON에서 생성
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      coverImage: json['coverImage'],
      description: json['description'],
      isbn: json['isbn'],
      publisher: json['publisher'],
      publishDate: json['publishDate'] != null 
          ? DateTime.parse(json['publishDate']) 
          : null,
      genre: json['genre'],
      status: ReadingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReadingStatus.wantToRead,
      ),
      addedAt: DateTime.parse(json['addedAt']),
      startedAt: json['startedAt'] != null 
          ? DateTime.parse(json['startedAt']) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      currentPage: json['currentPage'],
      totalPages: json['totalPages'],
    );
  }

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}





