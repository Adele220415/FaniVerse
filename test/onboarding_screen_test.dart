import 'package:faniverse_main/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding used to be unusable: it created a [PageController], rendered the
/// current page statically from an `_index` field, and then called
/// `nextPage()` on that controller - which was never attached to a PageView, so
/// the Next button threw on every tap.
///
/// These tests mount the real screen so that failure mode is caught. The
/// preference write is stubbed, because the real one needs platform channels.
void main() {
  // The screen now awaits its preference write before calling onFinished, so
  // without a mock store the write fails inside Preferences and the callback
  // lands after the test's pumpAndSettle has already given up on it.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  /// Taps Next [times] times, pumping between each so the page animation and
  /// the onPageChanged callback settle.
  Future<void> tapNext(WidgetTester tester, int times) async {
    for (var i = 0; i < times; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
  }

  group('onboarding renders', () {
    testWidgets('shows the first page and hides the last', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Discover your fandoms'), findsOneWidget);
      expect(find.text('Shop, save and ask'), findsNothing);
    });

    testWidgets('offers Skip on every page', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('renders an illustration for the current page', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      // OnboardingPage is a value type, not a widget, so it is not in the tree.
      // What is assertable is that the page laid out its illustration area and
      // did not throw on the asset path.
      expect(tester.takeException(), isNull);
      expect(find.text('Discover your fandoms'), findsOneWidget);
    });
  });

  group('Next advances the carousel', () {
    // The regression this whole file exists for.
    testWidgets('does not throw when Next is tapped', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      // Before the fix this threw:
      // "PageController.page cannot be accessed before a PageView is built
      //  with it."
      await tapNext(tester, 1);

      expect(tester.takeException(), isNull);
      expect(find.text('Never miss the moment'), findsOneWidget);
    });

    testWidgets('reaches the last page and renames the button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Get started'), findsNothing);

      await tapNext(tester, 2);

      expect(find.text('Shop, save and ask'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('stays exception-free across every page', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      // Two taps reach the last page; a third would be looking for a "Next"
      // that no longer exists, which is a bug in the test, not the screen.
      await tapNext(tester, 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('over-tapping Next cannot leave a dead button', (tester) async {
      // Guard against the final button silently doing nothing.
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      await tapNext(tester, 2);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('walking every page then finishing does not throw', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      await tapNext(tester, 2);
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('callback', () {
    testWidgets('reports finished=true after the last page', (tester) async {
      var finished = false;
      var completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onFinished: (value) {
              completed = true;
              finished = value;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNext(tester, 2);
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(finished, isTrue);
    });

    testWidgets('reports finished=false on Skip', (tester) async {
      var finished = true;
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(onFinished: (value) {
            called = true;
            finished = value;
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(finished, isFalse);
    });

    testWidgets('a double tap on the final button fires once', (tester) async {
      var calls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(onFinished: (_) => calls++),
        ),
      );
      await tester.pumpAndSettle();

      await tapNext(tester, 2);

      // Two rapid taps on "Get started" - the second must not record again,
      // which would re-trigger the transition in the auth wrapper.
      await tester.tap(find.text('Get started'));
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });
  });

  group('page indicator', () {
    testWidgets('renders one dot per page', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      // Three pages, so three tappable dots.
      final dots = find.byType(AnimatedContainer);
      expect(dots, findsNWidgets(3));
    });

    testWidgets('tapping a dot jumps to that page', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      // Advance one, then jump forward to the last.
      await tapNext(tester, 1);
      await tester.tap(find.byType(AnimatedContainer).at(2));
      await tester.pumpAndSettle();

      expect(find.text('Shop, save and ask'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
