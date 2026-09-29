import 'package:flutter/material.dart';

/// Three colours sampled out of a wallpaper image.
///
/// A wallpaper does more than supply a picture: these are what the scrim and
/// the accent tint are derived from, so the chrome around the image shifts to
/// match it rather than sitting on top of it in a fixed colour.
///
/// The three are, in order, the darkest, the mid-tone and the brightest
/// average of their luminance bands. Sampling by band rather than taking three
/// fixed points means a mostly-dark photo and a mostly-bright one both produce
/// a usable spread instead of two nearly identical colours.
class Anchors {
  const Anchors({required this.deep, required this.mid, required this.light});

  /// Each is a 3-element RGB list, stored as a list rather than a Color so the
  /// values survive a JSON round trip through SharedPreferences unchanged.
  final List<int> deep;
  final List<int> mid;
  final List<int> light;

  Color get deepColor => _colorOf(deep);
  Color get midColor => _colorOf(mid);
  Color get lightColor => _colorOf(light);

  static Color _colorOf(List<int> rgb) {
    if (rgb.length < 3) return const Color(0xFF808080);
    return Color.fromARGB(255, rgb[0].clamp(0, 255), rgb[1].clamp(0, 255), rgb[2].clamp(0, 255));
  }

  /// Relative luminance, 0 (black) to 1 (white).
  double get brightness =>
      (0.2126 * deepColor.r + 0.7152 * deepColor.g + 0.0722 * deepColor.b) / 255;

  Map<String, dynamic> toJson() => {'deep': deep, 'mid': mid, 'light': light};

  /// Tolerant parse.
  ///
  /// Returns null on anything malformed rather than throwing: this runs during
  /// app start, and a bad value in local storage should degrade to "no
  /// wallpaper", not crash the launch.
  static Anchors? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    List<int>? read(String key) {
      final value = json[key];
      if (value is! List || value.length != 3) return null;
      final out = <int>[];
      for (final item in value) {
        if (item is! num) return null;
        out.add(item.round());
      }
      return out;
    }

    final d = read('deep');
    final m = read('mid');
    final l = read('light');
    if (d == null || m == null || l == null) return null;
    return Anchors(deep: d, mid: m, light: l);
  }

  /// The accent hue to tint chrome with, given the app's violet.
  ///
  /// The violet is only mixed in, never replaced. A wallpaper chooses the tint
  /// and stays recognisably violet, which is the point of matching the app's
  /// existing palette rather than deriving an arbitrary colour from the image.
  Color get tint => Color.lerp(const Color(0xFF7C5CFF), midColor, 0.35)!;
}
