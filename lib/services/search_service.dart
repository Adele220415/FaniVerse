import '../models/content_item.dart';
import '../models/user_listing.dart';
import '../models/user_model.dart';
import '../core/result.dart';
import 'user_directory_service.dart';

/// What a search query is looking for.
///
/// Search used to be users-only, which meant a reader who typed a product or a
/// show name was told "no users matching ...". The scope is explicit rather
/// than inferred from the query, because Firestore cannot search four
/// collections in one go and the reader should be able to say which one they
/// mean.
enum SearchScope {
  all('All'),
  users('Users'),
  content('Content'),
  products('Merchandise'),
  events('Events');

  const SearchScope(this.label);

  final String label;

  /// True for the scope that fans a query out across every collection.
  bool get isAll => this == SearchScope.all;
}

/// The matches for one query, split by what they point at.
///
/// Grouping rather than a single flat list is what lets the "All" view keep a
/// heading per collection, so it is obvious why a result is there.
class SearchResults {
  const SearchResults({
    this.users = const [],
    this.content = const [],
    this.products = const [],
    this.events = const [],
  });

  final List<UserModel> users;
  final List<ContentItem> content;
  final List<ProductListing> products;
  final List<EventListing> events;

  bool get isEmpty =>
      users.isEmpty && content.isEmpty && products.isEmpty && events.isEmpty;

  int get total => users.length + content.length + products.length + events.length;
}

/// Runs one query across the four searchable collections.
///
/// Users are the only scope that costs a network round trip: Firestore cannot
/// do substring matching, so [UserDirectoryService] has to query for it. The
/// other three are filtered client-side over data the caller has already
/// loaded - the Explore grid, the shop and the events tab all hold the whole
/// collection already, so re-reading it per keystroke would be pure waste.
class SearchService {
  SearchService({UserDirectoryService? directory}) : _injected = directory;

  final UserDirectoryService? _injected;

  /// Resolved lazily, for the same reason [CatalogService] does it: reading
  /// `FirebaseAuth.instance` in the constructor would force every caller -
  /// including the pure filtering functions, which never touch the network - to
  /// initialise Firebase first.
  UserDirectoryService get _directory => _injected ?? UserDirectoryService();

  /// How many results one section shows when the reader has not narrowed the
  /// scope. Sections are ordered by relevance, not by collection, so a reader
  /// scanning the page sees their best matches first.
  static const int sectionLimit = 5;

  /// How many results a section shows once it is the only thing on screen.
  static const int scopedLimit = 25;

  /// Users matching [query], as a server-side search.
  Future<Result<List<UserModel>>> searchUsers(String query, {int limit = scopedLimit}) {
    return _directory.searchUsers(query, limit: limit);
  }

  /// Posts matching [query], filtered from [items].
  List<ContentItem> filterContent(String query, List<ContentItem> items, {int limit = scopedLimit}) {
    final needle = _normalise(query);
    if (needle.isEmpty) return const [];

    final matches = <ContentItem>[];
    for (final item in items) {
      if (matches.length >= limit) break;
      final haystack = _normalise('${item.title} ${item.description} ${item.creator} ${item.categories.join(' ')}');
      if (haystack.contains(needle)) matches.add(item);
    }
    return matches;
  }

  /// Merchandise matching [query], filtered from [items].
  List<ProductListing> filterProducts(
    String query,
    List<ProductListing> items, {
    int limit = scopedLimit,
  }) {
    final needle = _normalise(query);
    if (needle.isEmpty) return const [];

    final matches = <ProductListing>[];
    for (final product in items) {
      if (matches.length >= limit) break;
      final haystack =
          _normalise('${product.name} ${product.brand} ${product.category} ${product.description}');
      if (haystack.contains(needle)) matches.add(product);
    }
    return matches;
  }

  /// Events matching [query], filtered from [items].
  List<EventListing> filterEvents(
    String query,
    List<EventListing> items, {
    int limit = scopedLimit,
  }) {
    final needle = _normalise(query);
    if (needle.isEmpty) return const [];

    final matches = <EventListing>[];
    for (final event in items) {
      if (matches.length >= limit) break;
      final haystack = _normalise(
        '${event.title} ${event.description} ${event.location} ${event.organizer} ${event.category}',
      );
      if (haystack.contains(needle)) matches.add(event);
    }
    return matches;
  }

  /// Lower-cased and trimmed, so a trailing space cannot silently match nothing.
  static String _normalise(String value) => value.trim().toLowerCase();
}
