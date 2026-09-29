import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Only debugPrint is needed from here. Imported with `show` because
// flutter/foundation also exports a `Category` annotation, which collides with
// the app's own Category model.
import 'package:flutter/foundation.dart' show debugPrint;

import '../core/constants/app_roles.dart';
import '../core/result.dart';
import '../models/category.dart';
import '../models/content_item.dart';
import '../models/user_listing.dart';
import '../models/user_model.dart';
import 'category_service.dart';

/// Administrative read/write across the whole app.
///
/// ## Why this exists
///
/// Every other service in the app is scoped to "the signed-in user's own
/// rows": `CatalogService.createProduct` stamps your uid on the listing,
/// `ContentService` authors are checked against `selfRef()`, and so on. An
/// admin has to reach *other people's* rows, which none of those paths allow -
/// not because they are badly written, but because the ownership check is
/// correct for them.
///
/// So the admin path is separate and explicit rather than a set of
/// `if (isAdmin)` branches threaded through every service.
///
/// ## The client is not the security boundary
///
/// Every method here re-checks the caller's role before writing, which stops a
/// bug in the UI from escalating anyone. It is *not* what actually protects the
/// data: `firestore.rules` has a matching `isAdmin()` guard, and a caller that
/// simply omits that check gets PERMISSION_DENIED. The checks here exist to
/// turn a permission error into a readable message and to stop the admin
/// screens from offering actions that cannot succeed.
class AdminService {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  /// Both resolved lazily, so importing this class does not initialise Firebase.
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _authn => _auth ?? FirebaseAuth.instance;

  AdminService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore,
        _auth = auth;

  // ---------------------------------------------------------------------------
  // Role check
  // ---------------------------------------------------------------------------

  /// The signed-in uid, or null when signed out.
  String? get _authUid => _authn.currentUser?.uid;

