import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

import '../core/result.dart';
import '../models/user_listing.dart';

/// Resolves an event's free-text venue into coordinates.
///
/// Events store `location` as a human string ("Lagos Convention Centre"), not
/// as a coordinate pair. A map needs a coordinate pair, so the two have to be
/// bridged somewhere. Doing it here rather than at the write site means the
/// 75 already-seeded events resolve too, not only newly created ones.
///
/// ## Why the native geocoder
///
/// `geocoding` calls the platform's own geocoder rather than a web API, so
/// there is no API key, no per-request billing and no network round trip. The
/// trade-off is that it has no implementation on Web or desktop, so
/// [geocodeEvent] can legitimately return null on those targets - the caller
/// must handle that instead of treating null as an error.
class EventGeocodingService {
  const EventGeocodingService();

  /// A resolved coordinate pair.
  ///
  /// Kept separate from `EventListing` because resolution is a runtime concern.
  /// Persisting it onto the document is a deliberate decision
  /// ([cacheOnEvent]), not something that should happen implicitly on read.
  static const EventCoordinates unknown = EventCoordinates._(null, null);

  /// Resolves [event]'s venue to coordinates, or null when it cannot be done.
  ///
  /// Returns null - rather than throwing - when the venue is empty, when the
  /// platform has no geocoder, or when nothing matched. All three are ordinary
  /// outcomes, and the UI's response to each is the same: show the venue text
  /// and offer to open Google Maps.
  Future<EventCoordinates?> geocodeEvent(EventListing event) async {
    final query = event.location.trim();
    if (query.isEmpty) return null;

    // Coords already stored on the document win over re-geocoding. The seed
    // data is fixed and the platform geocoder can disagree between releases,
    // so a value that was resolved once should not drift underneath the user.
    if (event.latitude != null && event.longitude != null) {
      return EventCoordinates._(event.latitude, event.longitude);
    }

    try {
      // v4 of the package returns `Location`, not `Placemark` - the reverse
      // geocode is the one that yields the address components.
      final matches = await locationFromAddress(query);
      if (matches.isEmpty) return null;
      final hit = matches.first;

      // Null Island is the geocoder's "I have no idea" answer, not a real
      // venue. Treating it as a hit would centre the map in the Gulf of Guinea.
      if (hit.latitude == 0 && hit.longitude == 0) return null;
      return EventCoordinates._(hit.latitude, hit.longitude);
    } on Exception catch (e) {
      // The platform geocoder throws on unsupported platforms and on network
      // failure alike; neither is worth surfacing as a login-shaped error.
      debugPrint('Geocoding failed for "$query": $e');
      return null;
    }
  }

  /// Resolves [event]'s venue and writes the result onto its document.
  ///
  /// Writes only when resolution succeeds and the document is not already
  /// carrying coordinates, so this is safe to call on every open of the detail
  /// screen. A write failure is swallowed: the coordinates are a display
  /// convenience, and failing to cache them must not fail the event screen.
  Future<Result<EventCoordinates>> resolveAndCache(
    String eventId,
    EventListing event,
  ) async {
    final coords = await geocodeEvent(event);
    if (coords == null || !coords.isResolved) {
      return Result.error('Could not resolve "${event.location}" to a location.');
    }

    if (event.latitude == null || event.longitude == null) {
      try {
        await _write(eventId, coords);
      } on Exception catch (e) {
        debugPrint('Could not cache coordinates for $eventId: $e');
      }
    }

    return Result.success(coords);
  }

  /// Indirection so the Firestore write stays in one place.
  ///
  /// Injected rather than constructed inline because tests exercise
  /// [geocodeEvent] and [resolveAndCache] without touching the network.
  static Future<void> Function(String eventId, EventCoordinates coords)?
      _writerOverride;

  /// Overrides the coordinate write. Pass null to restore the real one.
  @visibleForTesting
  static set writerOverride(Future<void> Function(String, EventCoordinates)? w) =>
      _writerOverride = w;

  Future<void> _write(String eventId, EventCoordinates coords) async {
    final override = _writerOverride;
    if (override != null) return override(eventId, coords);

    // Imported lazily to keep this service unit-testable without Firestore.
    final db = FirebaseFirestore.instance;
    await db.collection('events').doc(eventId).update({
      'latitude': coords.latitude,
      'longitude': coords.longitude,
    });
  }
}

/// A latitude/longitude pair, either resolved or not.
class EventCoordinates {
  const EventCoordinates._(this.latitude, this.longitude);

  /// Builds a pair from raw values.
  factory EventCoordinates(double latitude, double longitude) =>
      EventCoordinates._(latitude, longitude);

  final double? latitude;
  final double? longitude;

  /// True when both values are present.
  bool get isResolved => latitude != null && longitude != null;

  /// The Google Maps universal search URL for this point.
  ///
  /// Universal rather than a `google.com/maps?q=` query so it behaves the same
  /// in the Maps apps on both mobile platforms, which is the only thing the
  /// desktop fallback has to get right.
  Uri? get mapsUri {
    if (!isResolved) return null;
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${latitude!},${longitude!}',
    );
  }
}
