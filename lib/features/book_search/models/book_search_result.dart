class BookSearchResult {
  final String title;
  final String author;
  final String publisher;
  final String image;
  final String description;
  final String isbn;

  BookSearchResult({
    required this.title,
    required this.author,
    required this.publisher,
    required this.image,
    required this.description,
    required this.isbn,
  });

  factory BookSearchResult.fromJson(Map<String, dynamic> json) {
    return BookSearchResult(
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      publisher: json['publisher'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      isbn: json['isbn'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'publisher': publisher,
      'image': image,
      'description': description,
      'isbn': isbn,
    };
  }
}
