import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';

/// The screen title pattern the designs use on every list screen: a large bold
/// heading, then a muted line of context beneath it.
///
/// Centralised because this pairing appeared on 30+ mockups, and each screen
/// was previously re-deriving the type scale and spacing for it.
class FvScreenHeader extends StatelessWidget {
  const FvScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// Usually an icon button - a filter, a cart, a settings entry.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 20, AppTheme.gutter, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}

/// A search field styled as in the designs: a filled rounded rect with a
/// leading magnifier, no visible border.
class FvSearchField extends StatelessWidget {
  const FvSearchField({
    super.key,
    this.controller,
    this.hint = 'Search Fandom Verse',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.field,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                  onPressed: onClear,
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusTile),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusTile),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusTile),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

/// The segmented pill row that sits under a search field on most list screens.
///
/// The designs repeat the same three-option control (For you / Trending /
/// Latest) across many screens, styled as a filled pill that goes violet-tinted
/// when selected.
class FvSegmentedPills<T> extends StatelessWidget {
  const FvSegmentedPills({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.padding = const EdgeInsets.fromLTRB(AppTheme.gutter, 12, AppTheme.gutter, 12),
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Pill(
                label: labelOf(option),
                selected: option == selected,
                onTap: () => onChanged(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryTint : AppColors.elevated,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primaryLight : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single pill, exposed for screens that need one on its own.
class FvPill extends StatelessWidget {
  const FvPill({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pill(label: label, selected: selected, onTap: onTap);
  }
}

/// A full-width primary action, the shape used for "Ask AI Fan Helper",
/// "Continue to checkout" and every other committing button in the designs.
class FvPrimaryButton extends StatelessWidget {
  const FvPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary),
            )
          : Text(label),
    );
  }
}

/// A quieter secondary action, used for "Add to wishlist", "Open map" and the
/// like/dislike pair on a content card.
class FvSecondaryButton extends StatelessWidget {
  const FvSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.tone,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Overrides the label colour for a selected or destructive state.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AppColors.textPrimary;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color)),
    );
  }
}

/// The small coloured status tag under a row title - "Trending now", "Draft",
/// "Beginner Fan Hub". The designs use coral as the dominant tag colour.
class FvTag extends StatelessWidget {
  const FvTag({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color ?? AppColors.accent,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// The rounded square icon that leads every list row in the designs.
class FvIconTile extends StatelessWidget {
  const FvIconTile({super.key, required this.icon, this.selected = false, this.size = 48});

  final IconData icon;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryTint : AppColors.elevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusTile),
      ),
      child: Icon(
        icon,
        color: selected ? AppColors.primaryLight : AppColors.textSecondary,
        size: size * 0.45,
      ),
    );
  }
}

/// Placeholder for a list with nothing in it. Matches the designs' empty
/// treatment: muted icon, short line, no call to action.
class FvEmptyState extends StatelessWidget {
  const FvEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
