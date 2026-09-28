class AppCategories {
  static const List<String> all = [
    'Anime',
    'Donghua',
    'Manga',
    'Manhua',
    'Manhwa',
    'Comics',
    'Gaming',
    'E-sports',
    'Music',
    'Movies',
    'Books',
  ];

  // Category icons mapping
  static const Map<String, String> categoryIcons = {
    'Anime': '🎌',
    'Donghua': '🐉',
    'Manga': '📚',
    'Manhua': '🏮',
    'Manhwa': '💫',
    'Comics': '🦹‍♂️',
    'Gaming': '🎮',
    'E-sports': '🏆',
    'Music': '🎵',
    'Movies': '🎬',
    'Books': '📖',
  };

  // Get icon for category
  static String getIcon(String category) {
    return categoryIcons[category] ?? '📌';
  }
}