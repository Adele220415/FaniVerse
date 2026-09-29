import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_roles.dart';
import '../../services/admin_service.dart';
import 'admin_categories_screen.dart';
import 'admin_content_screen.dart';
import 'admin_events_screen.dart';
import 'admin_products_screen.dart';
import 'admin_users_screen.dart';

/// The admin hub, reached from the profile settings sheet.
///
/// This screen re-checks the role on entry rather than trusting the caller. It
/// is reachable by navigation, so the gate that matters is the one at the
/// destination - the settings sheet hides the entry point, and this refuses
/// entry. Either alone would be the wrong place to rely on; the rules are the
/// real boundary, and this exists so a fan who finds the route sees an
/// explanation instead of a screen full of failed queries.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _admin = AdminService();

  bool _checking = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final isAdmin = await _admin.isAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _checking = false;
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
              ? const _NotAdmin()
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    const _Header(),
                    const SizedBox(height: 8),
                    _tile(
                      icon: Icons.category_outlined,
                      title: 'Categories',
                      subtitle: 'Add and remove fandoms',
                      onTap: () => _open(const AdminCategoriesScreen()),
                    ),
                    _tile(
                      icon: Icons.people_outline,
                      title: 'Users',
                      subtitle: 'Assign roles, deactivate accounts',
                      onTap: () => _open(const AdminUsersScreen()),
                    ),
                    _tile(
                      icon: Icons.article_outlined,
                      title: 'Content',
                      subtitle: 'Edit or remove any post',
                      onTap: () => _open(const AdminContentScreen()),
                    ),
                    _tile(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Products',
                      subtitle: 'All merchandise, including seeded listings',
                      onTap: () => _open(const AdminProductsScreen()),
                    ),
                    _tile(
                      icon: Icons.event_outlined,
                      title: 'Events',
                      subtitle: 'All events, including seeded listings',
                      onTap: () => _open(const AdminEventsScreen()),
                    ),
                  ],
                ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryLight, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primaryLight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administrator',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppRoles.adminEmail,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotAdmin extends StatelessWidget {
  const _NotAdmin();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            const Text(
              'Admins only',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This account does not hold the admin role.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
