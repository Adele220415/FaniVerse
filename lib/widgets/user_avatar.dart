import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../screens/user_profile_screen.dart';

/// The initials shown when there is no avatar image to load.
///
/// Derived from the handle, falling back to the display name - the same order
/// the profile screen uses, so the fallback never disagrees with it.
String initialsFor(String handle, String name) {
  final source = handle.trim().isNotEmpty ? handle : name;
  final parts = source.split(RegExp(r'[\s_]+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

/// A user's avatar, which opens their profile when tapped.
///
/// There were four independent avatar implementations in the app, and three of
/// them were not tappable. Centralising it means every avatar in the app has
/// the same fallback behaviour *and* leads to the same place.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.userId,
    this.imageUrl = '',
    this.displayName = '',
    this.username = '',
    this.radius = 20,
    this.onTap,
  });

  /// Empty means the user is unknown, in which case the avatar is inert rather
  /// than opening a profile that cannot be loaded.
  final String userId;

  final String imageUrl;

  /// Used for the initials fallback and as the profile screen's app bar title
  /// before the document has loaded.
  final String displayName;

  final String username;

  final double radius;

  /// Overrides the default "open the profile" behaviour. Used by your own
  /// profile, where the avatar is an upload target instead.
  final VoidCallback? onTap;

  bool get _isOwn => userId.isNotEmpty && userId == FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final initials = initialsFor(username, displayName);

    final avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl.isEmpty
            ? _initials(initials)
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, _) => Container(color: AppColors.primary),
                errorWidget: (context, _, __) => _initials(initials),
              ),
      ),
    );

    // On your own profile the avatar already means "edit me", so it must not
    // also navigate to the profile you are standing on.
    final tappable = onTap ?? (userId.isEmpty || _isOwn ? null : () => openUserProfile(context, userId: userId, displayName: _label));

    if (tappable == null) return avatar;

    return GestureDetector(
      onTap: tappable,
      behavior: HitTestBehavior.opaque,
      child: avatar,
    );
  }

  String get _label {
    if (username.trim().isNotEmpty) return username;
    if (displayName.trim().isNotEmpty) return displayName;
    return 'Profile';
  }

  Widget _initials(String value) {
    return Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        value,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Opens [userId]'s profile.
///
/// Sets `isOwnProfile` when the target is the signed-in user, so the profile
/// can hide the edit affordances on the merchandise and events sections.
Future<void> openUserProfile(
  BuildContext context, {
  required String userId,
  required String displayName,
}) {
  if (userId.isEmpty) return Future.value();

  final isOwn = userId == FirebaseAuth.instance.currentUser?.uid;

  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => UserProfileScreen(
        userId: userId,
        displayName: displayName,
        isOwnProfile: isOwn,
      ),
    ),
  );
}
