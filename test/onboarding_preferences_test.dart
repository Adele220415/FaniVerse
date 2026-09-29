import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:faniverse_main/services/onboarding_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock values are re-seeded per test because the store is process-wide, and
  // one test's write would otherwise leak into the next.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('before anything is recorded', () {
    test('the tour is due', () async {
      expect(await Preferences.read(), OnboardingState.unknown);
      expect(await Preferences.shouldShow(), isTrue);
    });
  });

  group('after completing the tour', () {
    setUp(() => Preferences.markCompleted());

    test('the state is completed, not skipped', () async {
      expect(await Preferences.read(), OnboardingState.completed);
    });

    test('it is never shown again', () async {
      // The whole point of completion: no resurface timer applies.
      expect(await Preferences.shouldShow(), isFalse);
    });

    test('it survives a fresh read of the store', () async {
      // Re-reading rather than a cached value, so this covers the actual
      // round trip through SharedPreferences.
      expect(await Preferences.read(), OnboardingState.completed);
      expect(await Preferences.shouldShow(), isFalse);
    });
  });

  group('after skipping the tour', () {
    setUp(() => Preferences.markSkipped());

    test('the state is skipped, not completed', () async {
      // The old single-flag version could not tell these apart, which is what
      // made a skip indistinguishable from finishing.
      expect(await Preferences.read(), OnboardingState.skipped);
    });

    test('it is not shown again straight away', () async {
      expect(await Preferences.shouldShow(), isFalse);
    });
  });

  group('the 72-hour window', () {
    test('is exactly 72 hours', () {
      expect(Preferences.resurfaceAfter, const Duration(hours: 72));
    });

    test('a skip older than the window is due again', () async {
      // Written directly rather than through markSkipped, because the
      // timestamp is the only input that matters here.
      SharedPreferences.setMockInitialValues({
        'onboarding_skipped': true,
        'onboarding_seen_at':
            DateTime.now()
                .subtract(const Duration(hours: 72, minutes: 1))
                .millisecondsSinceEpoch,
      });

      expect(await Preferences.read(), OnboardingState.unknown);
      expect(await Preferences.shouldShow(), isTrue);
    });

    test('a skip just inside the window is still not due', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_skipped': true,
        'onboarding_seen_at':
            DateTime.now()
                .subtract(const Duration(hours: 71, minutes: 59))
                .millisecondsSinceEpoch,
      });

      expect(await Preferences.read(), OnboardingState.skipped);
      expect(await Preferences.shouldShow(), isFalse);
    });

    test('a skip exactly on the boundary is due', () async {
      // The window is inclusive at the far end, so "72 hours later" reshows
      // rather than requiring a minute more.
      SharedPreferences.setMockInitialValues({
        'onboarding_skipped': true,
        'onboarding_seen_at':
            DateTime.now().subtract(const Duration(hours: 72)).millisecondsSinceEpoch,
      });

      expect(await Preferences.shouldShow(), isTrue);
    });

    test('a clock that moved backwards does not trigger the tour', () async {
      // A future timestamp means elapsed is negative. Treated as not yet due,
      // so a timezone or clock glitch cannot nag the reader.
      SharedPreferences.setMockInitialValues({
        'onboarding_skipped': true,
        'onboarding_seen_at':
            DateTime.now().add(const Duration(days: 2)).millisecondsSinceEpoch,
      });

      expect(await Preferences.read(), OnboardingState.skipped);
      expect(await Preferences.shouldShow(), isFalse);
    });
  });

  group('a skip with no timestamp', () {
    test('is treated as due rather than locked out forever', () async {
      // A half-written record must not permanently suppress the tour.
      SharedPreferences.setMockInitialValues({'onboarding_skipped': true});

      expect(await Preferences.read(), OnboardingState.unknown);
      expect(await Preferences.shouldShow(), isTrue);
    });
  });

  group('completion wins over a skip', () {
    test('skipping after completing does not downgrade the record', () async {
      await Preferences.markCompleted();
      await Preferences.markSkipped();

      // A completed tour is final. Without this, a later skip would re-arm the
      // 72-hour timer and offer the tour to someone who finished it.
      expect(await Preferences.read(), OnboardingState.completed);
      expect(await Preferences.shouldShow(), isFalse);
    });
  });

  group('a pre-existing install', () {
    test('an old completed-only flag still reads as completed', () async {
      // Devices that ran the previous version have `onboarding_complete` and
      // nothing else. They must not be shown the tour again.
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});

      expect(await Preferences.read(), OnboardingState.completed);
      expect(await Preferences.shouldShow(), isFalse);
    });
  });

  group('legacy accessors', () {
    test('prefsHasSeenOnboarding agrees with the new state', () async {
      expect(await prefsHasSeenOnboarding(), isFalse);

      await prefsMarkOnboardingCompleted();
      expect(await prefsHasSeenOnboarding(), isTrue);

      await prefsMarkOnboardingSkipped();
      expect(await prefsHasSeenOnboarding(), isTrue);
    });

    test('prefsSetSeenOnboarding records the weaker claim, a skip', () async {
      // It cannot know which outcome happened, so it must not claim
      // completion - that would permanently suppress the tour.
      await prefsSetSeenOnboarding();
      expect(await Preferences.read(), OnboardingState.skipped);
    });
  });

  group('clearAll', () {
    test('resets a completed record', () async {
      await Preferences.markCompleted();
      expect(await prefsShouldShowOnboarding(), isFalse);

      await Preferences.clearAll();
      expect(await prefsShouldShowOnboarding(), isTrue);
    });

    test('resets a skipped record', () async {
      await Preferences.markSkipped();
      expect(await prefsShouldShowOnboarding(), isFalse);

      await Preferences.clearAll();
      expect(await prefsShouldShowOnboarding(), isTrue);
    });
  });
}
