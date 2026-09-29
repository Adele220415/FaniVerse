import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/result.dart';
import '../core/constants/app_roles.dart';
import '../models/user_model.dart';

// Result class is now imported from core/result.dart to avoid duplication

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validate password strength
  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  // Register user with email and password
  Future<Result<void>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (name.trim().isEmpty) {
        return Result.error('Name cannot be empty');
      }
      
      if (!_isValidEmail(email)) {
        return Result.error('Please enter a valid email address');
      }
      
      if (!_isValidPassword(password)) {
        return Result.error('Password must be at least 6 characters');
      }

      // Create user with Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Create user document in Firestore with the full 12-field schema, so a
      // real account is indistinguishable in shape from a seeded one.
      final userModel = UserModel.forNewUser(
        id: userCredential.user!.uid,
        email: email.trim(),
        name: name.trim(),
        categories: const [], // Empty initially, user will select later
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toJson());

      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          errorMessage = e.message ?? 'Registration failed';
      }
      return Result.error(errorMessage);
    } catch (e) {
      return Result.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Login user with email and password
  Future<Result<void>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (!_isValidEmail(email)) {
        return Result.error('Please enter a valid email address');
      }
      
      if (password.isEmpty) {
        return Result.error('Password cannot be empty');
      }

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // A deactivated account is signed out again immediately.
      //
      // Firebase Auth has no notion of a disabled user, so `isActive` is the
      // only signal available, and it lives in Firestore. Enforcing it here -
      // rather than only hiding the account in the admin UI - is what makes
      // deactivation an actual moderation action instead of a label. The sign
      // out happens before the check below so a rejected user never ends up in
      // a half-authenticated state.
      final active = await _isActive(_auth.currentUser!.uid);
      if (active != true) {
        await _auth.signOut();
        return Result.error(
          active == false
              ? 'This account has been deactivated.'
              : 'Could not verify this account. Please try again.',
        );
      }

      // Keep lastLoginAt current. A failure here must not fail the login, so
      // it is logged and swallowed.
      try {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Could not update lastLoginAt: $e');
      }

      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        default:
          errorMessage = e.message ?? 'Login failed';
      }
      return Result.error(errorMessage);
    } catch (e) {
      return Result.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Logout user
  Future<Result<void>> logout() async {
    try {
      await _auth.signOut();
      return Result.success(null);
    } catch (e) {
      return Result.error('Logout failed: ${e.toString()}');
    }
  }

  // Reset password
  Future<Result<void>> resetPassword(String email) async {
    try {
      if (!_isValidEmail(email)) {
        return Result.error('Please enter a valid email address');
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = e.message ?? 'Password reset failed';
      }
      return Result.error(errorMessage);
    } catch (e) {
      return Result.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Get user data from Firestore
  Future<Result<UserModel>> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        return Result.error('User not found');
      }

      final userModel = UserModel.fromFirebase(doc.data()!, doc.id);
      return Result.success(userModel);
    } catch (e) {
      return Result.error('Failed to fetch user data: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // Role
  // ---------------------------------------------------------------------------

  /// Whether the account is allowed in. Returns null when the answer could not
  /// be determined, which is deliberately distinct from `false`.
  ///
  /// The distinction matters at the call site: a Firestore failure must not be
  /// reported to the user as "your account has been deactivated", which would
  /// be both wrong and unactionable. Callers fail closed on null anyway -
  /// refusing entry is the safer of the two mistakes - but they can say
  /// something truthful about it.
  Future<bool?> _isActive(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      // A document written before the field existed is treated as active.
      // Backfilling it to false would lock out every legacy account.
      return doc.data()?['isActive'] as bool? ?? true;
    } catch (e) {
      debugPrint('Could not read isActive for $uid: $e');
      return null;
    }
  }

  /// The signed-in account's role, or [AppRoles.fan] when signed out.
  ///
  /// The value comes from the user's own Firestore document, which only the
  /// `seed/grant-admin.mjs` script and an authenticated admin can write - the
  /// rules pin `role` on update, so a client cannot promote itself. Reading it
  /// from the document rather than inferring it from the email address matters:
  /// the email is public, so treating it as proof of admin would mean anyone
  /// who learns it is one `update` away from full write access.
  ///
  /// Returns [AppRoles.fan] for a signed-out caller or on a read failure. A
  /// failed lookup must not grant privilege, so this fails closed.
  Future<String> getCurrentUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return AppRoles.fan;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return AppRoles.fan;

      final role = doc.data()?['role'] as String?;
      return AppRoles.normalize(role);
    } catch (e) {
      debugPrint('Could not read role for $uid: $e');
      return AppRoles.fan;
    }
  }

  /// Live role for the signed-in account.
  ///
  /// Emits [AppRoles.fan] when signed out so a caller can drive UI straight
  /// from the stream without pairing it against the auth state. Useful for
  /// hiding admin-only controls the moment a role changes, rather than at the
  /// next app launch.
  Stream<String> watchCurrentUserRole() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(AppRoles.fan);

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) =>
            AppRoles.normalize(snap.data()?['role'] as String?))
        .handleError((Object error) {
      debugPrint('Role stream failed for $uid: $error');
    });
  }

  /// The signed-in account's full record, or null when signed out.
  Future<UserModel?> getCurrentUserModel() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final result = await getUserData(uid);
    return result.data;
  }

  /// Whether the signed-in account currently holds the admin role.
  Future<bool> isCurrentUserAdmin() async =>
      AppRoles.isAdmin(await getCurrentUserRole());

  // Check if user has selected categories
  Future<Result<bool>> hasUserSelectedCategories() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.error('No user logged in');
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        return Result.error('User not found');
      }

      final data = doc.data();
      final categories = data?['categories'] as List<dynamic>?;
      final hasCategories = categories != null && categories.isNotEmpty;

      return Result.success(hasCategories);
    } catch (e) {
      return Result.error('Failed to check categories: ${e.toString()}');
    }
  }

  // Update user data
  Future<Result<void>> updateUserData(UserModel userModel) async {
    try {
      // toUpdateJson() omits uid/email/createdAt so a profile edit can never
      // rewrite the original registration time.
      await _firestore
          .collection('users')
          .doc(userModel.id)
          .update(userModel.toUpdateJson());
      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to update user data: ${e.toString()}');
    }
  }

  // Update user categories
  Future<Result<void>> updateUserCategories(List<String> categories) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.error('No user logged in');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'categories': categories,
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to update categories: ${e.toString()}');
    }
  }

  // Update user profile (username and bio)
  Future<Result<void>> updateUserProfile({
    required String username,
    required String bio,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.error('No user logged in');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'username': username.trim(),
        'bio': bio.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to update profile: ${e.toString()}');
    }
  }

  /// Top up documents created before the 12-field schema. Safe to call
  /// repeatedly: existing values are never overwritten, only absent fields
  /// are added. Returns the number of documents backfilled.
  Future<Result<int>> backfillLegacyUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      var patched = 0;

      for (final doc in snapshot.docs) {
        // doc.data() is non-nullable in this cloud_firestore version.
        final data = doc.data();
        if (data.isEmpty) continue;

        final missing = UserModel.missingFields(data);
        if (missing.isEmpty) continue;

        final model = UserModel.fromFirebase(data, doc.id);
        final patch = <String, dynamic>{};

        // Only add what is genuinely absent.
        for (final field in missing) {
          switch (field) {
            case 'uid':
              patch['uid'] = doc.id;
            case 'username':
              patch['username'] = model.username;
            case 'profileImage':
              patch['profileImage'] = model.profileImage;
            case 'bio':
              patch['bio'] = model.bio;
            case 'role':
              patch['role'] = model.role;
            case 'isActive':
              patch['isActive'] = model.isActive;
            case 'categories':
              patch['categories'] = model.categories;
            case 'createdAt':
              patch['createdAt'] = model.createdAt;
            case 'updatedAt':
              patch['updatedAt'] = FieldValue.serverTimestamp();
            case 'lastLoginAt':
              patch['lastLoginAt'] = FieldValue.serverTimestamp();
          }
        }

        await doc.reference.update(patch);
        patched++;
      }

      return Result.success(patched);
    } catch (e) {
      return Result.error('Backfill failed: ${e.toString()}');
    }
  }

  // Delete user account
  Future<Result<void>> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.error('No user logged in');
      }

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete user from Firebase Auth
      await user.delete();
      
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.error(e.message ?? 'Account deletion failed');
    } catch (e) {
      return Result.error('An unexpected error occurred: ${e.toString()}');
    }
  }
}