  /// The signed-in account's role. Fails closed to [AppRoles.fan].
  Future<String> currentRole() async {
    final uid = _authUid;
    if (uid == null) return AppRoles.fan;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return AppRoles.fan;
      return AppRoles.normalize(doc.data()?['role'] as String?);
    } catch (e) {
      debugPrint('AdminService role read failed: $e');
      return AppRoles.fan;
    }
  }

  /// Whether the signed-in account may use the admin screens.
  Future<bool> isAdmin() async => AppRoles.isAdmin(await currentRole());

  /// Guard used by every mutating method. Returns an error result naming the
  /// reason, or null when the caller is allowed through.
  Future<Result<void>?> _requireAdmin() async {
    if (!await isAdmin()) {
      return Result.error('You do not have permission to do that');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------

  /// Every user, newest first. Admin-only.
  Future<Result<List<UserModel>>> listUsers({int limit = 200}) async {
    final denied = await _requireAdmin();
    if (denied != null) return Result.error(denied.error);

    try {
      final snapshot = await _db.collection('users').limit(limit).get();
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirebase(doc.data(), doc.id))
          .toList();
      users.sort((a, b) {
        // Admins first, then alphabetical, so the account you are looking for
        // is never buried under a few hundred fans.
        if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return Result.success(users);
    } catch (e) {
      return Result.error('Could not load users: $e');
    }
  }

  /// Sets a user's role.
  ///
  /// Refuses to touch the one admin account. There is a single admin by
  /// design, so demoting it would leave the app with nobody able to promote
  /// the next one, and promoting a second would make "who is the admin"
  /// ambiguous. Recovering from that needs a console change, which is a far
  /// worse outcome than a disabled toggle in the UI.
  Future<Result<void>> setUserRole(String userId, String role) async {
    final denied = await _requireAdmin();
    if (denied != null) return Result.error(denied.error);

    if (userId == _authUid) {
      return Result.error('You cannot change your own role');
    }
    if (AppRoles.isAdmin(role)) {
      return Result.error('There is only one admin account');
    }

    try {
      final ref = _db.collection('users').doc(userId);
      final snap = await ref.get();
      if (!snap.exists) return Result.error('That user no longer exists');

      if (UserModel.fromFirebase(snap.data()!, userId).isAdmin) {
        return Result.error('The admin role cannot be changed from the app');
      }

      await ref.update({
        'role': AppRoles.normalize(role),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not change the role: $e');
    }
  }

  /// Deactivates or reactivates an account.
  ///
  /// Deactivation is reversible and leaves the account's content in place.
  /// Hard deletion is deliberately not offered: it would orphan every post,
  /// product and event the user created, and a Firestore delete cannot be
  /// undone from the app.
  Future<Result<void>> setUserActive(String userId, bool active) async {
    final denied = await _requireAdmin();
    if (denied != null) return Result.error(denied.error);

    if (userId == _authUid) {
      return Result.error('You cannot deactivate your own account');
    }

    try {
      final ref = _db.collection('users').doc(userId);
      final snap = await ref.get();
      if (!snap.exists) return Result.error('That user no longer exists');

      if (UserModel.fromFirebase(snap.data()!, userId).isAdmin) {
        return Result.error('The admin account cannot be deactivated');
      }

      await ref.update({
        'isActive': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not update the account: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------

  Stream<List<ContentItem>> watchAllContent({int limit = 200}) {
    return _db
        .collection('content')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data().isNotEmpty)
            .map((doc) => ContentItem.fromFirebase(doc.id, doc.data()))
            .toList());
  }

  /// Deletes any post, whoever wrote it. The rules restrict ordinary deletes
  /// to the author, so this only succeeds for an admin.
  Future<Result<void>> deleteContent(String contentId) async {
    final denied = await _requireAdmin();
    if (denied != null) return Result.error(denied.error);

    try {
      await _db.collection('content').doc(contentId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not delete the post: $e');
    }
  }

  /// Edits a post's title, description and categories, whoever wrote it.
  Future<Result<void>> updateContentFields({
    required String contentId,
    required String title,
    required String description,
    required List<String> categories,
  }) async {
    final denied = await _requireAdmin();
    if (denied != null) return Result.error(denied.error);

    if (title.trim().isEmpty) {
      return Result.error('A post needs a title');
    }

    try {
      final normalised = categories
          .map((c) => c.trim().toLowerCase())
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();

      await _db.collection('content').doc(contentId).update({
        'title': title.trim(),
        'description': description.trim(),
        'category': normalised.isEmpty ? '' : normalised.first,
        'categories': normalised,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not save the post: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------------

  Stream<List<ProductListing>> watchAllProducts({int limit = 300}) {
    return _db
        .collection('products')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data().isNotEmpty)
            .map((doc) => ProductListing.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Deletes any listing. Seeded products have no `sellerId`, so the ordinary
  /// owner-only delete could never reach them; this can.
  Future<Result<void>> deleteProduct(String productId) async {
    final denied = await _requireAdmin();
    if (denied != null) return Result.error(denied.error);

    try {
      await _db.collection('products').doc(productId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not delete the product: $e');
    }
  }

  /// Updates a listing's name, description, price, stock and availability.
  Future<Result<void>> updateProductFields({
    required String productId,
    required String name,
    required String description,
    required double price,
    required int stockQuantity,
    required bool isAvailable,
  }) async {
    final denied = await _requireAdmin();
    if (denied != null) return Result.error(denied.error);

    if (name.trim().isEmpty) {
      return Result.error('A product needs a name');
    }
    if (price < 0) {
      return Result.error('Price cannot be negative');
    }
    if (stockQuantity < 0) {
      return Result.error('Stock cannot be negative');
    }

    try {
      await _db.collection('products').doc(productId).update({
        'name': name.trim(),
        'description': description.trim(),
        'price': price,
        'stockQuantity': stockQuantity,
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not save the product: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  Stream<List<EventListing>> watchAllEvents({int limit = 300}) {
    return _db
        .collection('events')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data().isNotEmpty)
            .map((doc) => EventListing.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<Result<void>> deleteEvent(String eventId) async {
    final denied = await _requireAdmin();
    if (denied != null) return Result.error(denied.error);

    try {
      await _db.collection('events').doc(eventId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not delete the event: $e');
    }
  }

  Future<Result<void>> updateEventFields({
    required String eventId,
    required String title,
    required String description,
    required String location,
    required String status,
  }) async {
    final denied = await _requireAdmin();
    if (denied != null) return Result.error(denied.error);

    if (title.trim().isEmpty) {
      return Result.error('An event needs a title');
    }

    try {
      await _db.collection('events').doc(eventId).update({
        'title': title.trim(),
        'description': description.trim(),
        'location': location.trim(),
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not save the event: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  /// Delegates to [CategoryService] so the built-in collision rules live in one
  /// place. Kept here so the admin screens have a single dependency.
  Future<Result<String>> addCategory(Category category) async {
    final denied = await _requireAdmin();
    if (denied != null) return Result.error(denied.error);
    return _categories().addCategory(category);
  }

  Future<Result<void>> updateCategory(Category category) async {
    final denied = await _requireAdmin();
    if (denied != null) return Result.error(denied.error);
    return _categories().updateCategory(category);
  }

  Future<Result<void>> deleteCategory(String id) async {
    final denied = await _requireAdmin();
    if (denied != null) return Result.error(denied.error);
    return _categories().deleteCategory(id);
  }

  CategoryService _categories() => CategoryService(firestore: _db);
}
