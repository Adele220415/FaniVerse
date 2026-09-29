import 'package:faniverse_main/core/appearance_controller.dart';
import 'package:faniverse_main/core/theme/app_theme.dart';
import 'package:faniverse_main/widgets/fv_screen.dart';
import 'package:faniverse_main/screens/wallpaper_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression tests for the wallpaper screen.
///
/// Two real defects these cover:
///  * every preset tile overflowed its grid cell by a few pixels, because
///    `GridView.count` sizes cells from a childAspectRatio while the tile
///    inside is content-sized;
///  * there was no Apply, so a tap applied immediately and there was no way to
///    change your mind.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A controller backed by in-memory preferences.
  Future<AppearanceController> controller() async {
    SharedPreferences.setMockInitialValues({});
    return AppearanceController.load();
  }

  /// Mounts the screen at a phone-sized viewport.
  ///
  /// The overflow was viewport-dependent, so a test at the default 800x600 would
  /// have passed while a real phone failed.
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: WallpaperSettingsScreen(appearance: await controller()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('layout', () {
    testWidgets('lays out every preset without overflowing', (tester) async {
      await pump(tester);

      // The real assertion: no RenderFlex overflow was reported. This is the
      // exact failure the yellow/black stripes were.
      expect(tester.takeException(), isNull);
    });

    testWidgets('holds at a narrow viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: WallpaperSettingsScreen(appearance: await controller()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the presets', (tester) async {
      await pump(tester);

      expect(find.text('Presets'), findsOneWidget);
      expect(find.text('Aurora'), findsOneWidget);
    });
  });

  group('apply', () {
    testWidgets('offers an Apply button', (tester) async {
      await pump(tester);

      expect(find.text('Apply wallpaper'), findsOneWidget);
    });

    testWidgets('Apply is disabled until something is chosen', (tester) async {
      await pump(tester);

      final button = tester.widget<FvPrimaryButton>(find.byType(FvPrimaryButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('choosing a preset enables Apply', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();

      final button = tester.widget<FvPrimaryButton>(find.byType(FvPrimaryButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping a tile does not change the wallpaper', (tester) async {
      // Selection is staged, not applied. Applying on tap would repaint the app
      // under the reader's finger and leave no way to undo the browse.
      final appearance = await controller();

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: WallpaperSettingsScreen(appearance: appearance),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();

      expect(appearance.wallpaperId, isNull);
    });

    testWidgets('Apply commits the staged choice', (tester) async {
      final appearance = await controller();

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: WallpaperSettingsScreen(appearance: appearance),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();

      // The commit row sits below the preset grid, and the ListView builds
      // lazily, so it has to be scrolled into existence before it can be
      // tapped. A raw tap here would silently miss.
      await tester.scrollUntilVisible(find.text('Apply wallpaper'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply wallpaper'));
      await tester.pumpAndSettle();

      expect(appearance.wallpaperId, isNotNull);
      // Confirming back, so the reader knows it took.
      expect(find.text('Wallpaper applied.'), findsOneWidget);
    });

    testWidgets('Cancel discards the staged choice', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();

      // scrollUntilVisible, not ensureVisible: the rows live in a ListView,
      // which builds lazily, so a widget below the fold does not merely sit
      // off-screen - it is not in the tree at all and ensureVisible throws.
      await tester.scrollUntilVisible(find.text('Cancel'), 200);
      await tester.pumpAndSettle();
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      final button = tester.widget<FvPrimaryButton>(find.byType(FvPrimaryButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('choosing the same wallpaper again is not a change', (tester) async {
      final appearance = await controller();
      appearance.setWallpaper('aurora');

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: WallpaperSettingsScreen(appearance: appearance),
        ),
      );
      await tester.pumpAndSettle();

      // Re-picking what is already applied should not light up Apply.
      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();

      final button = tester.widget<FvPrimaryButton>(find.byType(FvPrimaryButton));
      expect(button.onPressed, isNull);
    });
  });
}
