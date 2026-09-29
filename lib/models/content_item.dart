import 'package:cloud_firestore/cloud_firestore.dart';

import 'content_media.dart';

class ContentItem {
  final String id;
  final String title;
  final String description;
  final String category; // singular field or main category
  final List<String> categories;
  final String type;
  final String imageUrl;
  final String videoUrl;
  final String audioUrl;
  final String creator;

  /// The author's uid, resolved from the `author` DocumentReference.
  ///
  /// [creator] is only a display *name*, so it cannot answer "is this my post"
  /// or "open this person's profile" - a name is neither unique nor stable.
  /// Empty for documents written before authorship was recorded.
  final String authorId;

  final int likes;
  final int views;
  final int comments;
  final int saved;
  final DateTime? createdAt;

  /// The author's uid.
  ///
  /// Stored separately from `creator` (a display name) so a card can resolve
  /// and link the actual account. Read from the `author` DocumentReference, and
  /// also from a plain string, because documents have carried both shapes.
  final String author;

  /// Ordered slideshow items. Populated from the Firestore `media` array when
  /// present, and synthesised from the legacy single-URL fields when not, so
  /// documents written before the slideshow existed still display something.
  final List<ContentMedia> media;

  ContentItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    List<String>? categories,
    this.type = '',
    this.imageUrl = '',
    this.videoUrl = '',
    this.audioUrl = '',
    this.creator = '',
    this.authorId = '',
    this.likes = 0,
    this.views = 0,
    this.comments = 0,
    this.saved = 0,
    this.createdAt,
    this.author = '',
    List<ContentMedia>? media,
  })  : categories = categories ?? (category.isNotEmpty ? [category] : []),
        media = media ?? const [];

  /// True when this post is a slideshow rather than a single item.
  bool get isSlideshow => media.length > 1;

  /// Returns a copy with the given fields replaced.
  ///
  /// This exists because rebuilding a [ContentItem] by hand to bump a counter
  /// silently drops every field that is not listed, and the fields most likely
  /// to be forgotten - `media`, `description`, `creator` - are exactly the ones
  /// a post is displayed from. Always go through here instead.
  ContentItem copyWith({
    String? title,
    String? description,
    String? author,
    String? category,
    List<String>? categories,
    String? type,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    String? creator,
    String? authorId,
    int? likes,
    int? views,
    int? comments,
    int? saved,
    DateTime? createdAt,
    List<ContentMedia>? media,
  }) =>
      ContentItem(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        author: author ?? this.author,
        category: category ?? this.category,
        categories: categories ?? this.categories,
        type: type ?? this.type,
        imageUrl: imageUrl ?? this.imageUrl,
        videoUrl: videoUrl ?? this.videoUrl,
        audioUrl: audioUrl ?? this.audioUrl,
        creator: creator ?? this.creator,
        authorId: authorId ?? this.authorId,
        likes: likes ?? this.likes,
        views: views ?? this.views,
        comments: comments ?? this.comments,
        saved: saved ?? this.saved,
        createdAt: createdAt ?? this.createdAt,
        media: media ?? this.media,
      );

  factory ContentItem.fromFirebase(String id, Map<String, dynamic> data) {
    // Parse imageUrl: could be String or List<dynamic>
    String parsedImageUrl = '';
    if (data['imageUrl'] != null) {
      if (data['imageUrl'] is List && (data['imageUrl'] as List).isNotEmpty) {
        parsedImageUrl = (data['imageUrl'] as List).first.toString();
      } else if (data['imageUrl'] is String) {
        parsedImageUrl = data['imageUrl'] as String;
      }
    }
    if (parsedImageUrl.isEmpty && data['bannerUrl'] != null && data['bannerUrl'] is String) {
      parsedImageUrl = data['bannerUrl'] as String;
    }

    // Parse categories: could be single String 'category' or List 'categories'
    List<String> parsedCategories = [];
    if (data['categories'] is List) {
      parsedCategories = List<String>.from(data['categories'].map((e) => e.toString()));
    } else if (data['category'] is String && (data['category'] as String).isNotEmpty) {
      parsedCategories = [data['category'] as String];
    }

    String mainCategory = parsedCategories.isNotEmpty
        ? parsedCategories.first
        : (data['category']?.toString() ?? '');

    // Parse video / audio arrays if needed
    String vUrl = '';
    if (data['videoUrl'] is List && (data['videoUrl'] as List).isNotEmpty) {
      vUrl = (data['videoUrl'] as List).first.toString();
    } else if (data['videoUrl'] is String) {
      vUrl = data['videoUrl'] as String;
    }

    String aUrl = '';
    if (data['audioUrl'] is List && (data['audioUrl'] as List).isNotEmpty) {
      aUrl = (data['audioUrl'] as List).first.toString();
    } else if (data['audioUrl'] is String) {
      aUrl = data['audioUrl'] as String;
    }

    DateTime? created;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is DateTime) {
        created = data['createdAt'];
      } else if (data['createdAt']?.toDate != null) {
        created = data['createdAt'].toDate();
      }
    }

    return ContentItem(
      id: id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: mainCategory,
      categories: parsedCategories,
      type: data['type']?.toString() ?? '',
      imageUrl: parsedImageUrl,
      videoUrl: vUrl,
      audioUrl: aUrl,
      creator: data['creator']?.toString() ?? '',
      authorId: _authorIdOf(data['author']),
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      views: (data['views'] as num?)?.toInt() ?? 0,
      comments: (data['comments'] as num?)?.toInt() ?? 0,
      saved: (data['saved'] as num?)?.toInt() ?? 0,
      createdAt: created,
      author: _parseAuthor(data['author']),
      media: _parseMedia(data, parsedImageUrl, vUrl, aUrl),
    );
  }

  /// The author's uid, from either a DocumentReference or a plain string.
  static String _parseAuthor(Object? raw) {
    if (raw == null) return '';
    if (raw is DocumentReference) return raw.id;
    return raw.toString();
  }

  /// The author's uid from the `author` field.
  ///
  /// The canonical shape is a DocumentReference to `users/{uid}`. Two other
  /// shapes occur and are accepted: a bare uid string from legacy documents,
  /// and a `users/{uid}` path string, which is what the offline cache stores
  /// after `jsonEncode` has flattened the reference. Anything else yields an
  /// empty string, and callers treat that as "the author is unknown" rather
  /// than guessing from [creator] - a display name is not an identity.
  static String _authorIdOf(Object? author) {
    if (author is DocumentReference) return author.id;

    final asString = author?.toString().trim() ?? '';
    if (asString.isEmpty) return '';

    final parts = asString.split('/');
    if (parts.length == 1) return asString;
    if (parts.length == 2 && parts.first == 'users' && parts.last.isNotEmpty) {
      return parts.last;
    }
    return '';
  }

  /// Prefer the explicit `media` array; fall back to the legacy single-URL
  /// fields so pre-slideshow documents still render.
  static List<ContentMedia> _parseMedia(
    Map<String, dynamic> data,
    String imageUrl,
    String videoUrl,
    String audioUrl,
  ) {
    final raw = data['media'];
    if (raw is List) {
      final parsed = raw
          .map(ContentMedia.tryParse)
          .whereType<ContentMedia>()
          .toList(growable: false);
      if (parsed.isNotEmpty) return parsed;
    }

    // Legacy shape: at most one of each. Images lead, then video, then audio,
    // which matches how the old create screen ordered them.
    return [
      if (imageUrl.isNotEmpty) ContentMedia(type: 'image', url: imageUrl),
      if (videoUrl.isNotEmpty) ContentMedia(type: 'video', url: videoUrl),
      if (audioUrl.isNotEmpty) ContentMedia(type: 'audio', url: audioUrl),
    ];
  }

  /// Trending score: weighted sum of engagement signals.
  ///
  /// Saved counts for most and comments second, so a post people keep or
  /// discuss outranks one that is merely scrolled past.
  double get trendingScore {
    return (likes * 3) + (views * 1) + (comments * 4) + (saved * 5).toDouble();
  }

  /// True if this post sits in any of [candidates]. Comparison is
  /// case-insensitive because the stored vocabulary is lowercase but legacy
  /// documents carry Title Case.
  bool matchesAnyCategory(Set<String> candidates) {
    if (candidates.isEmpty) return false;
    for (final c in categories) {
      if (candidates.contains(c.toLowerCase())) return true;
    }
    return false;
  }

  /// Check if this item matches a filter value (case-insensitive)
  bool matchesCategory(String filter) {
    if (filter == 'all') return true;
    final lowerFilter = filter.toLowerCase();
    if (category.toLowerCase() == lowerFilter) return true;
    return categories.any((c) => c.toLowerCase() == lowerFilter);
  }
}
