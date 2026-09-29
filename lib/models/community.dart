import 'package:cloud_firestore/cloud_firestore.dart';

/// A community: a space around a fandom where fans post and talk.
///
/// Mirrors the shape the seeded `communities` documents already use, so a
/// community created in-app and one from `seed/` are indistinguishable. The
/// membership count is *stored*, not computed, because counting members on
/// every read would mean a query per card; the write that changes it lives in
/// `CommunityService`.
class Community {
  const Community({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    this.category = '',
    this.createdBy = '',
    this.memberCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final String createdBy;
  final int memberCount;
  final DateTime? createdAt;

  factory Community.fromFirestore(String id, Map<String, dynamic> data) {
    return Community(
      id: id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageUrl: _firstImage(data['imageUrl']),
      category: data['category']?.toString() ?? '',
      createdBy: _authorIdOf(data['createdBy']),
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      createdAt: _toDate(data['createdAt']),
    );
  }

  /// The banner URL, from either shape the field has carried.
  ///
  /// The seeded communities store an **array** of images (`pickImages` in
  /// seed/generate.mjs), while `CommunityService.createCommunity` writes a
  /// single string. A bare `toString()` on the list form yields
  /// `"[https://..., https://...]"`, which is not a URL - `Image.network` then
  /// fails for every seeded community and falls back to the placeholder icon.
  /// So the list form is unwrapped to its first entry.
  static String _firstImage(Object? raw) {
    if (raw is String) return raw;
    if (raw is List && raw.isNotEmpty) return raw.first.toString();
    return '';
  }

  /// The creator's uid, from either shape `createdBy` has carried.
  ///
  /// A DocumentReference stringifies to a full resource path
  /// (`projects/.../documents/users/UID`), not a uid, so `toString()` alone
  /// would leave every seeded community with a creator that matches no account -
  /// and the "delete my community" ownership check would never fire for them.
  /// Mirrors `ContentItem._authorIdOf`.
  static String _authorIdOf(Object? raw) {
    if (raw is DocumentReference) return raw.id;

    final asString = raw?.toString().trim() ?? '';
    if (asString.isEmpty) return '';

    final parts = asString.split('/');
    if (parts.length == 1) return asString;
    if (parts.length == 2 && parts.first == 'users' && parts.last.isNotEmpty) {
      return parts.last;
    }
    // A full resource path: .../documents/users/UID
    final marker = parts.indexOf('users');
    if (marker != -1 && marker + 1 < parts.length && parts.last.isNotEmpty) {
      return parts.last;
    }
    return '';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'category': category,
        'createdBy': createdBy,
        'memberCount': memberCount,
        'createdAt': FieldValue.serverTimestamp(),
      };

  Community copyWith({int? memberCount}) => Community(
        id: id,
        name: name,
        description: description,
        imageUrl: imageUrl,
        category: category,
        createdBy: createdBy,
        memberCount: memberCount ?? this.memberCount,
        createdAt: createdAt,
      );

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

/// A post inside a community.
///
/// Community posts are separate from `content` on purpose: they belong to a
/// space, carry a discussion shape, and are read through the community rather
/// than the main feed.
class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.content,
    this.title = '',
    this.authorId = '',
    this.authorName = '',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final int likesCount;
  final int commentsCount;
  final DateTime? createdAt;

  factory CommunityPost.fromFirestore(String id, Map<String, dynamic> data) {
    return CommunityPost(
      id: id,
      title: data['title']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      authorId: data['authorId']?.toString() ?? '',
      authorName: data['authorName']?.toString() ?? '',
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      createdAt: _toDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'likesCount': 0,
        'commentsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
