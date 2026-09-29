import 'package:flutter/foundation.dart';

import 'maps_config.dart';

/// Which map capabilities the current build target actually supports.
///
/// `google_maps_flutter` has implementations for Android, iOS and Web only. The
/// project also builds for Windows, Linux and macOS, so "is a map available?"
/// cannot be answered by feature-detection alone - the widget is not merely
/// disabled on those platforms, it is not compiled for them at all. Every call
/// site has to ask here rather than assume.
class MapsCapabilities {
  const MapsCapabilities._();

  /// The platforms with a Google Maps SDK implementation.
  static const Set<String> _supported = {'android', 'ios', 'web'};

  /// The current target's name: `android`, `ios`, `web`, `windows`, `linux` or
  /// `macos`.
  ///
  /// `Platform.operatingSystem` is `dart:io`, which does not compile on Web.
  /// The web value has to be checked first via [kIsWeb] and the `dart:io`
  /// import avoided behind a conditional, otherwise the Web build breaks on an
  /// import it cannot resolve.
  static String get platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  /// True when an embedded interactive map can render on this platform.
  ///
  /// Also requires a key, since the SDK is inert without one.
  static bool get supportsEmbeddedMap =>
      _supported.contains(platform) && MapsConfig.isConfigured;

  /// True when the platform has no map SDK and must open an external map.
  ///
  /// This is the desktop case. `url_launcher` is what makes it work at all.
  static bool get isDesktop => !_supported.contains(platform);

  /// Why the embedded map is unavailable, for the placeholder copy.
  static String get unavailableReason {
    if (!MapsConfig.isConfigured) return MapsConfig.missingReason!;
    return 'Interactive maps are not available on $platform. '
        'Open the location in Google Maps instead.';
  }
}
