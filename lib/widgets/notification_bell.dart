import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/notification_service.dart';
import '../screens/notifications_screen.dart';

/// A bell with an unread badge, wired to the live notification stream.
///
/// The badge count is derived from the same stream that fills the list, so the
/// number on the bell can never disagree with what is actually unread.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.service});

  final NotificationService? service;

  @override
  Widget build(BuildContext context) {
    final notifications = service ?? NotificationService();

    return StreamBuilder<int>(
      stream: notifications.watchUnreadCount(),
      builder: (context, snapshot) {
        // Show nothing until the first value arrives rather than flashing a
        // zero, which would read as "no notifications" when it is really
        // "not loaded yet".
        final unread = snapshot.data;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              color: AppColors.textPrimary,
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(service: notifications),
                ),
              ),
            ),
            if (unread != null && unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                  child: Text(
                    // 99+ rather than the raw number, so a runaway counter
                    // cannot stretch the badge across the app bar.
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
