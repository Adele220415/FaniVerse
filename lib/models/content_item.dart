class ContentItem {
  final String id;
  final String title;
  final String category; // singular field from Firestore
  final List<String> categories; // derived from category for compatibility
  final String type;
  final String imageUrl;
  final int likes;
  final int views;
  final int comments;
  final int saved;

  ContentItem({
    required this.id,
    required this.title,
    required this.category,
    List<String>? categories,
    this.type = '',
    this.imageUrl = '',
    this.likes = 0,
    this.views = 0,
    this.comments = 0,
    this.saved = 0,
  }) : categories = categories ?? [category];

  /// Trending score: weighted sum of engagement signals
  double get trendingScore {
    return (likes * 3) + (views * 1) + (comments * 4) + (saved * 5).toDouble();
  }

  /// Check if this item matches a filter value (case-insensitive)
  bool matchesCategory(String filter) {
    if (filter == 'all') return true;
    return category.toLowerCase() == filter.toLowerCase();
  }
}
