import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/app_notification.dart';
import '../models/content_item.dart';
import '../services/notification_service.dart';
import '../widgets/user_avatar.dart';
import 'content_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.service});

  final NotificationService? service;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _service = widget.service ?? NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Clear-unread lives here rather than on every row, so a screen full
          // of notifications does not fill up with icons.
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _service.watchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _Empty(
              icon: Icons.cloud_off,
              title: 'Could not load notifications',
              subtitle: '${snapshot.error}',
            );
          }

          final notifications = snapshot.data ?? const <AppNotification>[];
          if (notifications.isEmpty) {
            return const _Empty(
              icon: Icons.notifications_none,
              title: 'No notifications yet',
              subtitle: 'Likes and comments on your posts will show up here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // The stream re-reads on its own; this just gives the pull-to-
              // refresh gesture something to wait on.
              await _service.watchNotifications().first;
            },
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) => _NotificationTile(
                notification: notifications[index],
                onOpen: () => _open(notifications[index]),
                onOpenActor: () => _openActor(notifications[index]),
                onDismiss: () => _service.remove(notifications[index].id),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAllRead() async {
    final result = await _service.markAllRead();
    if (!mounted || result.isSuccess) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error ?? 'Could not mark all as read')),
    );
  }

  /// Marks as read, then jumps to the post if one is attached.
  ///
  /// The post is re-fetched rather than trusting the copy the notification
  /// carries, so opening a stale notification never shows a deleted post.
  Future<void> _open(AppNotification notification) async {
    if (!notification.read) {
      await _service.markRead(notification.id);
    }

    final contentId = notification.contentId;
    if (contentId == null || contentId.isEmpty || !mounted) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('content').doc(contentId).get();
      if (!mounted) return;

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That post no longer exists')),
        );
        return;
      }

      final item = ContentItem.fromFirebase(doc.id, doc.data()!);
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ContentDetailScreen(item: item)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open that post: $e')),
      );
    }
  }
  /// Opens the profile of whoever caused the notification.
  ///
  /// The row itself opens the post, so the actor is reached from the icon
  /// leading it - which is also the only place their face would be.
  Future<void> _openActor(AppNotification notification) async {
    final uid = notification.actorUid;
    if (uid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That account could not be identified')),
      );
      return;
    }

    if (!notification.read) {
      await _service.markRead(notification.id);
    }
    if (!mounted) return;

    await openUserProfile(
      context,
      userId: uid,
      displayName: notification.actorName.isEmpty ? 'Profile' : notification.actorName,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onOpen,
    required this.onDismiss,
    this.onOpenActor,
  });

  final AppNotification notification;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  /// Tapping the leading icon opens the actor's profile rather than the post.
  final VoidCallback? onOpenActor;

  IconData get _icon => switch (notification.type) {
        'like' => Icons.favorite,
        'save' => Icons.bookmark,
        'comment' => Icons.mode_comment_outlined,
        _ => Icons.notifications_none,
      };

  Color get _color => switch (notification.type) {
        'like' => Colors.red,
        'save' => AppColors.warning,
        'comment' => AppColors.primary,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Container(
          // An unread notification is tinted so it is distinguishable at a
          // glance without relying on a dot alone.
          color: notification.read ? Colors.transparent : AppColors.primary.withOpacity(0.06),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The icon is a separate tap target from the row: the row opens
              // the post, the icon opens the person who acted on it.
              InkWell(
                onTap: onOpenActor,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, color: _color, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: notification.read
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: notification.read ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    if (notification.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _relativeTime(notification.createdAt!),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              if (!notification.read)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 6),
                  height: 8,
                  width: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact "2h ago" style stamp. Deliberately not a date: a notification
  /// list is read relative to now.
  String _relativeTime(DateTime then) {
    final diff = DateTime.now().difference(then);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
