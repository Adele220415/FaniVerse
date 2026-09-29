import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:faniverse_main/core/appearance_controller.dart';
import 'package:faniverse_main/core/wallpaper/anchors.dart';
import 'package:faniverse_main/core/wallpaper/image_utils.dart';
import 'package:faniverse_main/core/wallpaper/wallpaper.dart';
import 'package:faniverse_main/core/wallpaper/wallpaper_painter.dart';
import 'package:faniverse_main/core/wallpaper_host.dart';
import 'package:faniverse_main/core/wallpaper_layer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Anchors', () {
    test('round-trips through JSON', () {
      const original = Anchors(deep: [1, 2, 3], mid: [4, 5, 6], light: [7, 8, 9]);
      final restored = Anchors.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored, isNotNull);
      expect(restored!.deep, [1, 2, 3]);
      expect(restored.mid, [4, 5, 6]);
      expect(restored.light, [7, 8, 9]);
    });

    test('rejects a malformed payload rather than throwing', () {
      // This runs during app start, so a bad value must degrade to "no
      // wallpaper" instead of preventing launch.
      expect(Anchors.fromJson(null), isNull);
      expect(Anchors.fromJson({}), isNull);
      expect(Anchors.fromJson({'deep': [1, 2], 'mid': [1, 2, 3], 'light': [1, 2, 3]}), isNull);
      expect(Anchors.fromJson({'deep': 'x', 'mid': [1, 2, 3], 'light': [1, 2, 3]}), isNull);
      expect(
        Anchors.fromJson({'deep': [1, 2, 3], 'mid': [1, 2, 3], 'light': [1, 2, 3, 4]}),
        isNull,
      );
    });

    test('clamps out-of-range channels instead of throwing', () {
      const wild = Anchors(deep: [-40, 999, 3], mid: [0, 0, 0], light: [0, 0, 0]);
      // A Color with a channel above 255 would assert in debug builds.
      expect(() => wild.deepColor, returnsNormally);
      expect(() => wild.tint, returnsNormally);
    });

    test('keeps the app violet in the tint', () {
      // The tint is a mix, not a replacement: a wallpaper must not repaint the
      // brand colour out of existence.
      const anchors = Anchors(deep: [0, 0, 0], mid: [255, 0, 0], light: [255, 255, 255]);
      final tint = anchors.tint;
      expect(tint.r, greaterThan(0));
      expect(tint.b, greaterThan(0));
    });
  });

  group('Wallpaper', () {
    test('preset ids are unique and all resolve', () {
      final ids = kWallpaperPresets.map((w) => w.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final id in ids) {
        expect(presetById(id), isNotNull);
      }
    });

    test('an unknown or null id resolves to nothing', () {
      expect(presetById('nope'), isNull);
      expect(presetById(null), isNull);
    });

    test('every preset carries anchors the painter can use', () {
      for (final w in kWallpaperPresets) {
        expect(w.preset, isNotNull);
        expect(w.anchors.deep.length, 3);
        expect(w.anchors.mid.length, 3);
        expect(w.anchors.light.length, 3);
      }
    });

    test('customFromJson needs both a source and anchors', () {
      expect(Wallpaper.customFromJson(null), isNull);
      expect(Wallpaper.customFromJson({'src': ''}), isNull);
      expect(Wallpaper.customFromJson({'src': 'data:image/jpeg;base64,AA=='}), isNull);
    });

    test('customFromJson restores a stored wallpaper', () {
      final restored = Wallpaper.customFromJson({
        'src': 'data:image/jpeg;base64,AA==',
        'anchors': {
          'deep': [1, 2, 3],
          'mid': [4, 5, 6],
          'light': [7, 8, 9],
        },
      });

      expect(restored, isNotNull);
      expect(restored!.isCustom, isTrue);
      expect(restored.anchors.mid, [4, 5, 6]);
    });
  });

  group('AppearanceController', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to no wallpaper', () async {
      final controller = await AppearanceController.load();
      expect(controller.wallpaper, isNull);
      expect(controller.hasWallpaper, isFalse);
      expect(controller.anchors, isNull);
    });

    test('selecting a preset is remembered across a reload', () async {
      final first = await AppearanceController.load();
      first.setWallpaper('lagoon');
      expect(first.wallpaper?.id, 'lagoon');

      // A new instance reads the same storage, which is what happens on relaunch.
      final reloaded = await AppearanceController.load();
      expect(reloaded.wallpaper?.id, 'lagoon');
    });

    test('clearing the wallpaper is remembered', () async {
      final first = await AppearanceController.load();
      first.setWallpaper('dunes');
      first.setWallpaper(null);

      final reloaded = await AppearanceController.load();
      expect(reloaded.wallpaper, isNull);
    });

    test('notifies listeners when the wallpaper changes', () async {
      final controller = await AppearanceController.load();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setWallpaper('aurora');
      expect(notifications, 1);

      // Selecting what is already active is a no-op, so it must not notify.
      controller.setWallpaper('aurora');
      expect(notifications, 1);
    });

    test('offers the custom wallpaper alongside the presets once set', () async {
      final controller = await AppearanceController.load();
      expect(controller.wallpapers.length, kWallpaperPresets.length);

      await controller.addCustomWallpaper(_tinyPngBytes());
      expect(controller.wallpapers.length, kWallpaperPresets.length + 1);
      expect(controller.wallpapers.last.id, 'custom');
    });

    test('removing a custom wallpaper also deselects it', () async {
      final controller = await AppearanceController.load();
      await controller.addCustomWallpaper(_tinyPngBytes());
      expect(controller.wallpaper?.id, 'custom');

      controller.removeCustomWallpaper();
      expect(controller.custom, isNull);
      expect(controller.wallpaper, isNull);
    });

    test('falls back to no wallpaper when the stored custom image is gone', () async {
      // A wallpaper id pointing at an image that failed to load must not render
      // an empty layer or throw.
      SharedPreferences.setMockInitialValues({
        'app-wallpaper': 'custom',
        'app-wallpaper-custom': '{not json',
      });
      final controller = await AppearanceController.load();
      expect(controller.custom, isNull);
      expect(controller.wallpaper, isNull);
    });
  });

  group('WallpaperTheme', () {
    test('has no scrim and no anchors when unset', () {
      const theme = WallpaperTheme();
      expect(theme.anchors, isNull);
      expect(theme.scrim, isNull);
      expect(theme.scrimOpacity, 0);
    });

    test('darkens more over a bright image than a dark one', () {
      // A bright wallpaper needs a heavier scrim or text is unreadable.
      const bright = WallpaperTheme(
        anchors: Anchors(deep: [200, 200, 200], mid: [230, 230, 230], light: [255, 255, 255]),
      );
      const dark = WallpaperTheme(
        anchors: Anchors(deep: [5, 5, 5], mid: [15, 15, 15], light: [40, 40, 40]),
      );

      expect(bright.scrimOpacity, greaterThan(dark.scrimOpacity));
    });

    test('scrim opacity stays within a readable range', () {
      for (final luminance in [0, 0.5, 1]) {
        final v = (luminance * 255).round();
        final theme = WallpaperTheme(
          anchors: Anchors(deep: [v, v, v], mid: [v, v, v], light: [v, v, v]),
        );
        expect(theme.scrimOpacity, greaterThan(0.2));
        expect(theme.scrimOpacity, lessThan(0.8));
      }
    });

    test('lerp switches at the halfway point without interpolating colours', () {
      const a = WallpaperTheme(
        anchors: Anchors(deep: [0, 0, 0], mid: [0, 0, 0], light: [0, 0, 0]),
      );
      const b = WallpaperTheme(
        anchors: Anchors(deep: [255, 255, 255], mid: [255, 255, 255], light: [255, 255, 255]),
      );

      expect(a.lerp(b, 0.2), same(a));
      expect(a.lerp(b, 0.8), same(b));
    });
  });

  group('AppearanceScope', () {
    testWidgets('is readable from a route pushed above home', (
      WidgetTester tester,
    ) async {
      // The bug this covers: scoping to `home` left every pushed route unable
      // to see the controller, so the settings sheet and the wallpaper screen
      // opened from it both saw null.
      final controller = await AppearanceController.load();

      late BuildContext pushedContext;
      await tester.pumpWidget(
        AppearanceScope(
          controller: controller,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (routeContext) {
                          pushedContext = routeContext;
                          return const Scaffold(body: Text('pushed'));
                        },
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(AppearanceScope.of(pushedContext), same(controller));
    });

    testWidgets('returns null when no scope is above the context', (
      WidgetTester tester,
    ) async {
      late BuildContext bare;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              bare = context;
              return const Scaffold(body: Text('x'));
            },
          ),
        ),
      );

      expect(AppearanceScope.of(bare), isNull);
    });
  });

  group('WallpaperHost', () {
    testWidgets('renders the layer only when a wallpaper is set', (
      WidgetTester tester,
    ) async {
      final controller = await AppearanceController.load();

      // No wallpaper: the child is returned untouched, so the host costs
      // nothing in the common case.
      await tester.pumpWidget(
        MaterialApp(
          home: WallpaperHost(
            appearance: controller,
            wallpaper: null,
            child: const Scaffold(body: Text('plain')),
          ),
        ),
      );
      expect(find.byType(WallpaperLayer), findsNothing);
      expect(find.text('plain'), findsOneWidget);

      controller.setWallpaper('aurora');
      await tester.pumpWidget(
        MaterialApp(
          home: WallpaperHost(
            appearance: controller,
            wallpaper: controller.wallpaper,
            child: const Scaffold(body: Text('wallpapered')),
          ),
        ),
      );
      expect(find.byType(WallpaperLayer), findsOneWidget);
      expect(find.text('wallpapered'), findsOneWidget);
    });
  });

  group('data urls', () {

    test('encodes and decodes a round trip', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final url = encodeDataUrl(bytes);
      expect(decodeDataUrl(url), bytes);
    });

    test('a non-base64 url decodes to null rather than throwing', () {
      expect(decodeDataUrl('not-a-data-url'), isNull);
      expect(decodeDataUrl('data:image/png;base64,!!!not base64!!!'), isNull);
    });
  });

  group('WallpaperPainter', () {
    test('paints every preset without throwing', () {
      for (final wallpaper in kWallpaperPresets) {
        for (final preview in [true, false]) {
          final painter = WallpaperPainter(wallpaper.preset!, preview: preview);
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          expect(
            () => painter.paint(canvas, const Size(200, 200)),
            returnsNormally,
            reason: 'failed for ${wallpaper.id} preview=$preview',
          );
          recorder.endRecording().dispose();
        }
      }
    });

    test('an unknown id falls back to a solid fill', () {
      final painter = WallpaperPainter('does-not-exist');
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), const Size(100, 100));
      recorder.endRecording().dispose();
    });

    test('repaints only when the id or preview flag changes', () {
      final a = WallpaperPainter('aurora');
      expect(a.shouldRepaint(WallpaperPainter('aurora')), isFalse);
      expect(a.shouldRepaint(WallpaperPainter('sunset')), isTrue);
      expect(a.shouldRepaint(WallpaperPainter('aurora', preview: true)), isTrue);
    });
  });
}

/// A 1x1 PNG, the smallest thing the decoder will accept.
Uint8List _tinyPngBytes() {
  return Uint8List.fromList(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ));
}
