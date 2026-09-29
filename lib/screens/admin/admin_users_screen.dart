import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_roles.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import 'admin_forms.dart';

/// User administration: deactivate accounts and see who holds which role.
///
/// There is deliberately no delete. A Firestore delete cannot be undone from
/// the app, and removing a user document would orphan every post, product and
/// event they created - the content would still exist with an `author`
/// reference pointing at a uid that no longer resolves, which is exactly the
/// broken state the `authorId` plumbing in `ContentItem` was written to
/// detect. Deactivation is reversible and leaves the content intact.
///
/// Role assignment is likewise constrained. There is one admin, created out of
/// band by `seed/grant-admin.mjs`, and this screen can neither promote a
/// second one nor demote the first: either would make the installation
/// unadministrable without a console change. So the only editable role is the
/// fan one, and the control is a single explanatory line rather than a
/// disabled dropdown.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _admin = AdminService();

  List<UserModel>? _users;
  String? _error;
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final result = await _admin.listUsers();

    if (!mounted) return;
    setState(() {
      _loading = false;
      _users = result.data;
      _error = result.isSuccess ? null : result.error;
    });
  }

  /// Admins first, then a case-insensitive filter on name, username and email.
  ///
  /// Admins sort first regardless of the query so the admin account is always
  /// reachable - it is otherwise just one row among hundreds of fans.
  List<UserModel> get _visible {
    final users = _users ?? const <UserModel>[];
    final needle = _query.trim().toLowerCase();
    final filtered = needle.isEmpty
        ? users
        : users.where((u) {
            return u.name.toLowerCase().contains(needle) ||
                u.username.toLowerCase().contains(needle) ||
                u.email.toLowerCase().contains(needle);
          }).toList();

    filtered.sort((a, b) {
      if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return filtered;
  }

  Future<void> _toggleActive(UserModel user) async {
    final next = !user.isActive;

    if (!next) {
      // Deactivating is reversible but still a moderation action worth
      // confirming, since the user is signed out of nothing - it only blocks
      // them from the admin's view. Say what it does rather than "are you
      // sure".
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.elevated,
          title: const Text('Deactivate account?', style: TextStyle(color: AppColors.textPrimary)),
          content: Text(
            '${user.name} will no longer be able to sign in. '
            'Their content is kept and the account can be reactivated.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deactivate', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final result = await _admin.setUserActive(user.id, next);
    if (!mounted) return;
    showAdminResult(
      context,
      result,
      success: next ? 'Account reactivated' : 'Account deactivated',
    );
    if (result.isSuccess) _load();
  }

  Future<void> _changeRole(UserModel user) async {
    // The only other role is `fan`, and a user is either already a fan or is
    // the admin (whose role is locked). So this is a confirm, not a picker -
    // a dropdown with one reachable option would imply a choice that does not
    // exist.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text('Set role', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '${user.name} will be a ${AppRoles.fan}.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Set role'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await _admin.setUserRole(user.id, AppRoles.fan);
    if (!mounted) return;
    showAdminResult(context, result, success: 'Role updated');
    if (result.isSuccess) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Users', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            color: AppColors.textSecondary,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name, username or email',
                hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _Error(
        message: _error!,
        onRetry: _load,
      );
    }

    final users = _visible;
    if (users.isEmpty) {
      return Center(
        child: Text(
          _users!.isEmpty ? 'No users found.' : 'No users match "$_query".',
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (context, index) => _row(users[index]),
    );
  }

  Widget _row(UserModel user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: user.isAdmin ? AppColors.primary : AppColors.surface,
        child: Text(
          _initials(user),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.name.isEmpty ? user.username : user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: user.isActive ? AppColors.textPrimary : AppColors.textTertiary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                decoration: user.isActive ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          if (user.isAdmin) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else if (!user.isActive) ...[
            const SizedBox(width: 6),
            const Text(
              'INACTIVE',
              style: TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '@${user.username}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      // The admin's own controls are hidden rather than disabled: there is
      // nothing to change about the one admin account, and a greyed-out switch
      // would suggest the limitation is temporary.
      trailing: user.isAdmin
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _changeRole(user),
                  icon: const Icon(Icons.badge_outlined, size: 20),
                  color: AppColors.textSecondary,
                  tooltip: 'Set role to fan',
                ),
                IconButton(
                  onPressed: () => _toggleActive(user),
                  icon: Icon(
                    user.isActive ? Icons.person_off_outlined : Icons.person_outline,
                    size: 20,
                  ),
                  color: user.isActive ? AppColors.textSecondary : AppColors.success,
                  tooltip: user.isActive ? 'Deactivate' : 'Reactivate',
                ),
              ],
            ),
    );
  }

  static String _initials(UserModel user) {
    final source = user.name.trim().isNotEmpty ? user.name : user.username;
    final parts = source.split(RegExp(r'[\s_]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 36, color: AppColors.error),
            const SizedBox(height: 10),
            Text(
              'Could not load users',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.split('\n').first,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
