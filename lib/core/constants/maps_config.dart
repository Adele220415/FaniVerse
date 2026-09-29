/// Google Maps configuration, supplied at build time.
///
/// The Maps SDK key is not a secret in the Firebase sense - it is embedded in
/// every APK and is readable by anyone who unpacks one. It is therefore
/// *restricted* rather than kept out: in Google Cloud it must be limited to the
/// Maps SDK for Android / iOS / JavaScript, and on Android additionally
/// restricted by package name and signing certificate SHA-1. A key without
/// those restrictions is an open billing liability, because anyone who lifts it
/// can spend the project's quota.
///
/// Pass it in at build time:
///
/// ```
/// flutter run \
///   --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
/// ```
class MapsConfig {
  const MapsConfig._();

  /// The Google Maps SDK for Platforms key.
  static const String apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// True when a key was supplied at build time.
  static bool get isConfigured => apiKey.isNotEmpty;

  /// Human-readable reason the embedded map cannot render, or null when
  /// configured.
  static String? get missingReason {
    if (apiKey.isEmpty) {
      return 'GOOGLE_MAPS_API_KEY was not supplied at build time. Rebuild with '
          '--dart-define=GOOGLE_MAPS_API_KEY=...';
    }
    return null;
  }
}
