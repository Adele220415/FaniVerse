import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_roles.dart';
import '../core/constants/categories.dart';
import '../core/constants/cloudinary_config.dart';
import '../core/appearance_controller.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/media_upload_service.dart';
import '../widgets/content_thumbnail.dart';
import '../widgets/media_upload_tile.dart';
import 'badge_picker_screen.dart';
import 'help_screen.dart';
import 'wallpaper_settings_screen.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_listings.dart';
import 'content_detail_screen.dart';
import 'edit_categories_screen.dart';
import 'notifications_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import '../models/user_model.dart';
import '../models/content_item.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService authService;

  const ProfileScreen({
    super.key,
    required this.authService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MediaUploadService _media = MediaUploadService();
  UserModel? _userModel;
  bool _isLoading = true;
  bool _uploadingAvatar = false;
  List<ContentItem> _userPosts = [];
  List<ContentItem> _savedItems = [];

  /// Whether to offer Admin in the header's overflow menu.
  ///
  /// Read from the role document, never from the signed-in account's email.
  /// The email is public and ships in the binary, so matching on it would put
  /// the admin entry behind a check anyone could satisfy by claiming that
  /// address. The Firestore rules enforce admin independently; this only
  /// decides whether the menu shows the row.
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = widget.authService.currentUser;
    if (user != null) {
      final result = await widget.authService.getUserData(user.uid);
      if (result.isSuccess && mounted) {
        setState(() {
          _userModel = result.data;
          _isLoading = false;
        });
        _loadUserPosts();
        _loadSavedItems();
      }
    }
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await widget.authService.getCurrentUserRole();
    if (!mounted) return;
    setState(() => _isAdmin = AppRoles.isAdmin(role));
  }

  Future<void> _loadUserPosts() async {
    final uid = widget.authService.currentUser?.uid;
    if (uid == null) return;

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final snapshot = await _firestore
          .collection('content')
          .where('author', isEqualTo: userRef)
          .limit(20)
          .get();

      final posts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ContentItem.fromFirebase(doc.id, data);
      }).toList();

      if (mounted) {
        setState(() {
          _userPosts = posts;
        });
      }
    } catch (e) {
      print('Error loading user posts: $e');
    }
  }

  Future<void> _loadSavedItems() async {
    final uid = widget.authService.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('interactions')
          .where('saved', isEqualTo: true)
          .limit(20)
          .get();

      final savedIds = snapshot.docs.map((doc) => doc.id).toList();
      if (savedIds.isEmpty) return;

      final contentSnapshot = await _firestore
          .collection('content')
          .where(FieldPath.documentId, whereIn: savedIds)
          .get();

      final items = contentSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ContentItem.fromFirebase(doc.id, data);
      }).toList();

      if (mounted) {
        setState(() {
          _savedItems = items;
        });
      }
    } catch (e) {
      print('Error loading saved items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileInfo(),
            _buildStats(),
            // Merchandise and events live in tabs rather than as stacked
            // sections, so all four kinds of content are reachable from the top.
            _buildTabs(widget.authService.currentUser?.uid ?? ''),
            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
    );
  }

  /// The title and the overflow menu live in the app bar, on the same line as
  /// the back button.
  ///
  /// The leading slot is reserved whether or not there is a back arrow, so the
  /// centred title does not shift sideways depending on how this screen was
  /// reached. With a 48px back button and a 48px menu button the two balance,
  /// which is what makes the title land on the screen's true centre rather than
  /// on the centre of the remaining space.
  AppBar _buildAppBar() {
    final canPop = Navigator.canPop(context);

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: const Text(
        'Profile',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      leading: canPop
          // Present because this screen is also pushed from Search and from the
          // home header. Without it those entry points are dead ends.
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
            )
          // An empty slot of the same width, to keep the title centred.
          : const SizedBox(width: 48),
      actions: [_buildOverflowMenu()],
    );
  }

  /// The header's three-dot menu.
  ///
  /// Notifications is the one entry that is not a navigation push - it opens a
  /// sheet, because a bell in the corner is expected to stay where it is.
  Widget _buildOverflowMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
      tooltip: 'More',
      color: AppColors.elevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'settings':
            _showSettingsBottomSheet();
            break;
          case 'help':
            _push(const HelpScreen());
            break;
          case 'badges':
            _push(const BadgePickerScreen());
            break;
          case 'categories':
            _openCategoriesEditor();
            break;
          case 'notifications':
            _push(const NotificationsScreen());
            break;
          case 'admin':
            _push(const AdminDashboardScreen());
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'settings',
          child: _MenuRow(icon: Icons.settings_outlined, label: 'Settings'),
        ),
        // Admin lives here rather than in the settings sheet, which every
        // reader can open. One entry, in the menu that is already about
        // uncommon actions.
        //
        // Hidden rather than disabled for a non-admin: a visible greyed-out
        // row would tell every fan the section exists and that they are not
        // allowed into it, which advertises the feature and invites a probe.
        if (_isAdmin)
          const PopupMenuItem<String>(
            value: 'admin',
            child: _MenuRow(
              icon: Icons.shield_outlined,
              label: 'Admin',
              emphasis: AppColors.primaryLight,
            ),
          ),
        const PopupMenuItem<String>(
          value: 'help',
          child: _MenuRow(icon: Icons.help_outline, label: 'Help & Support'),
        ),
        const PopupMenuItem<String>(
          value: 'badges',
          child: _MenuRow(icon: Icons.workspace_premium_outlined, label: 'Badges'),
        ),
        const PopupMenuItem<String>(
          value: 'categories',
          child: _MenuRow(icon: Icons.interests_outlined, label: 'Categories'),
        ),
        const PopupMenuItem<String>(
          value: 'notifications',
          child: _NotificationsMenuRow(),
        ),
      ],
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Opens the category editor and reloads the profile if it was changed.
  ///
  /// The reload matters: the chips used to be rendered on this screen from the
  /// cached [_userModel], and the stats and tabs still are. Returning without a
  /// reload would leave that model - and anything derived from it - stale.
  Future<void> _openCategoriesEditor() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditCategoriesScreen()),
    );

    if (changed == true && mounted) {
      await _loadUserData();
    }
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Tapping the avatar uploads a new picture straight to Cloudinary.
            _uploadingAvatar
                ? const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: SizedBox(
                      height: 26,
                      width: 26,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : UserAvatar(
                    // Your own avatar is an upload target, not a link, so the
                    // navigate-on-tap behaviour is suppressed.
                    userId: _userModel?.id ?? '',
                    imageUrl: _userModel?.profileImage ?? '',
                    displayName: _userModel?.name ?? '',
                    username: _userModel?.username ?? '',
                    radius: 50,
                    onTap: _changeProfilePicture,
                  ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showEditProfileBottomSheet(),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _userModel?.username ?? 'User',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _userModel?.email ?? '',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        if (_userModel?.bio != null && _userModel!.bio!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _userModel!.bio!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      // Tight, because the stats sit directly under the bio rather than in their
      // own band. The old 24px top and bottom pushed the tabs a full screen
      // fold further down than they needed to be.
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Posts', _userPosts.length.toString()),
          _buildStatItem('Total Likes', _formatCount(_totalLikes)),
          _buildStatItem('Saved', _savedItems.length.toString()),
        ],
      ),
    );
  }

  /// Summed from the loaded posts rather than stored on the user document, so
  /// the number can never drift from the posts that earned it.
  int get _totalLikes => _userPosts.fold<int>(0, (sum, post) => sum + post.likes);

  String _formatCount(int value) {
    if (value < 1000) return '$value';
    if (value < 1000000) {
      final k = (value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1);
      return '${k}K';
    }
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// The four tabs from the profile sketch: My posts / Saved / Events /
  /// Merchandise.
  ///
  /// Events and Merchandise were previously sections stacked *below* the tabs,
  /// which meant they were a long scroll past two fixed-height grids and could
  /// not be reached without knowing they were down there. As tabs they are
  /// visible and self-evident.
  Widget _buildTabs(String userId) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primaryLight,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'My posts'),
              Tab(text: 'Saved'),
              Tab(text: 'Events'),
              Tab(text: 'Merchandise'),
            ],
          ),
          SizedBox(
            // Tall enough for a 3-wide grid plus breathing room, and it stays
            // scrollable inside itself.
            height: 460,
            child: TabBarView(
              children: [
                _buildPostsGrid(_userPosts, isOwned: true),
                _buildPostsGrid(_savedItems, isOwned: false),
                // canEdit is true here: this is always your own profile. The
                // gate still matters because UserProfileScreen - a different
                // screen - reuses these widgets read-only.
                UserEventsSection(userId: userId, canEdit: true, embedded: true),
                UserMerchandiseSection(userId: userId, canEdit: true, embedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(List<ContentItem> items, {required bool isOwned}) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No content yet',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => _showContentDetailModal(item, isOwned: isOwned),
          child: Container(
            color: Colors.grey.shade800,
            child: ContentThumbnail(item: item),
          ),
        );
      },
    );
  }

  /// Opens the shared detail screen.
  ///
  /// This used to inline a second copy of the detail view, which is why the
  /// profile page showed a plain image with no slideshow, no video controls and
  /// no live counters. One screen, one behaviour.
  void _showContentDetailModal(ContentItem item, {required bool isOwned}) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(
          item: item,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    ).then((_) {
      // The post may have been edited or deleted from inside the detail
      // screen, so both lists are re-read on the way back.
      _loadUserPosts();
      _loadSavedItems();
    });
  }

  /// Pick an image, upload it to Cloudinary, and write the resulting URL to
  /// `users/{uid}.profileImage`.
  Future<void> _changeProfilePicture() async {
    if (_uploadingAvatar) return;

    // Without a preset there is nowhere to upload to, so say why rather than
    // opening a picker that would fail on submit.
    if (!CloudinaryConfig.isConfigured) {
      _showSnack(CloudinaryConfig.missingReason!, isError: true);
      return;
    }

    setState(() => _uploadingAvatar = true);
    final result = await _media.pickAndUploadImage(folder: 'faniverse/avatars');
    if (!mounted) return;
    setState(() => _uploadingAvatar = false);

    if (!result.isSuccess) {
      _showSnack(result.error ?? 'Upload failed', isError: true);
      return;
    }

    // Null means the user dismissed the picker without choosing a file.
    final upload = result.data;
    if (upload == null) return;

    final saved = await _media.updateProfileImage(upload.url);
    if (!mounted) return;

    if (saved.isSuccess) {
      _showSnack('Profile picture updated');
      _loadUserData();
    } else {
      _showSnack(saved.error ?? 'Could not save your profile picture', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  void _showEditProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditProfileBottomSheet(
        userModel: _userModel,
        authService: widget.authService,
        onSave: () {
          _loadUserData();
        },
      ),
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SettingsBottomSheet(
        authService: widget.authService,
      ),
    );
  }
}

