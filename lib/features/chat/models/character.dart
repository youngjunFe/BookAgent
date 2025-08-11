class Character {
  final String id;
  final String name;
  final String bookTitle;
  final String author;
  final String genre;
  final String personality;
  final String description;
  final String? imageUrl;
  final int popularityScore;

  const Character({
    required this.id,
    required this.name,
    required this.bookTitle,
    required this.author,
    required this.genre,
    required this.personality,
    required this.description,
    this.imageUrl,
    required this.popularityScore,
  });
}



