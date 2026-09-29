import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/content_item.dart';
import '../models/user_model.dart';
import '../screens/user_profile_screen.dart';

/// A circular avatar with the author's name, used on content cards.
///
/// The author arrives as a `DocumentReference` on the content document rather
/// than a name, so it has to be resolved. That is done per document id and
/// cached, because a grid of 20 cards all by the same person would otherwise
/// fire 20 identical reads.
class CreatorChip extends StatelessWidget {
  const CreatorChip({super.key, required this.item, this.onTap});

  final ContentItem item;
  final VoidCallback? onTap;

  static final Map<String, UserModel?> _cache = {};

  @override
  Widget build(BuildContext context) {
    final authorUid = _authorUidOf(item);
    if (authorUid == null || authorUid.isEmpty) {
      return const SizedBox.shrink();
    }

    final cached = _cache[authorUid];
    if (cached != null) {
      return _build(context, authorUid, cached);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(authorUid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Still loading, or the author document is gone. A placeholder
          // circle reads better than a row that reflows when the name lands.
          return _build(context, authorUid, null);
        }

        // doc.data() is Object? in this SDK, so narrow it before parsing.
        final raw = snapshot.data!.data() as Map<String, dynamic>?;
        if (raw == null) return _build(context, authorUid, null);

        final user = UserModel.fromFirebase(raw, authorUid);
        _cache[authorUid] = user;
        return _build(context, authorUid, user);
      },
    );
  }

  Widget _build(BuildContext context, String uid, UserModel? user) {
    final name = user?.username.isNotEmpty == true
        ? user!.username
        : (user?.name.isNotEmpty == true ? user!.name : 'Fan');

    return InkWell(
      onTap: onTap ??
          () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: uid, displayName: name),
                ),
              ),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(user: user),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pulls the author's uid off a content document, tolerating a raw string.
  static String? _authorUidOf(ContentItem item) {
    final author = item.author;
    if (author == null || author.isEmpty) return null;
    return author;
  }
}

/// The circle itself, with initials as the fallback.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    const size = 22.0;
    final image = user?.profileImage ?? '';

    if (image.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          image,
          height: size,
          width: size,
          fit: BoxFit.cover,
          errorBuilder: (context, _, __) => _initialsCircle(),
        ),
      );
    }

    return _initialsCircle();
  }

  Widget _initialsCircle() {
    return Container(
      height: 22,
      width: 22,
      decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          color: AppColors.primaryLight,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String get _initials {
    final user = this.user;
    if (user == null) return '?';
    final source = user.username.trim().isNotEmpty ? user.username : user.name;
    final parts = source.split(RegExp(r'[\s_]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
