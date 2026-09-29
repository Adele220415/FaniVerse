import 'package:cloud_firestore/cloud_firestore.dart';

/// A notification delivered to a user's `notifications` subcollection.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.actorName,
    this.contentId,
    this.contentTitle,
    this.read = false,
    this.createdAt,
  });

  /// Document id, unique per (recipient, actor, target, type) so the same
  /// like cannot notify twice.
  final String id;

  /// One of `like`, `save`, `comment`.
  final String type;

  /// Who caused it. Never trust a display name that arrives with the event -
  /// it is resolved from the actor's user document when rendering.
  final String actorUid;

  /// Cached actor name, so the list renders without a read per row.
  final String actorName;

  final String? contentId;
  final String? contentTitle;

  final bool read;
  final DateTime? createdAt;

  bool get isLike => type == 'like';
  bool get isComment => type == 'comment';
  bool get isSave => type == 'save';

  /// The line shown in the list.
  String get body {
    final who = actorName.isEmpty ? 'Someone' : actorName;
    final title = (contentTitle != null && contentTitle!.isNotEmpty) ? ' "$contentTitle"' : '';

    return switch (type) {
      'like' => '$who liked your post$title',
      'save' => '$who saved your post$title',
      'comment' => '$who commented on your post$title',
      _ => '$who interacted with your content',
    };
  }

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      type: data['type']?.toString() ?? 'unknown',
      actorUid: data['actorUid']?.toString() ?? '',
      actorName: data['actorName']?.toString() ?? '',
      contentId: data['contentId']?.toString(),
      contentTitle: data['contentTitle']?.toString(),
      read: data['read'] == true,
      createdAt: _toDate(data['createdAt']),
    );
  }

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
