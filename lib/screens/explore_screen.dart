import 'dart:async';
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_colors.dart';
import '../core/result.dart';
import '../widgets/content_thumbnail.dart';
import '../widgets/creator_chip.dart';
import '../widgets/fv_screen.dart';
import '../widgets/user_avatar.dart';
import '../models/content_item.dart';
import '../models/user_listing.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/catalog_filters.dart';
import '../services/feed_service.dart';
import '../services/search_service.dart';
import 'content_detail_screen.dart';
import 'communities_screen.dart';
import 'event_detail_screen.dart';
import 'product_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final SearchService _search = SearchService();
  final CatalogService _catalog = CatalogService();

  final TextEditingController _searchController = TextEditingController();

  List<ContentItem> _allContent = [];
  List<ContentItem> _filteredContent = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';
  UserModel? _userModel;
  /// The live text in the field. Only [_debouncedQuery] drives a search; this
  /// exists so the clear button can appear and disappear as you type.
  String _searchQuery = '';

  /// The merchandise and events a search can match against. Both are loaded
  /// once and kept live, because the shop and events tabs already read the
  /// whole collection - searching them costs no extra reads per keystroke.
  List<ProductListing> _products = [];
  List<EventListing> _events = [];
  String? _catalogError;

  final List<StreamSubscription<dynamic>> _catalogSubscriptions = [];

  /// Which collection the reader is searching. Search used to be users-only.
  SearchScope _scope = SearchScope.all;

  /// The settled query the search uses, so typing does not fire a request on
  /// every keystroke. See [_onSearchChanged].
  String _debouncedQuery = '';
  Timer? _debounceTimer;

  /// Bumped to re-run a failed search; see [_retrySearch].
  int _searchRetries = 0;

  /// How long to wait after the last keystroke before querying. Without this
  /// every character fired two Firestore round trips for the user search, which
  /// is both slow and the most likely way to hit a quota error.
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  /// Browse mode, shown as the segmented pill row above the grid.
  /// How the grid is ordered. Each value produces a genuinely different list.
  FeedMode _feedMode = FeedMode.forYou;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadContent();
    _watchCatalogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    for (final subscription in _catalogSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  /// Keeps merchandise and events in memory for search.
  ///
  /// Failures are recorded rather than thrown: a reader whose search includes
  /// merchandise should still get content and user results if the catalog
  /// collections are unreadable.
  void _watchCatalogs() {
    _catalogSubscriptions.add(
      _catalog.watchProducts().listen(
        (items) {
          if (mounted) setState(() => _products = items);
        },
        onError: (Object e) {
          debugPrint('Explore: merchandise unavailable: $e');
          if (mounted) setState(() => _catalogError = '$e');
        },
      ),
    );

    _catalogSubscriptions.add(
      _catalog.watchEvents().listen(
        (items) {
          if (mounted) setState(() => _events = items);
        },
        onError: (Object e) {
          debugPrint('Explore: events unavailable: $e');
          if (mounted) setState(() => _catalogError = '$e');
        },
      ),
    );
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await _firestore.collection('content').get();

      _allContent = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return null;
        return ContentItem.fromFirebase(doc.id, data);
      }).whereType<ContentItem>().toList();

      // Ordering is left to _applyFilter, which depends on the selected feed
      // option. Sorting here with a random jitter meant tapping a different
      // option reshuffled the grid for no reason.
      _applyFilter();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final result = await _authService.getUserData(user.uid);
      if (result.isSuccess && mounted) {
        setState(() {
          _userModel = result.data;
          // Re-apply filter now that user categories are loaded
          _applyFilter();
        });
      }
    }
  }

  /// Applies the category filter and the selected feed mode.
  ///
  /// The three pills are genuinely different orders, not labels:
  /// **forYou** favours the reader's own fandoms with a light shuffle,
  /// **trending** is pure engagement so it is reproducible, and **latest** is
  /// newest-first. The rules live in [FeedSorter] so Home and Explore cannot
  /// drift apart.
  void _applyFilter() {
    final category = _selectedFilter;
    final source = category == 'All'
        ? _allContent
        : _allContent
            .where((item) => item.matchesAnyCategory({category.toLowerCase().trim()}))
            .toList();

    final userCats = _userModel?.categories
            .map((c) => c.toLowerCase().trim())
            .toSet() ??
        const <String>{};

    _filteredContent = FeedSorter.sort(
      source,
      _feedMode,
      preferredCategories: userCats,
      // A fresh Random per call is intentional for forYou: re-sorting on every
      // switch would make the same tap produce different results.
      random: _feedMode == FeedMode.forYou ? Random() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Search bar
          _buildSearchBar(),

          // While a search is active the results take over the space the
          // pills and grid would otherwise use. The debounced query gates this,
          // not the raw one, so the grid does not disappear the instant a
          // character is typed and then come back.
          if (_searching) ...[
            _buildSearchResults(),
          ] else ...[
            // The sort control. Each option re-orders the grid, so the mode is
            // the source of truth for [_filteredContent].
            FvSegmentedPills<FeedMode>(
              options: FeedMode.values,
              selected: _feedMode,
              labelOf: (mode) => mode.label,
              onChanged: (mode) => setState(() {
                _feedMode = mode;
                _applyFilter();
              }),
            ),

            Expanded(
              child: _buildContentBody(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FvScreenHeader(
      title: 'Explore',
      subtitle: 'Series, resources and rabbit holes.',
      trailing: IconButton(
        icon: const Icon(Icons.groups_outlined),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CommunitiesScreen()),
        ),
        tooltip: 'Communities',
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FvSearchField(
          controller: _searchController,
          hint: 'Search users, content, merchandise, events',
          onChanged: _onSearchChanged,
          onClear: _clearSearch,
        ),
        // Always visible, not just while searching. Hiding it until a query
        // existed meant the search had no way to say what it was searching, and
        // "no users matching X" was the only clue the reader got.
        _buildScopePills(),
      ],
    );
  }

  /// Debounces the keystroke before anything is queried.
  ///
  /// The user search is a network round trip, and the old code fired it per
  /// character - two reads per keystroke, each of which could fail on quota and
  /// surface as "Search failed" with nothing to retry.
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _searchQuery = value;
        _debouncedQuery = '';
      });
      return;
    }

    setState(() => _searchQuery = value);
    _debounceTimer = Timer(_debounceDelay, () {
      if (mounted) setState(() => _debouncedQuery = value.trim());
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _debouncedQuery = '';
    });
  }

  /// "What am I searching for" - users, content, merchandise or events.
  Widget _buildScopePills() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (final scope in SearchScope.values) ...[
              FvPill(
                label: scope.label,
                selected: _scope == scope,
                onTap: () => setState(() => _scope = scope),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  bool get _searching => _debouncedQuery.isNotEmpty;

  /// Re-runs the current search, used by the "Try again" button.
  void _retrySearch() => setState(() => _searchRetries++);

  /// Search results replace the content grid while a query is active, so the
  /// two never compete for the same space.
  Widget _buildSearchResults() {
    if (!_searching) return const SizedBox.shrink();

    // The user search is the only part that hits the network, so it is the only
    // part that needs a loading or error state.
    final needsUsers = _scope == SearchScope.all || _scope == SearchScope.users;

    if (!needsUsers) return _buildScopedResults();

    return Expanded(
      child: FutureBuilder<Result<List<UserModel>>>(
        // Keyed on the query, the scope and the retry count. FutureBuilder keeps
        // the future it was first given, so without the retry count in the key
        // the "Try again" button would rebuild the widget and re-show the same
        // failed result.
        key: ValueKey('$_debouncedQuery|${_scope.name}|$_searchRetries'),
        future: _search.searchUsers(
          _debouncedQuery,
          limit: _scope == SearchScope.all ? SearchService.sectionLimit : SearchService.scopedLimit,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Explore: user search threw: ${snapshot.error}');
            return _SearchMessage(
              icon: Icons.cloud_off,
              title: 'Search failed',
              message: '${snapshot.error}',
              onRetry: _retrySearch,
            );
          }

          final result = snapshot.data;
          if (result != null && !result.isSuccess) {
            debugPrint('Explore: user search failed: ${result.error}');
            return _SearchMessage(
              icon: Icons.cloud_off,
              title: 'Search failed',
              message: result.error ?? 'Could not reach the server',
              onRetry: _retrySearch,
            );
          }

          final users = result?.data ?? const <UserModel>[];
          return _buildResults(users: users);
        },
      ),
    );
  }

  /// Results for a scope that needs no network call.
  Widget _buildScopedResults() {
    return Expanded(
      child: _buildResults(
        users: const [],
        limit: SearchService.scopedLimit,
      ),
    );
  }

  /// Assembles the sections the current scope asks for.
  ///
  /// Sections are omitted when they have no matches, so the "All" view never
  /// shows an empty "Events" heading.
  Widget _buildResults({required List<UserModel> users, int? limit}) {
    final query = _debouncedQuery;
    final showAll = _scope.isAll;
    final sectionLimit = limit ?? SearchService.sectionLimit;

    final content = showAll || _scope == SearchScope.content
        ? _search.filterContent(query, _allContent, limit: sectionLimit)
        : const <ContentItem>[];
    final products = showAll || _scope == SearchScope.products
        ? _search.filterProducts(query, _products, limit: sectionLimit)
        : const <ProductListing>[];
    final events = showAll || _scope == SearchScope.events
        ? _search.filterEvents(query, _events, limit: sectionLimit)
        : const <EventListing>[];

    final total = users.length + content.length + products.length + events.length;
    if (total == 0) {
      return _buildEmptyResults();
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(
            '$total ${total == 1 ? 'result' : 'results'} for "$query"',
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ),
        if (users.isNotEmpty) ...[
          if (showAll) _sectionHeader('Users', users.length),
          ...users.map(_userRow),
        ],
        if (content.isNotEmpty) ...[
          if (showAll) _sectionHeader('Content', content.length),
          _contentStrip(content),
        ],
        if (products.isNotEmpty) ...[
          if (showAll) _sectionHeader('Merchandise', products.length),
          _productStrip(products),
        ],
        if (events.isNotEmpty) ...[
          if (showAll) _sectionHeader('Events', events.length),
          _eventStrip(events),
        ],
      ],
    );
  }

  Widget _buildEmptyResults() {
    // Naming the scope in the empty state is the point of the filter: "no users
    // matching X" was actively misleading when the reader had searched for a
    // product.
    final hint = switch (_scope) {
      SearchScope.users => 'No users match "$_debouncedQuery".',
      SearchScope.content => 'No content matches "$_debouncedQuery".',
      SearchScope.products => 'No merchandise matches "$_debouncedQuery".',
      SearchScope.events => 'No events match "$_debouncedQuery".',
      SearchScope.all => 'Nothing matches "$_debouncedQuery" in users, content, merchandise or events.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              hint,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (_catalogError != null &&
                (_scope == SearchScope.products || _scope == SearchScope.events)) ...[
              const SizedBox(height: 8),
              const Text(
                'Merchandise and events could not be loaded.',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Text('$count', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _userRow(UserModel user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      // The whole row opens the profile, and so does the avatar on its own -
      // people tap the face.
      leading: UserAvatar(
        userId: user.id,
        imageUrl: user.profileImage,
        displayName: user.name,
        username: user.username,
        radius: 22,
        onTap: () => _openProfile(user),
      ),
      title: Text(
        user.username,
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        user.name,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () => _openProfile(user),
    );
  }

  /// Content matches run horizontally, so a reader who wants posts can see
  /// several at once instead of scrolling a vertical list one by one.
  Widget _contentStrip(List<ContentItem> items) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ContentDetailScreen(item: item)),
            ),
            child: SizedBox(
              width: 120,
              child: Card(
                color: AppColors.surface,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: ContentThumbnail(item: item),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _productStrip(List<ProductListing> items) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final product = items[index];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
            ),
            child: SizedBox(
              width: 120,
              child: Card(
                color: AppColors.surface,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: product.imageUrl.isEmpty
                            ? const ColoredBox(
                                color: AppColors.elevated,
                                child: Icon(Icons.shopping_bag, color: AppColors.textTertiary),
                              )
                            : Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const ColoredBox(
                                  color: AppColors.elevated,
                                  child: Icon(Icons.shopping_bag, color: AppColors.textTertiary),
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatPrice(product.price),
                            style: const TextStyle(color: AppColors.accent, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _eventStrip(List<EventListing> items) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final event = items[index];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
            ),
            child: SizedBox(
              width: 240,
              child: Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (event.eventDate != null) _formatEventDate(event.eventDate!),
                          if (event.location.isNotEmpty) event.location,
                        ].join(' - '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatPrice(double value) {
    final symbol = value >= 1000 ? 'K' : '';
    final amount = symbol.isEmpty ? value.toStringAsFixed(2) : (value / 1000).toStringAsFixed(1);
    return '\$$amount$symbol';
  }

  String _formatEventDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _openProfile(UserModel user) {
    openUserProfile(
      context,
      userId: user.id,
      displayName: user.username.trim().isNotEmpty ? user.username : user.name,
    );
  }

  Widget _buildContentBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContent,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredContent.isEmpty) {
      return const Center(
        child: Text(
          'No content found.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    // The bottom navigation bar is an overlay on this tab, so the grid gets
    // bottom padding to scroll its last row clear of it. A trailing SizedBox
    // inside a Column here used to steal 80px from the grid itself, which
    // clipped the bottom row.
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredContent.length,
      itemBuilder: (context, index) => _buildContentCard(_filteredContent[index]),
    );
  }

  Widget _buildContentCard(ContentItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContentDetailScreen(item: item),
          ),
        );
      },
      child: Card(
        color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: ContentThumbnail(item: item),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The author's avatar and handle, per the card layout in the
                CreatorChip(item: item),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 12, color: AppColors.accent),
                    const SizedBox(width: 3),
                    Text(
                      _formatCount(item.likes),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.visibility, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(
                      _formatCount(item.views),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

}

/// A search failure, with the reason and a way to try again.
///
/// The old version replaced the whole result area with the bare words "Search
/// failed" and no way to retry, which is what made a transient network blip
/// look like a broken feature.
class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
