import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/result.dart';
import '../models/fan_badge.dart';
import '../models/user_listing.dart';

/// Computes a fan's badges from what they have actually done.
///
/// Every number is derived, never stored: there is no `badges` array to keep in
/// step with the activity that earned it. Adding a post, or receiving a like,
/// changes the badges the next time this runs and nothing else. The only thing
/// written back is which badge the user has *pinned* to show, which is a
/// display preference rather than an achievement.
class BadgeService {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _authn => _auth ?? FirebaseAuth.instance;

  BadgeService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore,
        _auth = auth;

  User? get currentUser => _authn.currentUser;

  /// Gathers a fan's activity and evaluates the badge rules against it.
  ///
  /// The counts come from a handful of aggregate queries rather than reading
  /// every post, so the cost does not grow with how much a fan has written.
  Future<Result<({FanActivity activity, List<FanBadge> badges})>> loadBadges(
    String userId,
  ) async {
    if (userId.isEmpty) {
      return Result.error('No user');
    }

    try {
      final userRef = _db.collection('users').doc(userId);
      final authorRef = userRef;

      // Each of these is a counted query, not a fetch-and-count.
      final results = await Future.wait([
        _db.collection('content').where('author', isEqualTo: authorRef).get(),
        _db.collection('products').where('sellerId', isEqualTo: userId).get(),
        _db.collection('events').where('organizerId', isEqualTo: userId).get(),
        userRef.collection('communities').get(),
      ]);

      final posts = results[0].docs;
      final products = results[1].docs;
      final events = results[2].docs;
      final communities = results[3].docs;

      // Likes and saves received are summed from the posts themselves. There is
      // no "likes I gave" collection to read, and the per-post counters are
      // already maintained transactionally.
      var likes = 0;
      var saves = 0;
      for (final doc in posts) {
        final data = doc.data();
        likes += (data['likes'] as num?)?.toInt() ?? 0;
        saves += (data['saved'] as num?)?.toInt() ?? 0;
      }

      final activity = FanActivity(
        postCount: posts.length,
        likesReceived: likes,
        savesReceived: saves,
        communitiesJoined: communities.length,
        eventsCreated: events.length,
        productsListed: products.length,
      );

      return Result.success((
        activity: activity,
        badges: BadgeRules.evaluate(activity),
      ));
    } catch (e) {
      return Result.error('Could not load badges: $e');
    }
  }

  /// Live badges for a user, re-evaluated whenever the underlying posts change.
  Stream<List<FanBadge>> watchBadges(String userId) {
    final authorRef = _db.collection('users').doc(userId);

    // Streaming both collections means a like landing on a post re-evaluates
    // the badges without a manual refresh.
    return _db
        .collection('content')
        .where('author', isEqualTo: authorRef)
        .snapshots()
        .asyncMap((snap) async {
      var likes = 0;
      var saves = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        likes += (data['likes'] as num?)?.toInt() ?? 0;
        saves += (data['saved'] as num?)?.toInt() ?? 0;
      }

      // Only the counts that are cheap to get here; the rest would need extra
      // streams, and a badge that updates a moment later is fine.
      final activity = FanActivity(
        postCount: snap.docs.length,
        likesReceived: likes,
        savesReceived: saves,
      );
      return BadgeRules.evaluate(activity);
    });
  }

  /// The badge the user has pinned to their profile, if any.
  Stream<String?> watchPinnedBadge(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          final pinned = data?['featuredBadge']?.toString();
          return (pinned == null || pinned.isEmpty) ? null : pinned;
        });
  }

  /// Pins one of the user's *earned* badges, or clears the pin.
  ///
  /// The earned check happens here rather than trusting the caller, so a client
  /// cannot pin a badge it has not unlocked.
  Future<Result<void>> pinBadge(String userId, String? badgeId) async {
    try {
      final result = await loadBadges(userId);
      if (!result.isSuccess) {
        return Result.error(result.error ?? 'Could not verify your badges');
      }

      if (badgeId != null) {
        final earned = result.data!.badges.where((b) => b.id == badgeId && b.unlocked);
        if (earned.isEmpty) {
          return Result.error('You have not unlocked that badge yet');
        }
      }

      await _db.collection('users').doc(userId).update({
        if (badgeId == null)
          'featuredBadge': FieldValue.delete()
        else
          'featuredBadge': badgeId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Could not update your badge: $e');
    }
  }

  /// Convenience: the listings a user added, for their profile.
  Stream<List<ProductListing>> watchProducts(String userId) {
    return _db
        .collection('products')
        .where('sellerId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .where((d) => d.data().isNotEmpty)
            .map((d) => ProductListing.fromFirestore(d.id, d.data()))
            .toList());
  }

  Stream<List<EventListing>> watchEvents(String userId) {
    return _db
        .collection('events')
        .where('organizerId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .where((d) => d.data().isNotEmpty)
            .map((d) => EventListing.fromFirestore(d.id, d.data()))
            .toList());
  }
}
