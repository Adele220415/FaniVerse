import 'anchors.dart';

class Wallpaper {
  const Wallpaper({
    required this.id,
    required this.label,
    required this.desc,
    required this.anchors,
    this.preset,
    this.dataUrl,
  });

  final String id;
  final String label;
  final String desc;
  final Anchors anchors;
  final String? preset;
  final String? dataUrl;

  bool get isCustom => preset == null;

  Map<String, dynamic> toJson() =>
      {'src': dataUrl, 'anchors': anchors.toJson()};

  static Wallpaper? customFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final src = json['src'];
    if (src is! String || src.isEmpty) return null;
    final anchors = Anchors.fromJson(
      json['anchors'] is Map<String, dynamic>
          ? json['anchors'] as Map<String, dynamic>
          : null,
    );
    if (anchors == null) return null;
    return Wallpaper(
      id: 'custom',
      label: 'My image',
      desc: 'Your own picture, with matching colours.',
      anchors: anchors,
      dataUrl: src,
    );
  }
}

const List<Wallpaper> kWallpaperPresets = [
  Wallpaper(
    id: 'aurora',
    label: 'Aurora',
    desc: 'Green ribbons over a starlit sky.',
    preset: 'aurora',
    anchors: Anchors(deep: [5, 8, 20], mid: [14, 34, 56], light: [186, 255, 232]),
  ),
  Wallpaper(
    id: 'sunset',
    label: 'Sunset ridge',
    desc: 'Warm sun sinking behind the hills.',
    preset: 'sunset',
    anchors: Anchors(deep: [34, 14, 44], mid: [176, 70, 88], light: [255, 226, 184]),
  ),
  Wallpaper(
    id: 'lagoon',
    label: 'Lagoon',
    desc: 'Deep water fading into bright teal.',
    preset: 'lagoon',
    anchors: Anchors(deep: [3, 26, 50], mid: [16, 104, 130], light: [196, 246, 240]),
  ),
  Wallpaper(
    id: 'blossom',
    label: 'Blossom',
    desc: 'Soft pastel blooms on a pale sky.',
    preset: 'blossom',
    anchors: Anchors(
      deep: [176, 130, 192],
      mid: [255, 214, 234],
      light: [255, 247, 251],
    ),
  ),
  Wallpaper(
    id: 'dunes',
    label: 'Dunes',
    desc: 'Golden desert light and warm sand.',
    preset: 'dunes',
    anchors: Anchors(
      deep: [146, 88, 52],
      mid: [240, 196, 148],
      light: [255, 240, 214],
    ),
  ),
];

Wallpaper? presetById(String? id) {
  if (id == null) return null;
  for (final item in kWallpaperPresets) {
    if (item.id == id) return item;
  }
  return null;
}
