import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/maps_capabilities.dart';
import '../core/constants/maps_config.dart';
import '../models/user_listing.dart';

/// The map shown on an event's detail screen.
///
/// Three outcomes, and which one renders is decided by the *build target*, not
/// by the widget tree:
///
///  * a live, interactive [GoogleMap] where the SDK exists and a key is set;
///  * an "Open in Google Maps" button on desktop, where `google_maps_flutter`
///    has no implementation at all;
///  * the venue text alone for an online event, which has nowhere to point.
///
/// Degrading to text rather than to an error is deliberate: "Online / Discord"
/// is real seed data, and showing a failed map for it would imply the app had
/// tried and failed.
class EventMapSection extends StatelessWidget {
  const EventMapSection({super.key, required this.event});

  final EventListing event;

  @override
  Widget build(BuildContext context) {
    if (event.isOnline) return _online(context);

    // An online event is the only kind with genuinely nowhere to point, so it
    // is handled before the capability checks.
    if (MapsCapabilities.supportsEmbeddedMap && event.hasCoordinates) {
      return _embedded(context, event.latitude!, event.longitude!);
    }

    return _openInMaps(context);
  }

  Widget _embedded(BuildContext context, double lat, double lng) {
    final position = LatLng(lat, lng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: position, zoom: 15),
              markers: {
                Marker(
                  markerId: MarkerId(event.id),
                  position: position,
                  infoWindow: InfoWindow(
                    title: event.title,
                    snippet: event.location,
                  ),
                ),
              },
              // The app is dark, but the map style is left at default rather
              // than forced dark: Google's dark style hides the road labels
              // that make a venue findable, and this is a navigation aid.
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              scrollGesturesEnabled: true,
              onMapCreated: (_) {
                // Nothing to do here. Camera control is deliberately left to
                // the user; auto-moving the camera on rebuild would make the
                // map jump while they are reading the event.
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        _openButton(context, dense: true),
      ],
    );
  }

  Widget _openInMaps(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        const SizedBox(height: 10),
        // The venue text is always present. On a target without an SDK it is
        // the only representation of the location there is, so it must not be
        // hidden behind a button.
        if (event.location.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.location,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        _openButton(context),
        if (!MapsCapabilities.isDesktop && !MapsConfig.isConfigured)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              MapsCapabilities.unavailableReason,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _online(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.language, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                event.location.isEmpty ? 'Online event' : event.location,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _openButton(BuildContext context, {bool dense = false}) {
    return OutlinedButton.icon(
      onPressed: () => _launch(context),
      icon: const Icon(Icons.map_outlined, size: 18),
      label: const Text('Open in Google Maps'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
        padding: EdgeInsets.symmetric(vertical: dense ? 8 : 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        const Text(
          'Location',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Opens the venue in Google Maps.
  ///
  /// Prefers the resolved coordinate, because a place name alone can land on a
  /// different city when the venue name is ambiguous - "Victoria Island" is
  /// both a Lagos neighbourhood and other places entirely. Falls back to the
  /// text query when there are no coordinates, which still beats showing
  /// nothing.
  Future<void> _launch(BuildContext context) async {
    final query = event.hasCoordinates
        ? '${event.latitude},${event.longitude}'
        : event.location.trim();
    if (query.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
      );
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    } on Exception catch (e) {
      debugPrint('Could not launch maps: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }
}
