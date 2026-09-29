/// Cloudinary configuration, supplied at build time.
///
/// The Cloudinary **API secret is deliberately not supported here.** A Flutter
/// app ships its Dart source inside the binary, so any secret baked into it is
/// readable by anyone who decompiles the app. The only credential a client is
/// allowed to hold is an *unsigned upload preset* name, which Cloudinary
/// treats as public and which grants nothing beyond "upload files".
///
/// Pass the values in at build time:
///
/// ```
/// flutter run \
///   --dart-define=CLOUDINARY_CLOUD_NAME=my_cloud \
///   --dart-define=CLOUDINARY_PRESET=faniverse_unsigned
/// ```
class CloudinaryConfig {
  const CloudinaryConfig._();

  /// Your Cloudinary cloud name (Settings > Account > Cloud Name).
  static const String cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');

  /// The name of an unsigned upload preset created in the Cloudinary dashboard.
  static const String uploadPreset = String.fromEnvironment('CLOUDINARY_PRESET');

  /// Cloudinary's REST upload endpoint base.
  static const String _uploadBase = 'https://api.cloudinary.com/v1_1';

  /// True when both required values were supplied at build time.
  static bool get isConfigured => cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  /// Human-readable reason the app cannot upload, or null when configured.
  static String? get missingReason {
    if (cloudName.isEmpty && uploadPreset.isEmpty) {
      return 'Cloudinary is not configured. Rebuild with '
          '--dart-define=CLOUDINARY_CLOUD_NAME=... --dart-define=CLOUDINARY_PRESET=...';
    }
    if (cloudName.isEmpty) return 'CLOUDINARY_CLOUD_NAME was not supplied at build time.';
    if (uploadPreset.isEmpty) return 'CLOUDINARY_PRESET was not supplied at build time.';
    return null;
  }

  /// The upload endpoint for [resourceType] (one of `image`, `video`, `raw`).
  static String uploadEndpoint(String resourceType) => '$_uploadBase/$cloudName/$resourceType/upload';
}