/// One row in the profile header's three-dot menu.
///
/// A private widget rather than a bare [ListTile] because PopupMenuItem has no
/// inset of its own, and the default tile metrics put the icon hard against the
/// menu's edge where it reads as a divider.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.emphasis,
    this.trailing,
  });

  final IconData icon;
  final String label;

  /// Optional accent for the one entry that should stand out.
  final Color? emphasis;

  /// Optional right-aligned widget, e.g. the notifications unread count.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = emphasis ?? AppColors.textPrimary;

    return Row(
      children: [
        Icon(icon, size: 20, color: emphasis ?? AppColors.textSecondary),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: emphasis != null ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

/// The notifications entry, carrying its unread count.
///
/// The header used to show a `NotificationBell` inline, which put the unread
/// number on screen at all times. Folding it into a menu would otherwise lose
/// that entirely - a fan with 12 unread would have no reason to open the menu -
/// so the count moves onto the row instead.
///
/// It reads the same stream the list does, so the number here cannot disagree
/// with what is actually unread.
class _NotificationsMenuRow extends StatelessWidget {
  const _NotificationsMenuRow();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService().watchUnreadCount(),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;

        return _MenuRow(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          trailing: unread > 0 ? _count(unread) : null,
        );
      },
    );
  }

  Widget _count(int unread) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      constraints: const BoxConstraints(minWidth: 20),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        // 99+ rather than the raw number, so a runaway counter cannot stretch
        // the menu row out to the width of the sheet.
        unread > 99 ? '99+' : '$unread',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class EditProfileBottomSheet extends StatefulWidget {
  final UserModel? userModel;
  final AuthService authService;
  final VoidCallback onSave;

  const EditProfileBottomSheet({
    super.key,
    required this.userModel,
    required this.authService,
    required this.onSave,
  });

  @override
  State<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<EditProfileBottomSheet> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _profileImageController;
  late List<String> _selectedCategories;

  final MediaUploadService _media = MediaUploadService();
  bool _uploadingPicture = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.userModel?.username ?? '');
    _bioController = TextEditingController(text: widget.userModel?.bio ?? '');
    _profileImageController = TextEditingController(text: widget.userModel?.profileImage ?? '')
      ..addListener(_onProfileImageChanged);
    _selectedCategories = List<String>.from(widget.userModel?.categories ?? []);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _profileImageController
      ..removeListener(_onProfileImageChanged)
      ..dispose();
    super.dispose();
  }

  // The upload tile is driven off the controller's text, so it needs a rebuild
  // whenever that text changes - including when an upload writes to it.
  void _onProfileImageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickProfilePicture() async {
    if (_uploadingPicture) return;

    if (!CloudinaryConfig.isConfigured) {
      _showBottomSheetSnack(CloudinaryConfig.missingReason!, isError: true);
      return;
    }

    setState(() => _uploadingPicture = true);
    final result = await _media.pickAndUploadImage(folder: 'faniverse/avatars');
    if (!mounted) return;
    setState(() => _uploadingPicture = false);

    if (!result.isSuccess) {
      _showBottomSheetSnack(result.error ?? 'Upload failed', isError: true);
      return;
    }

    final upload = result.data;
    if (upload == null) return;

    // Only fills the field. The URL reaches Firestore on Save, alongside the
    // rest of the profile edit, so a single update commits everything.
    _profileImageController.text = upload.url;
  }

  void _showBottomSheetSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = AppCategories.all;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              MediaUploadTile(
                label: 'Profile picture',
                icon: Icons.person_outline,
                isImage: true,
                url: _profileImageController.text.trim(),
                isUploading: _uploadingPicture,
                onPick: _pickProfilePicture,
                onRemove: _profileImageController.clear,
                helperText: 'Stored in users.profileImage',
              ),
              const SizedBox(height: 20),
              const Text(
                'My Fandom Categories',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category.toUpperCase()),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: AppColors.background,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final uid = widget.authService.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'profileImage': _profileImageController.text.trim(),
        'categories': _selectedCategories,
      });

      widget.onSave();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }
}

