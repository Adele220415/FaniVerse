import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/categories.dart';

/// A fandom's illustration, replacing the emoji glyphs the app used before.
///
/// Named `CategoryArtView` rather than `CategoryArt` so it does not collide
/// with the descriptor of the same idea in `core/constants/categories.dart` -
/// the descriptor is data, this is the widget that draws it.
///
/// One SVG per category, sharing a single palette so the set reads as a family
/// rather than eleven unrelated pictures. The asset path comes from
/// [AppCategories], so adding a category to the catalog is all it takes.
///
/// If an asset is missing the [placeholderBuilder] renders a monogram tile
/// rather than a gap, which keeps a new category usable before its artwork
/// exists.
class CategoryArtView extends StatelessWidget {
  const CategoryArtView({
    super.key,
    required this.category,
    this.size = 56,
    this.showLabel = false,
    this.selected = false,
  });

  /// Canonical lowercase value; Title Case is tolerated.
  final String category;

  final double size;

  /// Draws the label beneath the art, as on the Home fandom row.
  final bool showLabel;

  /// Tints the fallback and the label, marking a chosen fandom.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final art = _art();
    if (!showLabel) return art;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        art,
        const SizedBox(height: 6),
        SizedBox(
          width: size + 8,
          child: Text(
            AppCategories.label(category),
            style: TextStyle(
              color: selected ? AppColors.primaryLight : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _art() {
    final asset = AppCategories.artAssetFor(category);

    if (asset == null) return _Monogram(category: category, size: size, selected: selected);

    return SizedBox(
      height: size,
      width: size,
      child: ClipOval(
        child: SvgPicture.asset(
          asset,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => _Monogram(category: category, size: size, selected: selected),
        ),
      ),
    );
  }
}

/// Fallback: the category's first letter on the tint.
class _Monogram extends StatelessWidget {
  const _Monogram({required this.category, required this.size, required this.selected});

  final String category;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final value = category.trim();
    final letter = value.isEmpty ? '?' : value[0].toUpperCase();

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : AppColors.primaryTint,
        border: Border.all(
          color: selected ? AppColors.primaryLight : AppColors.border,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: AppColors.primaryLight,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A category chip carrying its illustration, for filter rows.
///
/// Used in place of the plain [FilterChip] so the fandom identity is visible in
/// the filter, not just in the feed.
class CategoryChipArt extends StatelessWidget {
  const CategoryChipArt({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
    this.artSize = 24,
  });

  final String category;
  final bool selected;
  final VoidCallback onTap;
  final double artSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryTint : AppColors.elevated,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CategoryArtView(category: category, size: artSize),
              const SizedBox(width: 8),
              Text(
                AppCategories.label(category),
                style: TextStyle(
                  color: selected ? AppColors.primaryLight : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
