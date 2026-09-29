import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/fan_badge.dart';

/// A small circular badge, as shown next to a fan's name on their profile.
///
/// Kept in one place so an earned badge and a locked one cannot drift apart in
/// styling.
class FanBadgeChip extends StatelessWidget {
  const FanBadgeChip({
    super.key,
    required this.badge,
    this.size = 30,
    this.showTooltip = true,
  });

  final FanBadge badge;
  final double size;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.unlocked;

    final circle = Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // A locked badge is a flat outline; an earned one is filled violet.
        color: unlocked ? AppColors.primary : AppColors.elevated,
        border: Border.all(
          color: unlocked ? AppColors.primaryLight : AppColors.border,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        _icon(badge.icon),
        size: size * 0.55,
        color: unlocked ? AppColors.textOnPrimary : AppColors.textTertiary,
      ),
    );

    if (!showTooltip) return circle;

    return Tooltip(
      message: unlocked
          ? '${badge.label} - ${badge.description}'
          : '${badge.label} - ${badge.description} (${badge.progressLabel})',
      child: circle,
    );
  }

  static IconData _icon(String name) {
    switch (BadgeRules.iconFor(name).name) {
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'edit_note':
        return Icons.edit_note;
      case 'menu_book':
        return Icons.menu_book;
      case 'local_library':
        return Icons.local_library;
      case 'favorite':
        return Icons.favorite;
      case 'star':
        return Icons.star;
      case 'bookmark':
        return Icons.bookmark;
      case 'event':
        return Icons.event;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'groups':
        return Icons.groups;
      default:
        return Icons.stars;
    }
  }
}
