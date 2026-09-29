import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wallpaper/anchors.dart';
import 'wallpaper/image_utils.dart';
import 'wallpaper/wallpaper.dart';

/// Owns the wallpaper the user has chosen, and persists it per device.
///
/// Deliberately narrower than the equivalent controller in the sibling project,
/// which also owned the base theme. Here the app has a single dark palette
/// ([AppColors]) referenced as constants in ~700 places, so making it a
/// runtime value would mean rewriting every screen to read it through a
/// context. The wallpaper is layered behind the app instead and tints a small
/// number of surface tokens through a [ThemeExtension], which leaves the
/// existing palette - and every reference to it - untouched.
///
/// Persistence is [SharedPreferences], so the choice is per device rather than
/// per account. Signing in on another machine shows the default until the user
/// picks again.
class AppearanceController extends ChangeNotifier {
  AppearanceController._({
    required SharedPreferences storage,
    Wallpaper? custom,
    String? wallpaperId,
  })  : _storage = storage,
        _custom = custom,
        _wallpaperId = wallpaperId;

  static const _wallpaperKey = 'app-wallpaper';
  static const _customKey = 'app-wallpaper-custom';

  final SharedPreferences _storage;

  Wallpaper? _custom;
  String? _wallpaperId;

  /// Reads the stored choice. Never throws: a failure here would prevent the
  /// app from starting, which is a far worse outcome than a missing wallpaper.
  static Future<AppearanceController> load() async {
    final storage = await SharedPreferences.getInstance();

    Wallpaper? custom;
    try {
      final raw = storage.getString(_customKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          custom = Wallpaper.customFromJson(decoded);
        }
      }
    } catch (_) {
      custom = null;
    }

    final stored = storage.getString(_wallpaperKey);
    var wallpaperId = stored == null || stored == 'none' ? null : stored;

    // A custom wallpaper whose image failed to load cannot be painted, so fall
    // back to none rather than rendering an empty layer.
    if (wallpaperId == 'custom' && custom == null) wallpaperId = null;

    return AppearanceController._(
      storage: storage,
      custom: custom,
      wallpaperId: wallpaperId,
    );
  }

  Wallpaper? get custom => _custom;

  /// The selected id, or null for no wallpaper.
  String? get wallpaperId => _wallpaperId;

  /// What to paint, or null when no wallpaper is selected.
  Wallpaper? get wallpaper {
    final id = _wallpaperId;
    if (id == null) return null;
    if (id == 'custom') return _custom;
    return presetById(id);
  }

  /// The presets, with the user's own image appended when there is one.
  List<Wallpaper> get wallpapers =>
      _custom == null ? kWallpaperPresets : [...kWallpaperPresets, _custom!];

  bool get hasWallpaper => wallpaper != null;

  Anchors? get anchors => wallpaper?.anchors;

  void setWallpaper(String? id) {
    if (id == _wallpaperId) return;
    _wallpaperId = id;
    _storage.setString(_wallpaperKey, id ?? 'none');
    notifyListeners();
  }

  /// Stores a picked image and selects it.
  ///
  /// The resize and anchor sampling happen on a background isolate where the
  /// decoder allows it, because decoding and resizing a multi-megabyte photo
  /// on the UI isolate is a visible stall. If the save fails - most often
  /// localStorage being full on web - the wallpaper still applies for this
  /// session and the caller is told it was not persisted, so the user is not
  /// left with a setting that silently vanishes.
  Future<bool> addCustomWallpaper(Uint8List bytes) async {
    final result = await buildCustomWallpaper(bytes);
    final wallpaper = Wallpaper(
      id: 'custom',
      label: 'My image',
      desc: 'Your own picture.',
      anchors: result.anchors,
      dataUrl: result.dataUrl,
    );

    _custom = wallpaper;

    var persisted = true;
    try {
      await _storage.setString(_customKey, jsonEncode(wallpaper.toJson()));
    } catch (_) {
      persisted = false;
    }

    setWallpaper('custom');
    return persisted;
  }

  void removeCustomWallpaper() {
    _custom = null;
    _storage.remove(_customKey);
    if (_wallpaperId == 'custom') {
      setWallpaper(null);
    } else {
      notifyListeners();
    }
  }
}

/// The wallpaper's influence on the app's chrome, read through [Theme.of].
///
/// A [ThemeExtension] rather than a set of globals because it participates in
/// theme resolution: widgets that rebuild on theme change get repainted when
/// the wallpaper changes, with no listener wiring and no rebuild of the whole
/// tree by hand.
@immutable
class WallpaperTheme extends ThemeExtension<WallpaperTheme> {
  const WallpaperTheme({this.anchors});

  /// Null when no wallpaper is selected, which callers treat as "leave the
  /// palette alone".
  final Anchors? anchors;

  /// How opaque the veil over the wallpaper is.
  ///
  /// Rises with the image's brightness. The app's text is light, so a bright
  /// image sits closest to the text colour in luminance and is the harder case
  /// to read against - it needs a heavier veil, not a lighter one. A dark image
  /// can carry more of itself through.
  double get scrimOpacity {
    final value = anchors;
    if (value == null) return 0;
    // Brightness 0 -> 0.44, brightness 1 -> 0.69.
    return (0.44 + 0.25 * value.brightness).clamp(0.32, 0.72);
  }

  /// The gradient laid over the wallpaper so content stays readable.
  ///
  /// Three stops rather than one flat fill: content sits mostly in the middle
  /// of the screen, and a uniform veil either drowns the image at the top or
  /// leaves the centre too bright.
  Gradient? get scrim {
    final value = anchors;
    if (value == null) return null;
    final base = scrimOpacity;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0, 0.45, 1],
      colors: [
        Color.fromRGBO(0, 0, 0, base * 0.92),
        Color.fromRGBO(0, 0, 0, base * 0.74),
        Color.fromRGBO(0, 0, 0, base),
      ],
    );
  }

  @override
  WallpaperTheme copyWith({Anchors? anchors}) =>
      WallpaperTheme(anchors: anchors ?? this.anchors);

  @override
  WallpaperTheme lerp(ThemeExtension<WallpaperTheme>? other, double t) {
    if (other is! WallpaperTheme) return this;
    // Colours are not interpolated: cross-fading two independently sampled
    // colour sets has no meaningful midpoint, and a wallpaper change is
    // instant rather than animated anyway.
    return t < 0.5 ? this : other;
  }
}

/// Convenience accessor: the active wallpaper theme, or null when unset.
extension WallpaperThemeContext on BuildContext {
  WallpaperTheme? get wallpaperTheme =>
      Theme.of(this).extension<WallpaperTheme>();
}

/// Exposes the app's [AppearanceController] to the widget tree.
///
/// Passed down explicitly rather than looked up in a global: a static
/// reference to the controller would outlive a hot restart in debug and, worse,
/// would make tests that construct their own controller silently mutate the
/// one the running app is painting with.
///
/// Falls back to null rather than asserting, so a screen reached outside the
/// provider - a dialog, an isolated route in a test - degrades to "no wallpaper
/// available" instead of throwing.
class AppearanceScope extends InheritedWidget {
  const AppearanceScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final AppearanceController? controller;

  static AppearanceController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppearanceScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(AppearanceScope oldWidget) =>
      oldWidget.controller != controller;
}

extension AppearanceContext on BuildContext {
  /// The app's appearance controller, or null when there is none.
  AppearanceController? get appearance => AppearanceScope.of(this);

  /// Whether a wallpaper is active.
  bool get hasWallpaper => appearance?.hasWallpaper ?? false;
}
