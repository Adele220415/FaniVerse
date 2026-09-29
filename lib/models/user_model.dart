import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_roles.dart';

/// Mirrors the Firestore `users` document shape.
///
/// Every user - real or seeded - carries the same 12 fields so queries and UI
/// never have to null-check a field that happens to be missing. Documents
/// written before this schema (4 fields) still parse; [fromFirebase] fills in
/// defaults for anything absent.
class UserModel {
  final String id; // Firestore document ID, identical to [uid]
  final String uid;
  final String email;
  final String name;
  final String username;
  final String profileImage;
  final String bio;
  final List<String> categories;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.uid,
    required this.email,
    required this.name,
    required this.username,
    required this.profileImage,
    required this.bio,
    required this.categories,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  /// Defaults applied at registration so a new account is indistinguishable
  /// in shape from a seeded one.
  static const String defaultRole = AppRoles.fan;
  static const String defaultBio = '';

  /// Whether this account has admin privileges.
  ///
  /// Derived from [role] on every read rather than cached, so a promotion or a
  /// demotion takes effect the moment the document changes - there is no
  /// in-memory copy that can go stale behind a revoked role.
  bool get isAdmin => AppRoles.isAdmin(role);

  /// Whether this account is an ordinary fan.
  bool get isFan => !isAdmin;

  /// Builds the document for a freshly registered account.
  factory UserModel.forNewUser({
    required String id,
    required String name,
    required String email,
    List<String> categories = const [],
  }) {
    final now = DateTime.now();
    return UserModel(
      id: id,
      uid: id,
      email: email,
      name: name,
      username: deriveUsername(name, id),
      profileImage: defaultProfileImage(id),
      bio: defaultBio,
      categories: categories,
      role: defaultRole,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      lastLoginAt: now,
    );
  }

  /// `first_last_0000` style handle. The uid suffix keeps it unique without a
  /// server round-trip for a lookup.
  ///
  /// [uid] is defensively clamped rather than assumed to be long: this runs
  /// while parsing a document read from Firestore, and a short id there would
  /// otherwise throw and take the whole user list down with it.
  static String deriveUsername(String name, String uid) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final safe = base.isEmpty ? 'user' : base;
    final suffix = uid.length <= 4 ? uid : uid.substring(0, 4);
    return '${safe}_$suffix';
  }

  static String defaultProfileImage(String uid) => 'https://i.pravatar.cc/300?u=$uid';

  /// Accepts Timestamp, ISO-8601 String, epoch millis or DateTime. Seed data
  /// and the old client both wrote different types, so be tolerant.
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory UserModel.fromFirebase(Map<String, dynamic> data, String id) {
    final now = DateTime.now();
    final rawCategories = data['categories'];

    return UserModel(
      id: id,
      uid: data['uid'] as String? ?? id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      username: data['username'] as String? ?? deriveUsername(
        data['name'] as String? ?? 'user',
        id,
      ),
      profileImage: data['profileImage'] as String? ?? defaultProfileImage(id),
      bio: data['bio'] as String? ?? defaultBio,
      categories: rawCategories is List
          ? rawCategories.map((e) => e.toString()).toList()
          : const [],
      role: AppRoles.normalize(data['role'] as String?),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _parseTimestamp(data['createdAt']) ?? now,
      updatedAt: _parseTimestamp(data['updatedAt']) ?? _parseTimestamp(data['createdAt']) ?? now,
      lastLoginAt: _parseTimestamp(data['lastLoginAt']),
    );
  }

  /// Full document for creation. Timestamps use the server clock so they
  /// agree with seeded data regardless of device clock.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'username': username,
      'profileImage': profileImage,
      'bio': bio,
      'categories': categories,
      'role': role,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
  }

  /// Mutable fields only. `uid`, `email` and `createdAt` are excluded:
  /// `uid` and `createdAt` are immutable, and email is owned by Firebase Auth.
  ///
  /// `role` and `isActive` are excluded too, and this is a security boundary
  /// rather than tidiness. Firestore rules also pin both fields on update, so
  /// a client sending them would have the *whole write* rejected - a profile
  /// edit would fail with PERMISSION_DENIED and the user would see their
  /// avatar change bounce back with no explanation. Stripping them here means
  /// the ordinary edit path simply never touches them, and privilege can only
  /// be changed by an admin through [toAdminJson].
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'username': username,
      'profileImage': profileImage,
      'bio': bio,
      'categories': categories,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// The privileged fields, for an admin editing someone else's account.
  ///
  /// Kept separate from [toUpdateJson] so it is obvious at the call site that a
  /// privileged write is happening. It is a *full* document, not a patch, so it
  /// pairs with `.set(..., {merge: true})`; note it deliberately does not
  /// rewrite `uid`, `email` or `createdAt`.
  Map<String, dynamic> toAdminJson() {
    return {
      'name': name,
      'username': username,
      'profileImage': profileImage,
      'bio': bio,
      'categories': categories,
      'role': role,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool get hasSelectedCategories => categories.isNotEmpty;

  /// Fields present on a full-shape document, used to detect legacy docs.
  static const List<String> requiredFields = [
    'uid', 'name', 'email', 'username', 'profileImage', 'bio',
    'categories', 'role', 'isActive', 'createdAt', 'updatedAt', 'lastLoginAt',
  ];

  /// Which of [requiredFields] are missing from a raw document.
  static List<String> missingFields(Map<String, dynamic> data) {
    return requiredFields.where((f) => !data.containsKey(f)).toList();
  }
}
