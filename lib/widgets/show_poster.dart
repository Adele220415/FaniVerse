import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/show_model.dart';

/// A show poster from TVmaze, with a graceful placeholder.
///
/// [TvShow.imageMedium] is null for a fair number of shows, so never assume a
/// URL is present. This widget always renders something: the poster when
/// available, otherwise a tinted block with the show's initials.
class ShowPoster extends StatelessWidget {
  final TvShow show;
  final double width;

  /// Poster width. Height follows the 2:3 portrait ratio TVmaze uses.
  final double? height;
  final BorderRadius borderRadius;

  const ShowPoster({
    super.key,
    required this.show,
    this.width = 120,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? width * 1.5;
    final posterUrl = show.posterUrl;

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: effectiveHeight,
        child: posterUrl == null
            ? _Placeholder(show: show)
            : CachedNetworkImage(
                imageUrl: posterUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (context, _) => Container(
                  color: Colors.black12,
                ),
                // A broken or slow image should not break the layout.
                errorWidget: (context, url, error) => _Placeholder(show: show),
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final TvShow show;
  const _Placeholder({required this.show});

  /// First letters of up to two words, e.g. "Breaking Bad" -> "BB".
  String get _initials {
    final words =
        show.name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
    final letters = words
        .map((w) => w[0].toUpperCase())
        .join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv, color: scheme.outline, size: 28),
            const SizedBox(height: 6),
            Text(
              _initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
