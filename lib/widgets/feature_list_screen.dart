import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// A generic admin list screen: a live stream of items, with add / edit / delete
/// driven entirely by callbacks.
///
/// ## Why this exists
///
/// The five admin sections - content, products, events, users, categories -
/// all want the same thing: a live list, a permission gate, an empty state, a
/// loading state, an error state, and an add button that is hidden rather than
/// disabled when the caller cannot use it. Written five times, that is five
/// places to get the "hidden vs disabled" decision wrong, and the failure mode
/// is bad: a disabled Edit button tells the user the action exists and then
/// refuses it, which reads as a broken app rather than a missing permission.
///
/// So the gate decides *visibility*, not enablement, and this widget owns that
/// decision once.
///
/// A disabled control is still shown for a different reason: if the caller
/// passes a null callback the control is not rendered at all.
class FeatureListScreen<T> extends StatelessWidget {
  const FeatureListScreen({
    super.key,
    required this.title,
    required this.itemsStream,
    required this.getTitle,
    this.getSubtitle,
    this.buildLeading,
    this.buildTrailing,
    this.canAdd = false,
    this.canEdit,
    this.canDelete,
    this.onAdd,
    this.onEdit,
    this.onDelete,
    this.emptyHint = 'Nothing here yet.',
    this.onRefresh,
  });

  final String title;

  /// The items. A stream rather than a future so a write made in the admin
  /// screen - or by any other user, anywhere in the app - repaints the list
  /// without a manual refresh.
  final Stream<List<T>> itemsStream;

  final String Function(T item) getTitle;
  final String Function(T item)? getSubtitle;

  /// Optional leading widget, e.g. an avatar or an emoji tile.
  final Widget Function(T item)? buildLeading;

  /// Optional trailing widget, e.g. a status pill.
  final Widget Function(T item)? buildTrailing;

  final bool canAdd;

  /// Per-item gates. A null result hides the row's control.
  final bool Function(T item)? canEdit;
  final bool Function(T item)? canDelete;

  final VoidCallback? onAdd;

  /// Item-scoped, matching [onDelete]. Opening an editor is async (it pushes a
  /// route and may await a save), so a bare `VoidCallback` here would make the
  /// caller drop the future and lose the ability to react to failure.
  final Future<void> Function(T item)? onEdit;
  final Future<void> Function(T item)? onDelete;

  final String emptyHint;

  /// Optional pull-to-refresh. The list is live, so this is only worth wiring
  /// up where a stream error has put the list into its error state and the
  /// user needs a way to retry.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: canAdd && onAdd != null
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: onAdd,
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<List<T>>(
        stream: itemsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(error: '${snapshot.error}', onRetry: onRefresh);
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? const <Never>[];

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: onRefresh ?? () async {},
              color: AppColors.primary,
              backgroundColor: AppColors.elevated,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: AppColors.textTertiary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      emptyHint,
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: onRefresh ?? () async {},
            color: AppColors.primary,
            backgroundColor: AppColors.elevated,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, index) {
                final item = items[index];
                return _Row<T>(
                  item: item,
                  getTitle: getTitle,
                  getSubtitle: getSubtitle,
                  buildLeading: buildLeading,
                  buildTrailing: buildTrailing,
                  canEdit: canEdit?.call(item) ?? false,
                  canDelete: canDelete?.call(item) ?? false,
                  // Both are item-scoped and _Row already holds this row's item,
                  // so they pass straight through.
                  onEdit: onEdit,
                  onDelete: onDelete,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Row<T> extends StatelessWidget {
  const _Row({
    required this.item,
    required this.getTitle,
    required this.canEdit,
    required this.canDelete,
    this.getSubtitle,
    this.buildLeading,
    this.buildTrailing,
    this.onEdit,
    this.onDelete,
  });

  final T item;
  final String Function(T item) getTitle;
  final String Function(T item)? getSubtitle;
  final Widget Function(T item)? buildLeading;
  final Widget Function(T item)? buildTrailing;
  final bool canEdit;
  final bool canDelete;

  /// Item-scoped callbacks, invoked with [item] by this row. Keeping the
  /// parameter here rather than closing over it in the parent is what lets the
  /// confirmation dialog await the delete: a `VoidCallback` would fire and
  /// forget, and the dialog would close before the write it confirmed.
  final Future<void> Function(T item)? onEdit;
  final Future<void> Function(T item)? onDelete;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text('Delete?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '"${getTitle(item)}" will be permanently removed. This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (confirmed == true && onDelete != null) {
      await onDelete!(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leading = buildLeading?.call(item);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: leading,
      title: Text(
        getTitle(item),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),
      subtitle: getSubtitle == null
          ? null
          : Text(
              getSubtitle!(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (buildTrailing != null) buildTrailing!(item),
          // A control is rendered only when the caller both permits it and
          // supplied a handler. Anything else leaves a dead affordance behind.
          if (canEdit && onEdit != null)
            IconButton(
              onPressed: () => onEdit!(item),
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.textSecondary,
              tooltip: 'Edit',
            ),
          if (canDelete && onDelete != null)
            IconButton(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.textSecondary,
              tooltip: 'Delete',
            ),
        ],
      ),
    );
  }
}

/// A failed load, named rather than rendered as an empty list.
///
/// An error and an empty collection look identical otherwise, which is how a
/// missing Firestore rule or an undeployed admin role reads as "a working
/// screen that happens to have no data".
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, this.onRetry});

  final String error;
  final Future<void> Function()? onRetry;

  bool get _isPermission =>
      error.contains('PERMISSION_DENIED') || error.contains('permission-denied');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              _isPermission ? 'Not allowed' : 'Could not load',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isPermission
                  ? 'Your Firestore rules do not cover this yet. Run:\n'
                      '  firebase deploy --only firestore:rules'
                  : error.split('\n').first,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => onRetry!(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryLight,
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
