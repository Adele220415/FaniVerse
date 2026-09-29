import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/content_item.dart';
import '../services/user_directory_service.dart';
import '../widgets/content_thumbnail.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_listings.dart';
import 'content_detail_screen.dart';

/// Another user's profile: their stats, their posts, and their merchandise and
/// events.
///
/// The same screen serves both cases - opening your own profile from Search is
/// handled by [isOwnProfile], so there is no second copy of the layout to keep
/// in sync.
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.displayName,
    this.isOwnProfile = false,
    this.service,
  });

  final String userId;

  /// Shown in the app bar immediately, so the title is never blank while the
  /// profile document loads.
  final String displayName;

  final bool isOwnProfile;
  final UserDirectoryService? service;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final UserDirectoryService _service = widget.service ?? UserDirectoryService();

  /// Bumped to force a resubscribe after an error, which is what the Retry
  /// button does.
  int _retryCount = 0;

  /// Result of probing for the author + createdAt composite index. Cached so
  /// the probe runs once per visit, not once per rebuild.
  Future<bool>? _orderedPostsWorks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          widget.displayName,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<UserProfile>(
        // Re-keyed on the retry counter: StreamBuilder keeps the stream it was
        // given, so setState alone would resubscribe to the same failed stream.
        key: ValueKey(_retryCount),
        stream: _service.watchProfile(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('UserProfile(${widget.userId}) failed: ${snapshot.error}');
            return _ErrorView(
              message: _readableError(snapshot.error),
              onRetry: () => setState(() => _retryCount++),
            );
          }

          final profile = snapshot.data;
          if (profile == null) {
            return _ErrorView(
              message: 'That profile could not be loaded',
              onRetry: () => setState(() => _retryCount++),
            );
          }

          return _body(profile);
        },
      ),
    );
  }

  /// Turns a raw SDK or service exception into something a reader can act on.
  static String _readableError(Object? error) {
    if (error is StateError) return error.message.toString();
    final text = '$error';
    // A failed-precondition from Firestore always means a missing index, and
    // the raw message is a wall of SDK text that hides that.
    if (text.contains('failed-precondition') || text.contains('requires an index')) {
      return 'Some of this profile needs a Firestore index that has not been '
          'deployed yet. Run: firebase deploy --only firestore:indexes';
    }
    if (text.contains('PERMISSION_DENIED') || text.contains('permission-denied')) {
      return 'You do not have permission to view this profile.';
    }
    return text.split('\n').first;
  }

  Widget _body(UserProfile profile) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _buildHeader(profile),
        _buildStats(profile),
        const SizedBox(height: 8),
        const Divider(color: AppColors.border),
        _buildPostsHeader(profile),
        _buildPosts(profile.user.id),
        UserMerchandiseSection(userId: profile.user.id, canEdit: widget.isOwnProfile),
        UserEventsSection(userId: profile.user.id, canEdit: widget.isOwnProfile),
      ],
    );
  }

  Widget _buildHeader(UserProfile profile) {
    final user = profile.user;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          UserAvatar(
            userId: user.id,
            imageUrl: user.profileImage,
            displayName: user.name,
            username: user.username,
            radius: 38,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.name}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    user.bio,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Includes total likes across all of the user's posts - the aggregate is
  /// summed from the posts rather than stored on the user document, so it can
  /// never disagree with the posts themselves.
  Widget _buildStats(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stat('Posts', profile.postCount),
          _stat('Likes', profile.totalLikes),
          _stat('Views', profile.totalViews),
        ],
      ),
    );
  }

  Widget _stat(String label, int value) {
    return Column(
      children: [
        Text(
          _formatCount(value),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  String _formatCount(int value) {
    if (value < 1000) return '$value';
    if (value < 1000000) {
      final k = (value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1);
      return '${k}K';
    }
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  Widget _buildPostsHeader(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        'Posts (${profile.postCount})',
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  /// A user's posts, newest first.
  ///
  /// The obvious query - filter by author, order by `createdAt` - needs a
  /// composite index that only exists once `firestore.indexes.json` has been
  /// deployed. Until it is, Firestore rejects the whole query and the profile
  /// shows an error where the posts should be, which is exactly what was
  /// reported: search a user, open their profile, get an error.
  ///
  /// So the ordered query is probed once per profile. If it fails, the posts
  /// are read with the single-field `author` index alone and sorted here. One
  /// extra read buys a profile that works before the deploy as well as after.
  Widget _buildPosts(String userId) {
    _orderedPostsWorks ??= _probeOrderedPosts(userId);

    return FutureBuilder<bool>(
      future: _orderedPostsWorks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _postsStream(userId, ordered: snapshot.data == true);
      },
    );
  }

  /// Whether the author + createdAt composite index is actually deployed.
  ///
  /// A one-document probe: a missing index is rejected at query planning, before
  /// any data is read, so this costs nothing but the round trip.
  Future<bool> _probeOrderedPosts(String userId) async {
    try {
      await _postsQuery(userId).orderBy('createdAt', descending: true).limit(1).get();
      return true;
    } catch (e) {
      debugPrint('Ordered posts query unavailable, falling back: $e');
      return false;
    }
  }

  Query<Map<String, dynamic>> _postsQuery(String userId) {
    return FirebaseFirestore.instance
        .collection('content')
        .where('author', isEqualTo: FirebaseFirestore.instance.collection('users').doc(userId));
  }

  Widget _postsStream(String userId, {required bool ordered}) {
    final base = _postsQuery(userId);
    final stream = (ordered
            ? base.orderBy('createdAt', descending: true)
            : base.limit(_maxProfilePosts))
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey('posts-$userId-$ordered'),
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Posts for $userId failed: ${snapshot.error}');
          return _IndexError(error: '${snapshot.error}');
        }

        var docs = snapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No posts yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        // The unordered fallback has to be sorted here to look the same.
        if (!ordered) {
          docs = List.of(docs)
            ..sort((a, b) {
              final at = a.data()['createdAt'];
              final bt = b.data()['createdAt'];
              if (at is! Timestamp || bt is! Timestamp) return 0;
              return bt.compareTo(at);
            });
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final item = ContentItem.fromFirebase(docs[index].id, docs[index].data());
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ContentDetailScreen(item: item)),
              ),
              child: ContentThumbnail(item: item),
            );
          },
        );
      },
    );
  }

  /// Firestore caps a single `get` at its own page size, so the fallback reads
  /// a bounded slice and the profile shows the most recent of it.
  static const int _maxProfilePosts = 60;
}

/// Shown when a query needs a composite index that has not been deployed.
///
/// Firestore rejects the query outright, so the fix is a deploy rather than a
/// code change. The URL in the message is a direct link to the index editor.
class _IndexError extends StatelessWidget {
  const _IndexError({required this.error});

  final String error;

  static const String _help = 'This query needs a Firestore composite index. '
      'Run:\n\n  firebase deploy --only firestore:indexes';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(height: 12),
          const Text(
            'Could not load posts',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_help, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          // The SDK error is collapsed to a single line; the full text is
          // unreadable and it dominated the layout when shown in full.
          Text(
            error.split('\n').first,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
