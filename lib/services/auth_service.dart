import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/result.dart';
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