import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// The bottom navigation bar, styled to the designs: a flat, darker bar than
/// the page (#0B0B0D) with no shadow and no border, where the active item is
/// marked by a violet icon and label rather than a pill outline.
class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final void Function(int) onTap;

  /// The design shows five labelled destinations and a raised create button. The
  /// create button is kept because content creation is a real flow here, so the
  /// bar carries the four labelled tabs plus the action.
  static const List<({IconData icon, String label, int index})> _tabs = [
    (icon: Icons.home_outlined, label: 'Home', index: 0),
    (icon: Icons.explore_outlined, label: 'Explore', index: 1),
    (icon: Icons.event_outlined, label: 'Events', index: 3),
    (icon: Icons.shopping_bag_outlined, label: 'Shop', index: 4),
  ];

  /// Index the create button opens. Sits between Explore and Events.
  static const int createIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      // The bar is darker than the page, and there is no top border or shadow:
      // the designs separate the two by value alone.
      color: AppColors.navBackground,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final tab in [_tabs[0], _tabs[1]]) _tabFrom(tab),
              Expanded(child: _createButton()),
              for (final tab in [_tabs[2], _tabs[3]]) _tabFrom(tab),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabFrom(({IconData icon, String label, int index}) tab) {
    return _tab(icon: tab.icon, label: tab.label, index: tab.index);
  }

  Widget _tab({required IconData icon, required String label, required int index}) {
    final isActive = currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                // The filled variant marks the active tab, matching the
                // designs' heavier active state.
                isActive ? _filledFor(icon) : icon,
                color: isActive ? AppColors.primaryLight : AppColors.textTertiary,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.primaryLight : AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Outlined icons have a filled counterpart in Material; mapping the four
  /// tabs explicitly keeps the active state obvious.
  IconData _filledFor(IconData icon) {
    if (icon == Icons.home_outlined) return Icons.home;
    if (icon == Icons.explore_outlined) return Icons.explore;
    if (icon == Icons.event_outlined) return Icons.event;
    if (icon == Icons.shopping_bag_outlined) return Icons.shopping_bag;
    return icon;
  }

  Widget _createButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => onTap(createIndex),
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 40,
            child: Center(
              child: const Icon(Icons.add, color: AppColors.textOnPrimary, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
