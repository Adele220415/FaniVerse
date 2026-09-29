import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/result.dart';
import '../models/user_model.dart';

/// A user plus the aggregate numbers shown on a profile.
///
/// Kept separate from [UserModel] because the totals are *derived* - summed
/// across the user's posts - rather than stored on the user document. Storing
/// them would mean every like anywhere in the app has to fan out to update a
/// second document, which is the kind of write amplification that eventually
/// drifts out of sync.
class UserProfile {
  const UserProfile({
    required this.user,
    this.postCount = 0,
    this.totalLikes = 0,
    this.totalViews = 0,
  });

  final UserModel user;
  final int postCount;
  final int totalLikes;
  final int totalViews;

  /// Initials for the avatar fallback, e.g. "Daniel Smith" -> "DS".
  String get initials {
    final source = user.username.trim().isNotEmpty ? user.username : user.name;
    final parts = source
        .split(RegExp(r'[\s_]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  UserProfile copyWith({int? postCount, int? totalLikes, int? totalViews}) =>
      UserProfile(
        user: user,
        postCount: postCount ?? this.postCount,
        totalLikes: totalLikes ?? this.totalLikes,
        totalViews: totalViews ?? this.totalViews,
      );
}

/// Finds users and assembles their aggregate stats.
///
/// ## How search works, and its limits
///
/// Firestore cannot do substring or fuzzy matching. Two approaches are used
/// together:
///
///  * **Prefix search** - `username >= 'query'` with `username < 'query\uf8ff'`.
///    This is a real indexed range query, so it scales, but it only matches
///    usernames that *start* with the query. Typing "dan" finds "daniel_1a2b"
///    but not "the_dan".
///  * **Name-ordered scan** - a bounded page of users ordered by `name`, then
///    filtered client-side for substring hits.
///
/// So prefix matches are always found, and substring matches are found among
/// the first [scanLimit] users alphabetically. A user whose name sorts late and
/// does not begin with the query can be missed. That is inherent to Firestore
/// without a search service; Algolia or Typesense would remove the limit, and
/// the swap point is [searchUsers] alone.
class UserDirectoryService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserDirectoryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  /// Search users by username prefix and by name substring.
  ///
  /// Two kinds of account are excluded: the signed-in user (you are not a search
  /// result for yourself, and it keeps the count honest) and any admin
  /// account, which should not be discoverable by fans.
  ///
  /// The admin filter is applied here in Dart rather than as a Firestore
  /// `where` clause on purpose. A `!=` clause is not selective in Firestore -
  /// it matches documents where the field is *absent* as well as where it
  /// differs, so `where('role', isNotEqualTo: 'admin')` would also drop every
  /// legacy document written before the field existed. Since every hit is
  /// parsed into a [UserModel] anyway, filtering the parsed object is both
  /// correct for missing fields and free of an extra composite index.
  Future<Result<List<UserModel>>> searchUsers(String query, {int limit = 25}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return Result.success(const []);
    }

    final me = _auth.currentUser?.uid;

    try {
      final seen = <String>{};
      final results = <UserModel>[];

      // 1. Indexed prefix search on username.
      final prefix = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: trimmed)
          .where('username', isLessThan: '$trimmed\uf8ff')
          .limit(limit)
          .get();

      for (final doc in prefix.docs) {
        if (doc.id == me) continue;
        final user = UserModel.fromFirebase(doc.data()!, doc.id);
        if (user.isAdmin) continue;
        seen.add(doc.id);
        results.add(user);
      }

      // 2. Substring pass over a bounded, name-ordered page.
      if (results.length < limit) {
        const scanLimit = 200;
        final byName = await _firestore
            .collection('users')
            .orderBy('name')
            .limit(scanLimit)
            .get();

        final needle = trimmed.toLowerCase();
        for (final doc in byName.docs) {
          if (results.length >= limit) break;
          if (doc.id == me || seen.contains(doc.id)) continue;

          final user = UserModel.fromFirebase(doc.data()!, doc.id);
          if (user.isAdmin) continue;

          final haystack = '${user.name} ${user.username}'.toLowerCase();
          if (haystack.contains(needle)) {
            seen.add(doc.id);
            results.add(user);
          }
        }
      }

      return Result.success(results);
    } catch (e) {
      return Result.error('Could not search users: $e');
    }
  }

  /// Live search. Emits an empty list for a blank query so the caller can show
  /// its idle state without special-casing null.
  ///
  /// A plain [Future] is the better fit for search-as-you-type: a stream would
  /// need explicit debouncing and cancellation, and a superseded request would
  /// still be able to paint stale results over newer ones.
  Future<List<UserModel>> searchUsersOrEmpty(String query) async {
    final result = await searchUsers(query);
    return result.data ?? const [];
  }

  /// Loads one user with their aggregate stats.
  ///
  /// [watch] streams it, so a post published while the profile is open updates
  /// the counts without a manual refresh.
  Stream<UserProfile> watchProfile(String userId) {
    final userRef = _firestore.collection('users').doc(userId);
    final postsQuery = _firestore
        .collection('content')
        .where('author', isEqualTo: userRef)
        .limit(100);

    return userRef.snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists) {
        throw StateError('That profile no longer exists');
      }

      final user = UserModel.fromFirebase(userDoc.data()!, userDoc.id);

      // Sum the counters rather than storing them, so they can never drift
      // from the posts they describe.
      final posts = await postsQuery.get();
      var likes = 0;
      var views = 0;
      for (final doc in posts.docs) {
        final data = doc.data();
        likes += (data['likes'] as num?)?.toInt() ?? 0;
        views += (data['views'] as num?)?.toInt() ?? 0;
      }

      return UserProfile(
        user: user,
        postCount: posts.docs.length,
        totalLikes: likes,
        totalViews: views,
      );
    });
  }
}
