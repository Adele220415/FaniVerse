import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'anchors.dart';

Uint8List? decodeDataUrl(String dataUrl) {
  final index = dataUrl.indexOf('base64,');
  if (index == -1) return null;
  try {
    return base64Decode(dataUrl.substring(index + 7));
  } catch (_) {
    return null;
  }
}

String encodeDataUrl(Uint8List bytes) =>
    'data:image/jpeg;base64,${base64Encode(bytes)}';

double _luminanceOf(int r, int g, int b) =>
    0.2126 * r + 0.7152 * g + 0.0722 * b;

/// Averages the image's pixels into three brightness bands.
///
/// A 48x48 downsample is enough: this only needs the overall colour character,
/// and sampling the full-resolution image would mean millions of per-pixel
/// reads for a result that would not change.
Anchors sampleAnchors(img.Image image) {
  const size = 48;
  final small = img.copyResize(
    image,
    width: size,
    height: size,
    interpolation: img.Interpolation.average,
  );

  var darkR = 0,
      darkG = 0,
      darkB = 0,
      darkN = 0;
  var midR = 0,
      midG = 0,
      midB = 0,
      midN = 0;
  var brightR = 0,
      brightG = 0,
      brightB = 0,
      brightN = 0;
  var allR = 0,
      allG = 0,
      allB = 0,
      allN = 0;

  for (var y = 0; y < small.height; y++) {
    for (var x = 0; x < small.width; x++) {
      final pixel = small.getPixel(x, y);
      // Transparent pixels would otherwise drag every band toward black.
      if (pixel.a < 125) continue;
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final tone = _luminanceOf(r, g, b);
      if (tone < 85) {
        darkR += r;
        darkG += g;
        darkB += b;
        darkN++;
      } else if (tone < 175) {
        midR += r;
        midG += g;
        midB += b;
        midN++;
      } else {
        brightR += r;
        brightG += g;
        brightB += b;
        brightN++;
      }
      allR += r;
      allG += g;
      allB += b;
      allN++;
    }
  }

  List<int> average(int r, int g, int b, int n) {
    if (n == 0) return const [128, 128, 128];
    return [r ~/ n, g ~/ n, b ~/ n];
  }

  List<int> mix(List<int> a, List<int> b, double t) => [
        (a[0] + (b[0] - a[0]) * t).round(),
        (a[1] + (b[1] - a[1]) * t).round(),
        (a[2] + (b[2] - a[2]) * t).round(),
      ];

  // A flat image has no dark or bright pixels to average, so those bands fall
  // back to a push away from the overall tone - which preserves the intended
  // dark-to-light ordering instead of collapsing all three to one value.
  final overall = average(allR, allG, allB, allN);
  var deep = darkN > 0
      ? average(darkR, darkG, darkB, darkN)
      : mix(overall, const [0, 0, 0], 0.45);
  final middle = midN > 0 ? average(midR, midG, midB, midN) : overall;
  var light = brightN > 0
      ? average(brightR, brightG, brightB, brightN)
      : mix(overall, const [255, 255, 255], 0.45);

  // Enforce deep < light even if the bands came out inverted, so a scrim built
  // from these always darkens toward the bottom rather than the reverse.
  if (_luminanceOf(deep[0], deep[1], deep[2]) >
      _luminanceOf(light[0], light[1], light[2])) {
    final swap = deep;
    deep = light;
    light = swap;
  }

  return Anchors(deep: deep, mid: middle, light: light);
}

class CustomWallpaperResult {
  const CustomWallpaperResult({required this.dataUrl, required this.anchors});

  final String dataUrl;
  final Anchors anchors;
}

/// Prepares a picked image for storage: resized, re-encoded, and sampled.
///
/// The resize is what keeps this viable on web, where the data URL is held in
/// localStorage behind a ~5MB ceiling. A modern phone photo is routinely
/// several megabytes, so storing the original would silently fail on save and
/// leave the user with a wallpaper that disappears on next launch.
Future<CustomWallpaperResult> buildCustomWallpaper(Uint8List bytes) async {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Could not decode that image');
  }

  const max = 1080;
  final longest =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  final resized = longest > max
      ? img.copyResize(
          decoded,
          width: (decoded.width * max / longest).round(),
          height: (decoded.height * max / longest).round(),
          interpolation: img.Interpolation.average,
        )
      : decoded;

  final jpeg = img.encodeJpg(resized, quality: 80);
  return CustomWallpaperResult(
    dataUrl: encodeDataUrl(Uint8List.fromList(jpeg)),
    // Sampled from the original, not the resized copy, so the colours are not
    // quantised by the downscale.
    anchors: sampleAnchors(decoded),
  );
}
