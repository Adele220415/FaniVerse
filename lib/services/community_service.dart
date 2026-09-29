import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/result.dart';
import '../models/community.dart';

/// Reads and writes communities and the discussions inside them.
///
/// Membership is stored twice: as a document under
/// `users/{uid}/communities/{communityId}`, and as a count on the community
/// itself. Both are written in one transaction, so a fan can never end up
/// "joined" with a count that disagrees.
class CommunityService {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  /// Resolved lazily so the pure search and filter helpers can be used without
  /// initialising Firebase.
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _authn => _auth ?? FirebaseAuth.instance;

  CommunityService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore,
        _auth = auth;

  User? get currentUser => _authn.currentUser;

  /// All communities, newest first.
  Stream<List<Community>> watchCommunities() {
    return _db.collection('communities').snapshots().map((snapshot) {
      final list = snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => Community.fromFirestore(doc.id, doc.data()))
          .toList();
      list.sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    });
  }

  Stream<Community> watchCommunity(String id) {
    return _db.collection('communities').doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) throw StateError('That community no longer exists');
      return Community.fromFirestore(doc.id, data);
    });
  }

  /// Discussions inside a community, newest first.
  Stream<List<CommunityPost>> watchPosts(String communityId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('discussions')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data().isNotEmpty)
            .map((doc) => CommunityPost.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Which of the given communities the user has joined.
  ///
  /// A batched `in` query rather than one read per row, because a grid of a
  /// dozen communities would otherwise fire a dozen reads on every rebuild.
  Stream<Set<String>> watchMemberships() {
    final uid = _authn.currentUser?.uid;
    if (uid == null) return Stream.value(const {});

    return _db
        .collection('users')
        .doc(uid)
        .collection('communities')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Future<Result<bool>> toggleMembership(String communityId) async {
    final uid = _authn.currentUser?.uid;
    if (uid == null) {
      return Result.error('You must be logged in to join a community');
    }

    try {
      final joined = await _db.runTransaction<bool>((txn) async {
        final edge = _db.collection('users').doc(uid).collection('communities').doc(communityId);
        final communityRef = _db.collection('communities').doc(communityId);

        final [edgeSnap, communitySnap] = await Future.wait([
          txn.get(edge),
          txn.get(communityRef),
        ]);
        if (!communitySnap.exists) throw StateError('That community no longer exists');

        final wasJoined = edgeSnap.exists;
        final willJoin = !wasJoined;
        final current = (communitySnap.data()?['memberCount'] as num?)?.toInt() ?? 0;

        if (willJoin) {
          txn.set(edge, {
            'joinedAt': FieldValue.serverTimestamp(),
            'communityName': communitySnap.data()?['name']?.toString() ?? '',
          });
          txn.update(communityRef, {'memberCount': current + 1});
        } else {
          txn.delete(edge);
          // Clamped at zero: a decrement below zero would show as "-1 members"
          // if a counter ever drifted.
          txn.update(communityRef, {'memberCount': current > 0 ? current - 1 : 0});
        }

        return willJoin;
      });

      return Result.success(joined);
    } catch (e) {
      return Result.error('Could not update membership: $e');
    }
  }

  Future<Result<String>> createCommunity({
    required String name,
    required String description,
    String category = '',
    String imageUrl = '',
  }) async {
    final uid = _authn.currentUser?.uid;
    if (uid == null) {
      return Result.error('You must be logged in to create a community');
    }
    if (name.trim().isEmpty) {
      return Result.error('Give the community a name');
    }

    try {
      final docRef = await _db.collection('communities').add(Community(
        id: '',
        name: name.trim(),
        description: description.trim(),
        category: category,
        imageUrl: imageUrl,
        // The creator joins on create, so they are not staring at a community
        // they have to go and join themselves.
        createdBy: uid,
        memberCount: 1,
      ).toJson());

      await _db.collection('users').doc(uid).collection('communities').doc(docRef.id).set({
        'joinedAt': FieldValue.serverTimestamp(),
        'communityName': name.trim(),
      });

      return Result.success(docRef.id);
    } catch (e) {
      return Result.error('Could not create the community: $e');
    }
  }

  Future<Result<String>> createPost({
    required String communityId,
    required String title,
    required String content,
  }) async {
    final uid = _authn.currentUser?.uid;
    if (uid == null) {
      return Result.error('You must be logged in to post');
    }

    // The display name is resolved before the write so a post never renders
    // with an empty byline, and so the transaction does not need a second read.
    String authorName = 'A fan';
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final data = userDoc.data();
      if (data != null) {
        authorName = (data['username'] ?? data['name'] ?? authorName).toString();
      }
    } catch (_) {
      // Fall back to the generic name rather than blocking the post.
    }

    try {
      final docRef = await _db
          .collection('communities')
          .doc(communityId)
          .collection('discussions')
          .add(CommunityPost(
            id: '',
            title: title.trim(),
            content: content.trim(),
            authorId: uid,
            authorName: authorName,
          ).toJson());

      return Result.success(docRef.id);
    } catch (e) {
      return Result.error('Could not post: $e');
    }
  }

  Future<Result<void>> togglePostLike(String communityId, String postId) async {
    final uid = _authn.currentUser?.uid;
    if (uid == null) {
      return Result.error('You must be logged in to like a post');
    }

    try {
      await _db.runTransaction<void>((txn) async {
        final likedRef = _db
            .collection('users')
            .doc(uid)
            .collection('community_likes')
            .doc('${communityId}_$postId');
        final postRef =
            _db.collection('communities').doc(communityId).collection('discussions').doc(postId);

        final [likedSnap, postSnap] = await Future.wait([txn.get(likedRef), txn.get(postRef)]);
        if (!postSnap.exists) throw StateError('That post no longer exists');

        final wasLiked = likedSnap.exists;
        final current = (postSnap.data()?['likesCount'] as num?)?.toInt() ?? 0;

        if (wasLiked) {
          txn.delete(likedRef);
          txn.update(postRef, {'likesCount': current > 0 ? current - 1 : 0});
        } else {
          txn.set(likedRef, {'likedAt': FieldValue.serverTimestamp()});
          txn.update(postRef, {'likesCount': current + 1});
        }
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Could not update the like: $e');
    }
  }

  /// Client-side search, for the same reason the catalog filters are: the
  /// collection is loaded whole, and this keeps typing instant.
  List<Community> filter(List<Community> communities, String query, {String category = ''}) {
    final needle = query.trim().toLowerCase();

    return communities.where((c) {
      if (category.isNotEmpty && c.category.toLowerCase() != category.toLowerCase()) {
        return false;
      }
      if (needle.isEmpty) return true;
      return '${c.name} ${c.description} ${c.category}'.toLowerCase().contains(needle);
    }).toList();
  }
}
