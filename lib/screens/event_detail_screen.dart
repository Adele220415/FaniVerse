import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/user_listing.dart';
import '../services/event_geocoding_service.dart';
import '../widgets/event_map_section.dart';

/// An event's own page.
///
/// Events used to open the post viewer, which showed an empty title because an
/// event document has no `title` under the shape the post model expects, and
/// offered no way to register for it.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.event});

  final EventListing event;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _registered = false;

  /// The event as it stands after a geocode resolved coordinates for it.
  ///
  /// Held separately from [widget.event] because the coordinates are written to
  /// Firestore by the service; the parent still holds the pre-geocode snapshot
  /// and will not update this screen on its own. Resolving in a local copy is
  /// what lets the map appear on this open instead of only the next one.
  late EventListing _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _resolveLocation();
  }

  /// Geocodes the venue once, on open.
  ///
  /// No-ops for an event that already carries coordinates, and for an online
  /// event, which has nowhere to point. Failures are silent by design: the
  /// section below falls back to the venue text, and a resolution problem is
  /// not something the user can act on.
  Future<void> _resolveLocation() async {
    final target = widget.event;
    if (target.isOnline || target.hasCoordinates || target.location.isEmpty) return;

    const service = EventGeocodingService();
    final result = await service.resolveAndCache(target.id, target);

    // Guarded because the user may have left the screen while this was in
    // flight, and setState after dispose throws.
    if (!mounted || !result.isSuccess) return;
    final coords = result.data;
    if (coords == null || !coords.isResolved) return;

    setState(() {
      _event = target.copyWithResolvedCoordinates(
        latitude: coords.latitude,
        longitude: coords.longitude,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final ended = event.eventDate != null && event.eventDate!.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Event',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: event.imageUrl.isEmpty
                        ? Container(
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.event, size: 44, color: Colors.white38),
                          )
                        : Image.network(
                            event.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => Container(
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.event, size: 44, color: Colors.white38),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                if (event.category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.category.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                Text(
                  event.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 12),

                _row(Icons.calendar_today, _dateLine(event)),
                const SizedBox(height: 8),
                if (event.location.isNotEmpty) _row(Icons.location_on, event.location),
                const SizedBox(height: 8),
                _row(
                  Icons.people,
                  '${event.attendeesCount} attending'
                      '${event.capacity > 0 ? ' of ${event.capacity}' : ''}',
                ),
                if (event.organizer.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _row(Icons.person_outline, 'Hosted by ${event.organizer}'),
                ],

                const SizedBox(height: 16),

                // The map. Shown for every event that names a location, and
                // left to EventMapSection to decide between an interactive map,
                // an "open externally" button and plain text.
                if (event.location.isNotEmpty || event.hasCoordinates) ...[
                  EventMapSection(event: event),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),

                _priceLine(event),
                if (event.ticketUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _row(Icons.link, event.ticketUrl),
                ],

                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    event.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Registration is a local toggle: there is no ticketing backend, and
          // silently pretending a booking was stored would be worse than
          // being clear about it.
          if (ended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: const Text(
                'This event has already ended.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _registered = !_registered),
                        icon: Icon(
                          _registered ? Icons.check_circle : Icons.add_circle_outline,
                          size: 18,
                          color: _registered ? AppColors.primary : AppColors.textPrimary,
                        ),
                        label: Text(
                          _registered ? 'Registered' : 'Register',
                          style: TextStyle(
                            color: _registered ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _registered ? AppColors.primary : AppColors.border,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (event.ticketPrice > 0)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _registered
                              ? () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ticketing is not connected yet.'),
                                  ),
                                )
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Get ticket - \$${event.ticketPrice.toStringAsFixed(2)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _priceLine(EventListing event) {
    final free = event.ticketPrice <= 0;
    return Row(
      children: [
        const Icon(Icons.confirmation_number, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          free ? 'Free entry' : '\$${event.ticketPrice.toStringAsFixed(2)} per ticket',
          style: TextStyle(
            color: free ? AppColors.primary : AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _dateLine(EventListing event) {
    final date = event.eventDate;
    if (date == null) return 'Date to be announced';

    final day = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (event.startTime.isEmpty) return day;
    return '$day at ${event.startTime}';
  }
}
