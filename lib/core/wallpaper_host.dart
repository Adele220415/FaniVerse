import 'package:flutter/material.dart';

import 'appearance_controller.dart';
import 'wallpaper_layer.dart';
import 'wallpaper/wallpaper.dart';

/// Paints the wallpaper behind everything the app shows.
///
/// Installed through [MaterialApp.builder], which wraps the whole navigator
/// rather than the `home` widget: one instance then covers every route,
/// including ones pushed after the build, without any of them knowing a
/// wallpaper exists. A background image is content rather than a theme value,
/// which is why it is not done in the ThemeData.
class WallpaperHost extends StatelessWidget {
  const WallpaperHost({
    super.key,
    required this.appearance,
    required this.wallpaper,
    required this.child,
  });

  final AppearanceController appearance;
  final Wallpaper? wallpaper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (wallpaper == null) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        WallpaperLayer(wallpaper: wallpaper!),
        child,
      ],
    );
  }
}
