import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/content_item.dart';
import '../models/content_media.dart';

/// Static preview for a post inside a grid.
///
/// Deliberately does **not** mount a [VideoPlayer]: a scrolling grid builds and
/// tears down many cells, and each one would open a media session and buffer a
/// clip nobody has asked to play. Instead the first image is shown when there
/// is one, otherwise a type tile with a play badge. Tapping through to the
/// detail screen is where full playback controls live.
class ContentThumbnail extends StatelessWidget {
  const ContentThumbnail({super.key, required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final media = item.media;
    if (media.isEmpty) {
      return _tile(icon: Icons.image_outlined, label: item.type.toUpperCase());
    }

    // Prefer a still frame: a video's own poster frame is ideal, otherwise the
    // first image in the slideshow stands in for it.
    final still = media.where((m) => m.isImage).firstOrNull;
    if (still != null) {
      return _image(still);
    }

    final first = media.first;
    if (first.isVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _tile(icon: Icons.videocam, label: 'VIDEO'),
          if (media.length > 1) _count(media.length),
        ],
      );
    }

    if (first.isAudio) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _tile(icon: Icons.audiotrack, label: 'AUDIO'),
          if (media.length > 1) _count(media.length),
        ],
      );
    }

    return _image(first);
  }

  Widget _image(ContentMedia still) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: still.url,
          fit: BoxFit.cover,
          placeholder: (context, _) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          errorWidget: (context, _, __) => _tile(icon: Icons.broken_image, label: ''),
        ),
        // A video later in the slideshow means this post is playable, so the
        // card gets a play affordance even though the still is an image.
        if (item.media.any((m) => m.isVideo)) _playBadge(),
        if (item.media.length > 1) _count(item.media.length),
      ],
    );
  }

  Widget _tile({required IconData icon, required String label}) {
    return Container(
      color: Colors.grey.shade800,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white38, size: 28),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _playBadge() {
    return const Positioned(
      top: 6,
      right: 6,
      child: _Circle(icon: Icons.play_arrow, size: 22),
    );
  }

  Widget _count(int total) {
    return Positioned(
      bottom: 6,
      right: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.collections, color: Colors.white, size: 10),
            const SizedBox(width: 3),
            Text(
              '$total',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: size * 0.7),
    );
  }
}
