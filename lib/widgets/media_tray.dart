import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/content_media.dart';

/// Editor for a post's ordered media list.
///
/// Order is the slideshow order, so items are drag-reorderable and each card
/// shows its position. Removal is per-item, which is what makes a mixed
/// slideshow (several images plus a video) possible.
class MediaTray extends StatelessWidget {
  const MediaTray({
    super.key,
    required this.media,
    required this.onRemove,
    required this.onReorder,
    this.onPreview,
  });

  final List<ContentMedia> media;
  final void Function(int index) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(ContentMedia item)? onPreview;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.photo_library_outlined, color: AppColors.textSecondary, size: 28),
            SizedBox(height: 8),
            Text(
              'No media yet - add images, video or audio below',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 132,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: media.length,
        onReorder: onReorder,
        proxyDecorator: (child, index, animation) => Material(
          color: Colors.transparent,
          child: Transform.scale(scale: 1.05, child: child),
        ),
        itemBuilder: (context, index) {
          final item = media[index];
          return Padding(
            key: ValueKey('${item.type}:${item.url}'),
            padding: const EdgeInsets.only(right: 10),
            child: _MediaCard(
              item: item,
              position: index + 1,
              onRemove: () => onRemove(index),
              onPreview: onPreview == null ? null : () => onPreview!(item),
            ),
          );
        },
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.item,
    required this.position,
    required this.onRemove,
    this.onPreview,
  });

  final ContentMedia item;
  final int position;
  final VoidCallback onRemove;
  final VoidCallback? onPreview;

  IconData get _icon => switch (item.type) {
        'video' => Icons.videocam,
        'audio' => Icons.audiotrack,
        _ => Icons.image,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onPreview,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _thumbnail(),
              ),
            ),
          ),
          // Position badge, so the author can see the running order.
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$position',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
          // Drag handle, the only way to reorder.
          Positioned(
            top: 0,
            right: 0,
            child: ReorderableDragStartListener(
              index: position - 1,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  // Only the inner corner is rounded; the outer corner sits
                  // flush against the card and stays square.
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
                ),
                child: const Icon(Icons.drag_handle, color: Colors.white, size: 16),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnail() {
    if (item.isImage) {
      return CachedNetworkImage(
        imageUrl: item.url,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(color: Colors.black26),
        errorWidget: (context, _, __) => Container(
          color: Colors.black26,
          child: const Icon(Icons.broken_image, color: Colors.white38),
        ),
      );
    }

    // Video and audio have no cheap inline thumbnail yet, so show a type tile
    // rather than pulling the whole asset into memory.
    return Container(
      color: AppColors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_icon, color: AppColors.primary, size: 30),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              item.type.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen preview of a single item while editing.
void showMediaPreview(BuildContext context, ContentMedia item) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: InteractiveViewer(
              maxScale: 4,
              child: Image.network(
                item.url,
                fit: BoxFit.contain,
                errorBuilder: (context, _, __) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.url,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}