/// The settings sheet.
///
/// Stateless as of removing the Admin row: it used to read the reader's role to
/// decide whether to show that entry, and nothing else here depends on the
/// role.
class SettingsBottomSheet extends StatelessWidget {
  final AuthService authService;

  const SettingsBottomSheet({
    super.key,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 20),
          // No Admin row here any more. It was the one privileged entry in a
          // list every reader can open, and it duplicated what the profile
          // header's overflow menu already offers - the same control, in two
          // places, one of which is three taps into a general settings sheet.
          // The menu entry is the single home for it, and the rules enforce
          // admin independently of whatever the UI chooses to show.
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            title: const Text('Notifications', style: TextStyle(color: AppColors.textPrimary)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications settings coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.wallpaper_outlined, color: AppColors.textPrimary),
            title: const Text('Wallpaper', style: TextStyle(color: AppColors.textPrimary)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              // Read the controller before popping the sheet: its context is
              // the sheet's, and the sheet is on its way away.
              //
              // The scope sits above the navigator, so a route pushed after the
              // pop can still reach it - which is why the settings sheet could
              // not when the scope only wrapped `home`.
              final appearance = context.appearance;
              Navigator.of(context).pop();
              if (appearance == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wallpaper is unavailable right now')),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WallpaperSettingsScreen(appearance: appearance),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textPrimary),
            title: const Text('Privacy', style: TextStyle(color: AppColors.textPrimary)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy settings coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.textPrimary),
            title: const Text('Help & Support', style: TextStyle(color: AppColors.textPrimary)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help center coming soon')),
              );
            },
          ),
          const Divider(),
          // Bottom padding inside the sheet's own bounds, so the last row's
          // ink ripple is not clipped by the sheet's bottom edge.
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              await authService.logout();
              // Navigate back to AuthWrapper which handles redirect to login
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
