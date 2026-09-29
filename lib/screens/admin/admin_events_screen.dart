import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_listing.dart';
import '../../services/admin_service.dart';
import '../../widgets/feature_list_screen.dart';
import 'admin_forms.dart';

/// Moderation over every event, including the seeded listings.
///
/// Mirrors `AdminProductsScreen`: the seeded events have no `organizerId`, so
/// the owner-scoped delete in `CatalogService` could never reach them.
class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final AdminService _admin = AdminService();

  @override
  Widget build(BuildContext context) {
    return FeatureListScreen<EventListing>(
      title: 'Events',
      itemsStream: _admin.watchAllEvents(),
      emptyHint: 'No events yet.',
      getTitle: (e) => e.title,
      getSubtitle: (e) => [
            if (e.eventDate != null) _date(e.eventDate!),
            if (e.location.isNotEmpty) e.location,
            if (e.category.isNotEmpty) e.category,
            e.organizerId.isEmpty ? 'seeded' : 'host ${e.organizerId.substring(0, 4)}',
            e.status,
          ].join('  ·  '),
      buildLeading: (e) => CircleAvatar(
        backgroundColor: AppColors.surface,
        child: const Icon(Icons.event_outlined, color: AppColors.primaryLight, size: 20),
      ),
      canAdd: false,
      canEdit: (_) => true,
      canDelete: (_) => true,
      onEdit: _editEvent,
      onDelete: _deleteEvent,
    );
  }

  Future<void> _editEvent(EventListing event) async {
    final values = await showAdminFormDialog(
      context,
      title: 'Edit event',
      fields: [
        AdminFormField(key: 'title', label: 'Title', initialValue: event.title),
        AdminFormField(
          key: 'description',
          label: 'Description',
          initialValue: event.description,
          maxLines: 3,
        ),
        AdminFormField(
          key: 'location',
          label: 'Location',
          initialValue: event.location,
        ),
        AdminFormField(
          key: 'status',
          label: 'Status',
          initialValue: event.status,
          // A free-text field rather than a dropdown, so an unusual status
          // already in the data is not silently rewritten to the first option.
          hint: 'upcoming, ongoing, ended, cancelled',
          validator: (value) => value.isEmpty ? 'A status is required' : null,
        ),
      ],
    );
    if (values == null || !mounted) return;

    final result = await _admin.updateEventFields(
      eventId: event.id,
      title: values['title']!,
      description: values['description']!,
      location: values['location']!,
      status: values['status']!.toLowerCase(),
    );
    if (!mounted) return;
    showAdminResult(context, result, success: 'Event updated');
  }

  Future<void> _deleteEvent(EventListing event) async {
    final result = await _admin.deleteEvent(event.id);
    if (!mounted) return;
    showAdminResult(context, result, success: 'Event removed');
  }

  static String _date(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
