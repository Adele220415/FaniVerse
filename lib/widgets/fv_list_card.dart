import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';

/// The list row that the designs use on nearly every screen.
///
/// The same shape appears across Home, Explore, Notifications, Bookmarks,
/// Offline content, Wishlist, Settings, Purchase history and more: a rounded
/// card containing an icon tile, a bold title, a muted meta line and a coral
/// status tag, with a chevron on the right.
///
/// It is one widget rather than a pattern copied per screen, so the spacing and
/// type cannot drift between tabs.
class FvListCard extends StatelessWidget {
  const FvListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.tag,
    this.leading,
    this.icon = Icons.auto_awesome,
    this.onTap,
    this.trailing,
    this.selected = false,
  });

  final String title;

  /// The muted second line: a timestamp, a count, a status.
  final String? subtitle;

  /// The coral label beneath the meta line.
  final String? tag;

  /// Overrides [icon] with real content, for rows showing artwork.
  final Widget? leading;

  final IconData icon;

  final VoidCallback? onTap;

  /// Overrides the chevron, for rows with an edit/delete pair.
  final Widget? trailing;

  /// Tints the icon tile, marking the row as active or highlighted.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (leading != null)
                  leading!
                else
                  FvIconTileSmall(icon: icon, selected: selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (tag != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          tag!,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (trailing != null)
                  trailing!
                else if (onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The smaller icon tile used inside [FvListCard].
///
/// Kept separate from `FvIconTile` because the designs use two tile sizes: a
/// 48px tile for standalone rows and a ~52px rounded thumbnail for cards.
class FvIconTileSmall extends StatelessWidget {
  const FvIconTileSmall({super.key, required this.icon, this.selected = false, this.size = 52});

  final IconData icon;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryTint : AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppTheme.radiusTile),
      ),
      child: Icon(icon, color: AppColors.primaryLight, size: size * 0.44),
    );
  }
}

/// Groups [FvListCard]s under a heading, as the designs do with "Related
/// content", "Our team" and "Management".
class FvSection extends StatelessWidget {
  const FvSection({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(AppTheme.gutter, 8, AppTheme.gutter, 0),
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
