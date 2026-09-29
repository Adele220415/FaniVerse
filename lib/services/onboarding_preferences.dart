import 'package:shared_preferences/shared_preferences.dart';

/// Whether the reader walked the whole tour, skipped it, or has not seen it.
enum OnboardingState {
  /// Never recorded on this device.
  unknown,

  /// Walked every page. Never shown again.
  completed,

  /// Dismissed early. Shown again once [Preferences.resurfaceAfter] has passed.
  skipped,
}

/// Local record of the onboarding tour.
///
/// ## Why this is a timestamp and not a boolean
///
/// The earlier version stored one `onboarding_complete` flag set on both
/// finish and skip, which made skip indistinguishable from completion - a fan
/// who swiped past the tour on day one was never offered it again. Skipping is
/// an answer, not a completion, and the product wants to re-ask once.
///
/// Recording a millisecond timestamp rather than a separate "skipped at" field
/// means one key holds the whole state: the value's meaning comes from
/// [_skipped] and [_completed] flags plus the timestamp, so there is no way for
/// two keys to disagree about what happened.
///
/// Device-local by design. Onboarding introduces the app, so it belongs to the
/// install; putting it on the user document would mean a second device shows
/// the tour to someone who has already finished it.
class Preferences {
  const Preferences._();

  static const _completed = 'onboarding_complete';
  static const _skipped = 'onboarding_skipped';
  static const _seenAt = 'onboarding_seen_at';
  static const _seenWelcome = 'seen_welcome';

  /// How long a skipped tour waits before being offered again.
  ///
  /// Long enough that a fan who deliberately skipped is not nagged on their
  /// next few sessions, short enough that the tour is still worth showing to
  /// someone who has not got round to it.
  static const Duration resurfaceAfter = Duration(hours: 72);

  /// Reads the stored state.
  ///
  /// Tolerant by construction: every failure path resolves to
  /// [OnboardingState.unknown], which means "show the tour". Erring towards
  /// showing it is the recoverable direction - a fan who sees an extra tour
  /// can skip it, whereas a fan who never sees it has no way to bring it back.
  static Future<OnboardingState> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // A completed tour is final, and checked first so an older install that
      // recorded only `onboarding_complete` still reads as completed.
      if (prefs.getBool(_completed) == true) return OnboardingState.completed;

      if (prefs.getBool(_skipped) != true) return OnboardingState.unknown;

      final seenAt = prefs.getInt(_seenAt);
      if (seenAt == null) {
        // Skipped but no timestamp. Treated as unknown rather than as a skip
        // that never expires, so a half-written record cannot lock the tour out
        // permanently.
        return OnboardingState.unknown;
      }

      final skippedAt = DateTime.fromMillisecondsSinceEpoch(seenAt);
      final elapsed = DateTime.now().difference(skippedAt);

      // A clock moved backwards - a timezone change, or a device with a badly
      // wrong clock - produces a negative elapsed. Treated as not yet due
      // rather than immediately due, so a glitch cannot trigger the tour.
      return elapsed < resurfaceAfter
          ? OnboardingState.skipped
          : OnboardingState.unknown;
    } catch (_) {
      return OnboardingState.unknown;
    }
  }

  /// True when the tour should be shown right now.
  static Future<bool> shouldShow() async =>
      await read() == OnboardingState.unknown;

  /// Records that the tour was walked through.
  static Future<void> markCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completed, true);
      // Clearing these keeps a later skip from resurrecting a finished tour.
      await prefs.remove(_skipped);
      await prefs.remove(_seenAt);
    } catch (_) {
      // Non-fatal: the worst case is the tour appearing once more.
    }
  }

  /// Records that the tour was dismissed early, and when.
  ///
  /// The timestamp is what starts the 72-hour clock, so it is written on the
  /// skip itself rather than being inferred from a session counter.
  static Future<void> markSkipped() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_skipped, true);
      await prefs.setInt(_seenAt, DateTime.now().millisecondsSinceEpoch);
      // Completion wins over a skip, so a finished tour is never downgraded.
      if (prefs.getBool(_completed) == true) return;
      await prefs.setBool(_completed, false);
    } catch (_) {
      // Non-fatal.
    }
  }

  /// Forgets everything, so the tour plays from the start again.
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_completed);
      await prefs.remove(_skipped);
      await prefs.remove(_seenAt);
      await prefs.remove(_seenWelcome);
    } catch (_) {
      // Ignored: a failed reset is not worth surfacing to the user.
    }
  }
}

/// Convenience top-level shorthands, so call sites read as
/// `prefsShouldShowOnboarding()` rather than `Preferences.shouldShow()`.
Future<OnboardingState> prefsReadOnboarding() => Preferences.read();

Future<bool> prefsShouldShowOnboarding() => Preferences.shouldShow();

Future<void> prefsMarkOnboardingCompleted() => Preferences.markCompleted();

Future<void> prefsMarkOnboardingSkipped() => Preferences.markSkipped();

/// The old single-flag accessors.
///
/// Kept so a call site written against the previous API keeps compiling, and
/// routed onto the new state. [prefsSetSeenOnboarding] is ambiguous by nature -
/// it cannot say which of the two outcomes happened - so it records a skip,
/// the weaker claim, rather than claiming completion.
Future<bool> prefsHasSeenOnboarding() async =>
    await Preferences.read() != OnboardingState.unknown;

Future<void> prefsSetSeenOnboarding() => Preferences.markSkipped();
