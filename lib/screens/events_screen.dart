import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/categories.dart';
import '../models/user_listing.dart';
import '../services/catalog_filters.dart';
import '../widgets/fv_screen.dart';
import '../widgets/product_filter_sheet.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key, this.catalogService});

  /// Injected in tests; falls back to a live service.
  final CatalogService? catalogService;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// Unfiltered source. Filters derive from this, so filtering never re-reads.
  List<EventListing> _allEvents = const [];
  EventFilters _filters = EventFilters.none;
  bool _isLoading = true;
  String? _error;

  late final CatalogService _catalog = widget.catalogService ?? CatalogService();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // A stream, so an event created by anyone appears without a refresh.
    _catalog.watchEvents().listen(
      (events) {
        if (!mounted) return;
        setState(() {
          _allEvents = events;
          _isLoading = false;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      },
    );
  }

  List<EventListing> get _visible => _catalog.filterEvents(_allEvents, _filters);

  Future<void> _openFilters() async {
    final result = await showEventFilterSheet(
      context,
      initial: _filters,
      categories: _catalog.categoriesIn(const [], _allEvents),
    );
    if (result == null || !mounted) return;

    setState(() {
      _filters = result;
      if (result.query.isEmpty && _searchController.text.isNotEmpty) {
        _searchController.clear();
      }
    });
  }

  void _clearAll() {
    _searchController.clear();
    setState(() => _filters = EventFilters.none);
  }

  @override
  Widget build(BuildContext context) {
    final events = _visible;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildCategoryChips(),
          _buildResultBar(events.length),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorPanel(message: _error!, onRetry: _loadEvents)
                    : events.isEmpty
                        ? _EmptyPanel(filtered: _filters.isActive, onClear: _clearAll)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: events.length,
                            itemBuilder: (context, index) => _buildEventCard(events[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FvScreenHeader(
      title: 'Event calendar',
      subtitle: 'Upcoming events and meetups.',
      trailing: IconButton(
        icon: const Icon(Icons.tune),
        onPressed: _openFilters,
        tooltip: 'Filters',
      ),
    );
  }

  Widget _buildSearchBar() {
    return FvSearchField(
      controller: _searchController,
      hint: 'Search events...',
      onChanged: (value) => setState(() => _filters = _filters.copyWith(query: value)),
      onClear: () {
        _searchController.clear();
        setState(() => _filters = _filters.copyWith(query: ''));
      },
    );
  }


  Widget _buildCategoryChips() {
    final categories = _catalog.categoriesIn(const [], _allEvents);
    if (categories.isEmpty) return const SizedBox(height: 8);

    return Container(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _filters.categories.isEmpty,
            onSelected: (_) => setState(() => _filters = _filters.copyWith(categories: const {})),
            selectedColor: AppColors.primary.withOpacity(0.3),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              color: _filters.categories.isEmpty ? AppColors.primary : AppColors.textSecondary,
            ),
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: _filters.categories.isEmpty ? AppColors.primary : AppColors.border,
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                label: Text(AppCategories.label(category)),
                selected: _filters.categories.contains(category),
                onSelected: (selected) {
                  setState(() {
                    final next = Set<String>.from(_filters.categories);
                    if (selected) {
                      next.add(category);
                    } else {
                      next.remove(category);
                    }
                    _filters = _filters.copyWith(categories: next);
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.3),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _filters.categories.contains(category)
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: _filters.categories.contains(category) ? AppColors.primary : AppColors.border,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultBar(int count) {
    if (!_filters.isActive) return const SizedBox(height: 4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
      child: Row(
        children: [
          Text(
            '$count event${count == 1 ? '' : 's'}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _clearAll,
            icon: const Icon(Icons.clear, size: 14),
            label: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventListing event) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: event.imageUrl.isEmpty
                      ? const Icon(Icons.event, size: 40, color: Colors.white38)
                      : Image.network(
                          event.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) =>
                              const Icon(Icons.event, size: 40, color: Colors.white38),
                        ),
                ),
                // Past events are marked, since the list can be told to show
                // them and a reader should not have to check the date.
                if (event.eventDate != null && event.eventDate!.isBefore(DateTime.now()))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ENDED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  )
                else if (event.ticketPrice <= 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'FREE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _metaRow(Icons.calendar_today, _formatDate(event.eventDate), Icons.location_on, event.location),
                  const SizedBox(height: 6),
                  _metaRow(
                    Icons.people,
                    '${event.attendeesCount} attending',
                    Icons.confirmation_number,
                    event.ticketPrice <= 0 ? 'Free' : '\$${event.ticketPrice.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Two facts per row so a narrow phone does not wrap the card to four lines.
  Widget _metaRow(IconData firstIcon, String first, IconData secondIcon, String second) {
    return Row(
      children: [
        Icon(firstIcon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            first,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Icon(secondIcon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            second,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date TBD';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.filtered, required this.onClear});

  final bool filtered;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtered ? Icons.search_off : Icons.event_busy,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              filtered ? 'No events match your filters' : 'No events yet',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              filtered
                  ? 'Try another city, or include past events.'
                  : 'Check back soon.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (filtered) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onClear, child: const Text('Clear filters')),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Could not load events',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              message.split('\n').first,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
