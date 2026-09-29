import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// A labelled upload slot: shows the currently uploaded media with
/// pick / replace / remove actions.
///
/// Purely presentational - the parent owns the upload, because only the parent
/// knows whether the result should go to a content document or a user document.
///
/// The preview always comes from the Cloudinary URL rather than from a local
/// file. That is deliberate: a local preview would need `dart:io`, which does
/// not exist on the web, and a cross-platform local preview would not match
/// what other devices render anyway.
class MediaUploadTile extends StatelessWidget {
  const MediaUploadTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onPick,
    this.url,
    this.isUploading = false,
    this.onRemove,
    this.isImage = false,
    this.helperText,
  });

  /// Field name, shown above the slot (for example "Cover image").
  final String label;

  final IconData icon;

  /// Called when the user asks to choose a file. Should be a no-op while
  /// [isUploading] is true.
  final VoidCallback onPick;

  /// The Cloudinary URL, present once the upload finished.
  final String? url;

  final bool isUploading;

  /// When null the remove button is hidden, which suits required slots.
  final VoidCallback? onRemove;

  /// Render an image preview instead of a generic file chip.
  final bool isImage;

  /// Optional note under the preview, for example the stored URL.
  final String? helperText;

  bool get _hasMedia => url != null && url!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (_hasMedia && onRemove != null && !isUploading)
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                label: const Text(
                  'Remove',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: isUploading ? null : onPick,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: isImage ? 180 : 64,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasMedia ? AppColors.primary.withOpacity(0.6) : AppColors.border,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildContent(context),
          ),
        ),
        if (helperText != null && _hasMedia) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isUploading) {
      return const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Text('Uploading...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    if (!_hasMedia) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Tap to choose a file',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      );
    }

    if (isImage) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        placeholder: (context, _) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, _, __) => const Center(
          child: Icon(Icons.broken_image, color: AppColors.textSecondary),
        ),
      );
    }

    return Row(
      children: [
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Uploaded to Cloudinary',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
              Text(
                url!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
