import 'dart:convert';

import 'package:flutter/material.dart';

import 'appearance_controller.dart';
import 'wallpaper/wallpaper.dart';
import 'wallpaper/wallpaper_painter.dart';

/// Paints the selected wallpaper behind the app.
///
/// Kept in a Stack with a [fit] of expand and no gesture handling, so it never
/// intercepts touches: it is purely decorative and the app's own scroll views
/// and buttons sit above it untouched.
class WallpaperLayer extends StatelessWidget {
  const WallpaperLayer({super.key, required this.wallpaper});

  final Wallpaper wallpaper;

  @override
  Widget build(BuildContext context) {
    final scrim = context.wallpaperTheme?.scrim;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (wallpaper.preset != null)
          CustomPaint(
            painter: WallpaperPainter(wallpaper.preset!, preview: false),
          )
        else if (wallpaper.dataUrl != null)
          _CustomImage(dataUrl: wallpaper.dataUrl!),
        if (scrim != null) DecoratedBox(decoration: BoxDecoration(gradient: scrim)),
      ],
    );
  }
}

class _CustomImage extends StatelessWidget {
  const _CustomImage({required this.dataUrl});

  final String dataUrl;

  @override
  Widget build(BuildContext context) {
    final index = dataUrl.indexOf('base64,');
    if (index == -1) return const SizedBox.shrink();
    try {
      final bytes = base64Decode(dataUrl.substring(index + 7));
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
