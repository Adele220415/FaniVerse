import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// A time-of-day greeting, shown once on the login screen.
///
/// It lived above the username on the Home header before, which meant the same
/// line of copy repeated on every visit to the feed. A greeting belongs at the
/// point of arrival, not on a screen someone opens fifty times a day.
class Greeting extends StatelessWidget {
  const Greeting({super.key});

  /// "Good evening". Split out so it is testable without pumping a widget.
  static String forHour(int hour) {
    if (hour < 5) return 'Still up';
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  /// A line of context under the greeting.
  static String taglineFor(int hour) {
    if (hour < 5) return 'The best lore is written at 2am.';
    if (hour < 12) return 'Your fandom is already talking.';
    if (hour < 18) return 'Plenty to catch up on.';
    return 'Your fandom is still awake.';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = forHour(now.hour);

    return Column(
      children: [
        Text(
          greeting,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          taglineFor(now.hour),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
