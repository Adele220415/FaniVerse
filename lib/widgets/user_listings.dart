import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/user_listing.dart';
import '../screens/event_detail_screen.dart';
import '../screens/listing_editor.dart';
import '../screens/product_detail_screen.dart';
import '../services/catalog_filters.dart';

/// A user's merchandise, on their profile.
///
/// The list is owned by [CatalogService.watchUserProducts], so a listing added
/// here appears immediately without a refresh, and one added from the shop
/// shows up too.
class UserMerchandiseSection extends StatefulWidget {
  const UserMerchandiseSection({
    super.key,
    required this.userId,
    this.canEdit = false,
    this.service,
    this.embedded = false,
  });

  final String userId;

  /// True on your own profile, which is what reveals the "Add" and delete
  /// controls. Reading someone else's profile must never offer to edit it.
  final bool canEdit;

  final CatalogService? service;

  /// True when hosted inside a TabBarView rather than stacked in a scroll
  /// view. Drops the outer spacing, which would otherwise double up with the
  /// tab's own padding.
  final bool embedded;

  @override
  State<UserMerchandiseSection> createState() => _UserMerchandiseSectionState();
}

class _UserMerchandiseSectionState extends State<UserMerchandiseSection> {
  late final CatalogService _service = widget.service ?? CatalogService();

  Future<void> _add() async {
    final created = await showListingEditor(context, kind: ListingKind.product);
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merchandise added to your profile')),
      );
    }
  }

  Future<void> _confirmDelete(ProductListing product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text('Remove merchandise?'),
        content: Text('"${product.name}" will be taken off your profile.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await _service.deleteProduct(product.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.isSuccess ? 'Removed' : (result.error ?? 'Could not remove'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductListing>>(
      stream: _service.watchUserProducts(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // A missing products rule is a deploy problem, not something the
          // reader can act on, so it is reported rather than thrown - and
          // swallowed silently rather than looking like "no merchandise".
          debugPrint('Merchandise section failed for ${widget.userId}: ${snapshot.error}');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ListingHeader(title: 'Merchandise', count: null, onAdd: null),
              _ListingError(error: '${snapshot.error}'),
            ],
          );
        }

        final products = snapshot.data ?? const <ProductListing>[];

        if (products.isEmpty && !widget.canEdit) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ListingHeader(
              title: 'Merchandise',
              count: products.length,
              onAdd: widget.canEdit ? _add : null,
            ),
            if (products.isEmpty)
              const _ListingEmpty(hint: 'No merchandise listed yet.')
            else
              Padding(
                padding: widget.embedded
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
                    : const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final product in products)
                      _ProductCard(
                        product: product,
                        onDelete: widget.canEdit ? () => _confirmDelete(product) : null,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A user's events, on their profile. Mirrors [UserMerchandiseSection].
class UserEventsSection extends StatefulWidget {
  const UserEventsSection({
    super.key,
    required this.userId,
    this.canEdit = false,
    this.service,
    this.embedded = false,
  });

  final String userId;
  final bool canEdit;
  final CatalogService? service;

  /// See [UserMerchandiseSection.embedded].
  final bool embedded;

  @override
  State<UserEventsSection> createState() => _UserEventsSectionState();
}

class _UserEventsSectionState extends State<UserEventsSection> {
  late final CatalogService _service = widget.service ?? CatalogService();

  Future<void> _add() async {
    final created = await showListingEditor(context, kind: ListingKind.event);
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event added to your profile')),
      );
    }
  }

  Future<void> _confirmDelete(EventListing event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text('Remove event?'),
        content: Text('"${event.title}" will be taken off your profile.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await _service.deleteEvent(event.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.isSuccess ? 'Removed' : (result.error ?? 'Could not remove'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventListing>>(
      stream: _service.watchUserEvents(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Events section failed for ${widget.userId}: ${snapshot.error}');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ListingHeader(title: 'Events', count: null, onAdd: null),
              _ListingError(error: '${snapshot.error}'),
            ],
          );
        }

        final events = snapshot.data ?? const <EventListing>[];

        if (events.isEmpty && !widget.canEdit) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ListingHeader(
              title: 'Events',
              count: events.length,
              onAdd: widget.canEdit ? _add : null,
            ),
            if (events.isEmpty)
              const _ListingEmpty(hint: 'No events yet. Host one and it shows up here.')
            else
              Padding(
                padding: widget.embedded
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
                    : const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (final event in events)
                      _EventRow(
                        event: event,
                        onDelete: widget.canEdit ? () => _confirmDelete(event) : null,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ListingHeader extends StatelessWidget {
  const _ListingHeader({required this.title, required this.count, this.onAdd});

  final String title;

  /// Null while loading or on error, so the count is simply omitted.
  final int? count;

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text('$count', style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          ],
          const Spacer(),
          if (onAdd != null)
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
            ),
        ],
      ),
    );
  }
}

class _ListingEmpty extends StatelessWidget {
  const _ListingEmpty({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(hint, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
    );
  }
}

/// Why a section could not be read.
///
/// This is deliberately explicit. A section that renders as an empty heading
/// is indistinguishable from "this user has no merchandise", which is how a
/// missing Firestore rule reads as a working feature with no data.
class _ListingError extends StatelessWidget {
  const _ListingError({required this.error});

  final String error;

  /// A permission error means the deployed rules do not cover this collection
  /// yet, which is a deploy rather than a user problem.
  bool get _isPermission =>
      error.contains('PERMISSION_DENIED') || error.contains('permission-denied');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPermission ? 'Not available yet' : 'Could not load',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isPermission
                      // Naming the fix is the whole point: without it the only
                      // clue is that the section is mysteriously empty.
                      ? 'This collection is blocked by your Firestore rules. Run:\n'
                          '  firebase deploy --only firestore:rules'
                      : error.split('\n').first,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, this.onDelete});

  final ProductListing product;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                ),
                child: SizedBox(
                  height: 110,
                  width: 110,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: product.imageUrl.isEmpty
                        ? const ColoredBox(
                            color: AppColors.elevated,
                            child: Icon(Icons.shopping_bag, color: AppColors.textTertiary),
                          )
                        : Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: AppColors.elevated,
                              child: Icon(Icons.shopping_bag, color: AppColors.textTertiary),
                            ),
                          ),
                  ),
                ),
              ),
              // An explicit control rather than a long-press: nothing advertises
              // a long-press, so a discoverable one was needed.
              if (onDelete != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          ),
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.accent, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, this.onDelete});

  final EventListing event;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ended = event.eventDate != null && event.eventDate!.isBefore(DateTime.now());

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              height: 44,
              width: 44,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: event.imageUrl.isEmpty
                    ? const ColoredBox(
                        color: AppColors.elevated,
                        child: Icon(Icons.event, color: AppColors.textTertiary),
                      )
                    : Image.network(
                        event.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: AppColors.elevated,
                          child: Icon(Icons.event, color: AppColors.textTertiary),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ended ? AppColors.textSecondary : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (event.eventDate != null) _shortDate(event.eventDate!),
                      if (event.location.isNotEmpty) event.location,
                    ].join(' - '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (ended)
              const Text('ENDED', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textSecondary),
                tooltip: 'Remove event',
              ),
          ],
        ),
      ),
    );
  }

  static String _shortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
