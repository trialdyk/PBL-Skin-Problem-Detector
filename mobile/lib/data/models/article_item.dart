class ArticleItem {
  const ArticleItem({
    required this.category,
    required this.title,
    required this.body,
    required this.readTime,
    required this.image,
    this.badge,
    this.related = const [],
  });

  final String category;
  final String title;
  final String body;
  final String readTime;
  final String image;
  final String? badge;
  final List<String> related;
}
