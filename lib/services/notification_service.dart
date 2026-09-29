import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/result.dart';
import '../models/app_notification.dart';

/// Reads and manages the signed-in user's notifications.
///
/// Notifications live in `users/{uid}/notifications`, which is what makes the
/// in-app half of this work with no backend: the client that performs a like
/// writes a notification into the post author's subcollection inside the same
/// transaction, so the two can never disagree or half-apply.
class NotificationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('notifications');
  }

  /// All notifications, newest first.
  ///
  /// [limit] bounds the query because Firestore reads are billed and billed
  /// reads should not grow without limit as a user accumulates history.
  Stream<List<AppNotification>> watchNotifications({int limit = 50}) {
    final collection = _collection;
    if (collection == null) return Stream.value(const []);

    return collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data().isNotEmpty)
            .map((doc) => AppNotification.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// How many are unread. Computed client-side from the same stream the list
  /// uses, so the badge and the list can never disagree.
  Stream<int> watchUnreadCount() {
    return watchNotifications(limit: 200).map((items) => items.where((n) => !n.read).length);
  }

  Future<Result<void>> markRead(String notificationId) async {
    final collection = _collection;
    if (collection == null) {
      return Result.error('You must be logged in');
    }

    try {
      await collection.doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not mark the notification as read: $e');
    }
  }

  Future<Result<void>> markAllRead() async {
    final collection = _collection;
    if (collection == null) {
      return Result.error('You must be logged in');
    }

    try {
      final snapshot = await collection.where('read', isEqualTo: false).get();
      if (snapshot.docs.isEmpty) return Result.success(null);

      // Batched because write() caps at 500 operations.
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not mark notifications as read: $e');
    }
  }

  Future<Result<void>> remove(String notificationId) async {
    final collection = _collection;
    if (collection == null) {
      return Result.error('You must be logged in');
    }

    try {
      await collection.doc(notificationId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not delete the notification: $e');
    }
  }

  /// Writes a notification into [recipientUid]'s subcollection.
  ///
  /// **Call this from inside the transaction that performs the action** so the
  /// notification and the action are committed together. The document id is
  /// derived from (type, actor, target), which makes a repeat action
  /// overwrite rather than duplicate.
  static void writeInTransaction(
    Transaction txn,
    FirebaseFirestore firestore,
    String recipientUid, {
    required String type,
    required String actorUid,
    required String actorName,
    String? contentId,
    String? contentTitle,
  }) {
    // Nobody notifies themselves about their own action.
    if (recipientUid == actorUid) return;

    final notificationId = [
      type,
      actorUid,
      contentId ?? 'none',
    ].join('_');

    txn.set(
      firestore
          .collection('users')
          .doc(recipientUid)
          .collection('notifications')
          .doc(notificationId),
      {
        'type': type,
        'actorUid': actorUid,
        'actorName': actorName,
        'contentId': contentId,
        'contentTitle': contentTitle,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      // Overwrite rather than merge: a second like refreshes the timestamp
      // instead of resurrecting an already-read notification as unread.
      SetOptions(merge: true),
    );
  }
}
