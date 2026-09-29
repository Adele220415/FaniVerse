import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/categories.dart';
import '../services/catalog_filters.dart';

/// Opens the shop filter sheet and returns the applied filters, or null if the
/// user dismissed it.
///
/// [categories] and [priceRange] come from the data rather than a constant, so
/// the sheet cannot offer a filter that returns nothing.
Future<ProductFilters?> showProductFilterSheet(
  BuildContext context, {
  required ProductFilters initial,
  required List<String> categories,
  required ({double min, double max}) priceRange,
}) {
  return showModalBottomSheet<ProductFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _ProductFilterSheet(
      initial: initial,
      categories: categories,
      priceRange: priceRange,
    ),
  );
}

/// Opens the events filter sheet and returns the applied filters, or null if
/// the user dismissed it.
Future<EventFilters?> showEventFilterSheet(
  BuildContext context, {
  required EventFilters initial,
  required List<String> categories,
}) {
  return showModalBottomSheet<EventFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _EventFilterSheet(initial: initial, categories: categories),
  );
}

class _EventFilterSheet extends StatefulWidget {
  const _EventFilterSheet({required this.initial, required this.categories});

  final EventFilters initial;
  final List<String> categories;

  @override
  State<_EventFilterSheet> createState() => _EventFilterSheetState();
}

class _EventFilterSheetState extends State<_EventFilterSheet> {
  late EventFilters _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const _Grabber(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Event filters',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _draft = EventFilters.none),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  if (widget.categories.isNotEmpty) ...[
                    _label('Category'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.categories.map((category) {
                        final selected = _draft.categories.contains(category);
                        return FilterChip(
                          label: Text(AppCategories.label(category)),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              final next = Set<String>.from(_draft.categories);
                              if (value) {
                                next.add(category);
                              } else {
                                next.remove(category);
                              }
                              _draft = _draft.copyWith(categories: next);
                            });
                          },
                          selectedColor: AppColors.primary.withOpacity(0.3),
                          checkmarkColor: AppColors.primary,
                          backgroundColor: AppColors.background,
                          labelStyle: TextStyle(
                            color: selected ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          side: BorderSide(
                            color: selected ? AppColors.primary : AppColors.border,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _label('Show'),
                  SwitchListTile(
                    value: _draft.upcomingOnly,
                    onChanged: (value) => setState(() => _draft = _draft.copyWith(upcomingOnly: value)),
                    title: const Text(
                      'Upcoming events only',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Hide anything that has already happened',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  SwitchListTile(
                    value: _draft.freeOnly,
                    onChanged: (value) => setState(() => _draft = _draft.copyWith(freeOnly: value)),
                    title: const Text(
                      'Free entry only',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  const SizedBox(height: 12),

                  _label('Sort by'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SortOrder.values.map((order) {
                      final selected = _draft.sort == order;
                      return ChoiceChip(
                        label: Text(order.label),
                        selected: selected,
                        onSelected: (_) => setState(() => _draft = _draft.copyWith(sort: order)),
                        selectedColor: AppColors.primary.withOpacity(0.3),
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: selected ? AppColors.primary : AppColors.border,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_draft),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Apply filters',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _label(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ProductFilterSheet extends StatefulWidget {
  const _ProductFilterSheet({
    required this.initial,
    required this.categories,
    required this.priceRange,
  });

  final ProductFilters initial;
  final List<String> categories;
  final ({double min, double max}) priceRange;

  @override
  State<_ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<_ProductFilterSheet> {
  /// Edited locally and only committed on Apply, so Cancel really cancels.
  late ProductFilters _draft;

  late RangeValues _priceRange;

  /// True until the user drags the slider, so "no price filter" stays
  /// distinguishable from "price filter spanning the whole range".
  bool _priceTouched = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _priceRange = RangeValues(
      widget.initial.minPrice ?? widget.priceRange.min,
      widget.initial.maxPrice ?? widget.priceRange.max,
    );
    _priceTouched = widget.initial.minPrice != null || widget.initial.maxPrice != null;
  }

  @override
  Widget build(BuildContext context) {
    final bounds = widget.priceRange;
    final hasRange = bounds.max > bounds.min;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const _Grabber(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _draft = ProductFilters.none;
                      _priceRange = RangeValues(bounds.min, bounds.max);
                      _priceTouched = false;
                    }),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  if (widget.categories.isNotEmpty) ...[
                    _sectionLabel('Category'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.categories.map((category) {
                        final selected = _draft.categories.contains(category);
                        return FilterChip(
                          label: Text(AppCategories.label(category)),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              final next = Set<String>.from(_draft.categories);
                              if (value) {
                                next.add(category);
                              } else {
                                next.remove(category);
                              }
                              _draft = _draft.copyWith(categories: next);
                            });
                          },
                          selectedColor: AppColors.primary.withOpacity(0.3),
                          checkmarkColor: AppColors.primary,
                          backgroundColor: AppColors.background,
                          labelStyle: TextStyle(
                            color: selected ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          side: BorderSide(
                            color: selected ? AppColors.primary : AppColors.border,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  _sectionLabel('Price'),
                  const SizedBox(height: 4),
                  Text(
                    _priceRange.end <= 0
                        ? 'Free only'
                        : '\$${_priceRange.start.toStringAsFixed(0)} - \$${_priceRange.end.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                  if (hasRange)
                    RangeSlider(
                      values: _priceRange,
                      min: bounds.min,
                      max: bounds.max,
                      divisions: bounds.max > bounds.min
                          ? (bounds.max - bounds.min).round().clamp(1, 100)
                          : null,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.border,
                      onChanged: (values) => setState(() {
                        _priceRange = values;
                        _priceTouched = true;
                      }),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Every item in the shop is free.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 8),

                  _sectionLabel('Availability'),
                  SwitchListTile(
                    value: _draft.inStockOnly,
                    onChanged: (value) => setState(() => _draft = _draft.copyWith(inStockOnly: value)),
                    title: const Text(
                      'In stock only',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  const SizedBox(height: 16),

                  _sectionLabel('Sort by'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SortOrder.values.map((order) {
                      final selected = _draft.sort == order;
                      return ChoiceChip(
                        label: Text(order.label),
                        selected: selected,
                        onSelected: (_) => setState(() => _draft = _draft.copyWith(sort: order)),
                        selectedColor: AppColors.primary.withOpacity(0.3),
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: selected ? AppColors.primary : AppColors.border,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Only record a price filter when the user actually moved
                      // it, otherwise every product would carry a redundant
                      // min/max pair.
                      final result = _priceTouched
                          ? _draft.copyWith(
                              minPrice: _priceRange.start,
                              maxPrice: _priceRange.end,
                            )
                          : _draft.copyWith(clearMinPrice: true, clearMaxPrice: true);
                      Navigator.of(context).pop(result);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Apply filters',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.textSecondary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
