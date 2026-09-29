import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/result.dart';
import 'notification_service.dart';

/// The three things a viewer can do to a post, and the counters behind them.
///
/// Every mutation runs inside a Firestore transaction that also reads the
/// signed-in user's `interactions` subcollection. That buys two things a bare
/// `FieldValue.increment` does not:
///
///  * **Idempotency.** A view is recorded once per user, ever. Reopening the
///    post, or opening it on a second device, does not inflate the count.
///  * **Atomicity.** Read-the-flag and write-the-counter cannot interleave with
///    another user doing the same, so the counter cannot drift.
///
/// The counters themselves are read back through a snapshot stream by the
/// calling screen, which is what makes likes and views live for everyone.
class EngagementService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  EngagementService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  DocumentReference _contentRef(String contentId) =>
      _firestore.collection('content').doc(contentId);

  DocumentReference _interactionRef(String contentId) =>
      _firestore.collection('users').doc(_auth.currentUser!.uid).collection('interactions').doc(contentId);

  /// `Transaction.get` returns a loosely typed snapshot in this SDK, so the
  /// data is narrowed to a map before any field is read.
  Map<String, dynamic>? _data(DocumentSnapshot<Object?> doc) =>
      doc.data() as Map<String, dynamic>?;

  /// The name to attribute an action to, preferring what the post document
  /// already carries so no extra read is needed inside the transaction.
  static String _displayName(Map<String, dynamic>? contentData, User user) {
    final creator = contentData?['creator']?.toString().trim();
    if (creator != null && creator.isNotEmpty) return creator;
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    return 'A fan';
  }

  /// Record that the current user viewed [contentId].
  ///
  /// Returns true when this call actually counted, false when the user had
  /// already viewed it. Safe to call on every open of a post.
  Future<Result<bool>> registerView(String contentId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return Result.error('You must be logged in to view content');
    }

    try {
      final counted = await _firestore.runTransaction<bool>((txn) async {
        final interactionRef = _interactionRef(contentId);
        final interaction = await txn.get(interactionRef);

        if (_data(interaction)?['viewed'] == true) {
          // Already counted for this user. Nothing to do.
          return false;
        }

        final contentRef = _contentRef(contentId);
        final content = await txn.get(contentRef);
        if (!content.exists) {
          // The post was deleted while it was open. Do not resurrect counters.
          return false;
        }

        txn.set(
          interactionRef,
          {'viewed': true, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
        txn.update(contentRef, {'views': FieldValue.increment(1)});
        return true;
      });

      return Result.success(counted);
    } catch (e) {
      return Result.error('Could not record the view: $e');
    }
  }

  /// Flip the current user's like on [contentId].
  ///
  /// Returns the resulting `liked` state so the caller can update its icon
  /// without guessing.
  Future<Result<bool>> toggleLike(String contentId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return Result.error('You must be logged in to like content');
    }

    try {
      final nowLiked = await _firestore.runTransaction<bool>((txn) async {
        final interactionRef = _interactionRef(contentId);
        final interaction = await txn.get(interactionRef);
        final wasLiked = _data(interaction)?['liked'] == true;
        final willLiked = !wasLiked;

        final contentRef = _contentRef(contentId);
        final content = await txn.get(contentRef);
        if (!content.exists) {
          throw StateError('Post no longer exists');
        }

        txn.set(
          interactionRef,
          {'liked': willLiked, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
        txn.update(contentRef, {'likes': FieldValue.increment(willLiked ? 1 : -1)});

        // The author is told inside the same transaction, so the notification
        // cannot be delivered without the like, or vice versa.
        if (willLiked) {
          final contentData = _data(content);
          final authorRef = contentData?['author'];
          final authorUid = authorRef is DocumentReference ? authorRef.id : null;

          if (authorUid != null) {
            NotificationService.writeInTransaction(
              txn,
              _firestore,
              authorUid,
              type: 'like',
              actorUid: user.uid,
              actorName: _displayName(contentData, user),
              contentId: contentId,
              contentTitle: contentData?['title']?.toString(),
            );
          }
        }
        return willLiked;
      });

      return Result.success(nowLiked);
    } catch (e) {
      return Result.error('Could not update the like: $e');
    }
  }

  /// Flip the current user's save on [contentId].
  Future<Result<bool>> toggleSave(String contentId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return Result.error('You must be logged in to save content');
    }

    try {
      final nowSaved = await _firestore.runTransaction<bool>((txn) async {
        final interactionRef = _interactionRef(contentId);
        final interaction = await txn.get(interactionRef);
        final wasSaved = _data(interaction)?['saved'] == true;
        final willSave = !wasSaved;

        final contentRef = _contentRef(contentId);
        final content = await txn.get(contentRef);
        if (!content.exists) {
          throw StateError('Post no longer exists');
        }

        txn.set(
          interactionRef,
          {'saved': willSave, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
        txn.update(contentRef, {'saved': FieldValue.increment(willSave ? 1 : -1)});

        // A save is as much an endorsement as a like, so the author is told -
        // and inside the same transaction, so the two cannot diverge.
        if (willSave) {
          final contentData = _data(content);
          final authorRef = contentData?['author'];
          final authorUid = authorRef is DocumentReference ? authorRef.id : null;

          if (authorUid != null) {
            NotificationService.writeInTransaction(
              txn,
              _firestore,
              authorUid,
              type: 'save',
              actorUid: user.uid,
              actorName: _displayName(contentData, user),
              contentId: contentId,
              contentTitle: contentData?['title']?.toString(),
            );
          }
        }
        return willSave;
      });

      return Result.success(nowSaved);
    } catch (e) {
      return Result.error('Could not update your saved list: $e');
    }
  }

  /// Live counters for [contentId], so a like from another device appears
  /// without a refresh.
  Stream<ContentCounts> watchCounts(String contentId) {
    return _contentRef(contentId).snapshots().map((doc) => _countsFrom(doc));
  }

  /// Extracts the counter fields, tolerating a missing document.
  static ContentCounts _countsFrom(DocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const ContentCounts();
    return ContentCounts(
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      views: (data['views'] as num?)?.toInt() ?? 0,
      comments: (data['comments'] as num?)?.toInt() ?? 0,
      saved: (data['saved'] as num?)?.toInt() ?? 0,
    );
  }

  /// Live counters for a whole page of posts, keyed by document id.
  ///
  /// The feed patches these onto the items it already has, rather than
  /// re-sorting on every change, so a like arriving from another user does not
  /// make the whole feed jump around under the reader.
  ///
  /// Firestore caps an `in` query at 30 values, so larger feeds are watched in
  /// chunks and the results are merged.
  Stream<Map<String, ContentCounts>> watchCountsFor(Iterable<String> contentIds) {
    final ids = contentIds.toList(growable: false);
    if (ids.isEmpty) {
      return Stream.value(const {});
    }

    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += _maxInQuery) {
      chunks.add(ids.sublist(i, (i + _maxInQuery).clamp(0, ids.length)));
    }

    return Stream.fromIterable(chunks)
        .asyncExpand((chunk) => _firestore
            .collection('content')
            .where(FieldPath.documentId, whereIn: chunk)
            .snapshots())
        .map((snap) {
      final out = <String, ContentCounts>{};
      for (final doc in snap.docs) {
        out[doc.id] = _countsFrom(doc);
      }
      return out;
    });
  }

  /// Firestore's hard limit on the number of values in an `in` clause.
  static const int _maxInQuery = 30;

  /// Loads which posts the user has viewed, liked or saved.
  Future<InteractionSet> loadInteractions() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const InteractionSet();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('interactions')
          .get();

      return InteractionSet.from(snapshot);
    } catch (_) {
      return const InteractionSet();
    }
  }
}

/// The live counters on a post.
class ContentCounts {
  const ContentCounts({
    this.likes = 0,
    this.views = 0,
    this.comments = 0,
    this.saved = 0,
  });

  final int likes;
  final int views;
  final int comments;
  final int saved;
}

/// Which of a post's actions the current user has taken.
class InteractionSet {
  const InteractionSet({this.viewed = const {}, this.liked = const {}, this.saved = const {}});

  final Set<String> viewed;
  final Set<String> liked;
  final Set<String> saved;

  static InteractionSet from(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final viewed = <String>{};
    final liked = <String>{};
    final saved = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['viewed'] == true) viewed.add(doc.id);
      if (data['liked'] == true) liked.add(doc.id);
      if (data['saved'] == true) saved.add(doc.id);
    }

    return InteractionSet(viewed: viewed, liked: liked, saved: saved);
  }
}
