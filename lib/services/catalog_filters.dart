import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/result.dart';
import '../models/user_listing.dart';

/// How results are ordered in the shop and events tabs.
enum SortOrder {
  newest('Newest'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low'),
  rating('Top rated'),
  nameAZ('Name: A-Z');

  const SortOrder(this.label);
  final String label;
}

/// Every filter the shop applies, as one value so the results can be derived
/// from it and the UI can reset it in a single call.
class ProductFilters {
  const ProductFilters({
    this.query = '',
    this.categories = const {},
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
    this.sort = SortOrder.newest,
  });

  final String query;

  /// Empty means "no category filter" rather than "match nothing", which is
  /// the usual trap with a Set-based filter.
  final Set<String> categories;

  final double? minPrice;
  final double? maxPrice;
  final bool inStockOnly;
  final SortOrder sort;

  bool get isActive =>
      query.isNotEmpty ||
      categories.isNotEmpty ||
      minPrice != null ||
      maxPrice != null ||
      inStockOnly ||
      sort != SortOrder.newest;

  /// How many filter controls are narrowing the list, for the badge count.
  int get activeCount =>
      (query.isNotEmpty ? 1 : 0) +
      (categories.isNotEmpty ? 1 : 0) +
      ((minPrice != null || maxPrice != null) ? 1 : 0) +
      (inStockOnly ? 1 : 0) +
      (sort != SortOrder.newest ? 1 : 0);

  ProductFilters copyWith({
    String? query,
    Set<String>? categories,
    double? minPrice,
    double? maxPrice,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool? inStockOnly,
    SortOrder? sort,
  }) =>
      ProductFilters(
        query: query ?? this.query,
        categories: categories ?? this.categories,
        minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
        maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
        inStockOnly: inStockOnly ?? this.inStockOnly,
        sort: sort ?? this.sort,
      );

  static const ProductFilters none = ProductFilters();
}

/// Every filter the events tab applies.
class EventFilters {
  const EventFilters({
    this.query = '',
    this.categories = const {},
    this.upcomingOnly = true,
    this.freeOnly = false,
    this.sort = SortOrder.newest,
  });

  final String query;
  final Set<String> categories;

  /// Hides events that have already happened, which is the default because a
  /// past convention is rarely what a reader opening the tab wants.
  final bool upcomingOnly;

  final bool freeOnly;
  final SortOrder sort;

  bool get isActive =>
      query.isNotEmpty ||
      categories.isNotEmpty ||
      !upcomingOnly ||
      freeOnly ||
      sort != SortOrder.newest;

  int get activeCount =>
      (query.isNotEmpty ? 1 : 0) +
      (categories.isNotEmpty ? 1 : 0) +
      (!upcomingOnly ? 1 : 0) +
      (freeOnly ? 1 : 0) +
      (sort != SortOrder.newest ? 1 : 0);

  EventFilters copyWith({
    String? query,
    Set<String>? categories,
    bool? upcomingOnly,
    bool? freeOnly,
    SortOrder? sort,
  }) =>
      EventFilters(
        query: query ?? this.query,
        categories: categories ?? this.categories,
        upcomingOnly: upcomingOnly ?? this.upcomingOnly,
        freeOnly: freeOnly ?? this.freeOnly,
        sort: sort ?? this.sort,
      );

  static const EventFilters none = EventFilters();
}

/// Reads the shop and events collections, and derives the filtered, sorted
/// result.
///
/// Filtering happens **client-side** rather than as Firestore queries. The
/// collections are small and fully loaded anyway - the tabs already fetch the
/// whole collection - and doing it here keeps the filter instant instead of a
/// round trip per keystroke. Each additional filter dimension would need a
/// composite index if it were pushed server-side, and Firestore supports only
/// one `arrayContains` per query, so multi-category filtering could not be
/// expressed anyway.
class CatalogService {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  /// Both are resolved lazily.
  ///
  /// Reading `FirebaseFirestore.instance` in the constructor would force every
  /// caller - including the pure filtering functions, which never touch the
  /// network - to initialise Firebase first. That made the filtering logic
  /// untestable in isolation.
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _authn => _auth ?? FirebaseAuth.instance;

  CatalogService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore,
        _auth = auth;

  Stream<List<ProductListing>> watchProducts() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => ProductListing.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<EventListing>> watchEvents() {
    return _db.collection('events').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => EventListing.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  /// Live merchandise and events for one user, for their profile.
  Stream<List<ProductListing>> watchUserProducts(String userId) {
    return _db
        .collection('products')
        .where('sellerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data().isNotEmpty)
            .map((doc) => ProductListing.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Stream<List<EventListing>> watchUserEvents(String userId) {
    return _db
        .collection('events')
        .where('organizerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data().isNotEmpty)
            .map((doc) => EventListing.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Publishes a product. Refuses if the user is signed out.
  Future<Result<String>> createProduct(ProductListing product) async {
    final user = _authn.currentUser;
    if (user == null) {
      return Result.error('You must be logged in to add merchandise');
    }

    try {
      final docRef = await _db.collection('products').add(
        product.copyWith(sellerId: user.uid).toJson(),
      );
      return Result.success(docRef.id);
    } catch (e) {
      return Result.error('Could not save the product: $e');
    }
  }

  Future<Result<void>> deleteProduct(String productId) async {
    final user = _authn.currentUser;
    if (user == null) return Result.error('You must be logged in');

    try {
      final doc = await _db.collection('products').doc(productId).get();
      // The rules also scope deletion to the seller, but checking here turns a
      // permission error into a clear message instead of an exception.
      if (doc.data()?['sellerId']?.toString() != user.uid) {
        return Result.error('You can only delete your own merchandise');
      }
      await doc.reference.delete();
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not delete the product: $e');
    }
  }

  Future<Result<String>> createEvent(EventListing event) async {
    final user = _authn.currentUser;
    if (user == null) {
      return Result.error('You must be logged in to add events');
    }

    try {
      final docRef = await _db.collection('events').add(
        event.copyWith(organizerId: user.uid).toJson(),
      );
      return Result.success(docRef.id);
    } catch (e) {
      return Result.error('Could not save the event: $e');
    }
  }

  Future<Result<void>> deleteEvent(String eventId) async {
    final user = _authn.currentUser;
    if (user == null) return Result.error('You must be logged in');

    try {
      final doc = await _db.collection('events').doc(eventId).get();
      if (doc.data()?['organizerId']?.toString() != user.uid) {
        return Result.error('You can only delete your own events');
      }
      await doc.reference.delete();
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not delete the event: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Filtering
  // ---------------------------------------------------------------------------

  List<ProductListing> filterProducts(
    List<ProductListing> products,
    ProductFilters filters,
  ) {
    final needle = filters.query.trim().toLowerCase();
    final out = products.where((p) {
      if (filters.categories.isNotEmpty &&
          !filters.categories.contains(p.category.toLowerCase())) {
        return false;
      }
      if (filters.inStockOnly && (!p.isAvailable || p.stockQuantity <= 0)) {
        return false;
      }
      if (filters.minPrice != null && p.price < filters.minPrice!) {
        return false;
      }
      if (filters.maxPrice != null && p.price > filters.maxPrice!) {
        return false;
      }
      if (needle.isNotEmpty) {
        final haystack = '${p.name} ${p.brand} ${p.description} ${p.category}'.toLowerCase();
        if (!haystack.contains(needle)) return false;
      }
      return true;
    }).toList();

    out.sort(_productComparator(filters.sort));
    return out;
  }

  Comparator<ProductListing> _productComparator(SortOrder order) {
    switch (order) {
      case SortOrder.priceLow:
        return (a, b) => a.price.compareTo(b.price);
      case SortOrder.priceHigh:
        return (a, b) => b.price.compareTo(a.price);
      case SortOrder.rating:
        // Tie-break on name so equal ratings do not shuffle between rebuilds.
        return (a, b) {
          final byRating = b.rating.compareTo(a.rating);
          return byRating != 0 ? byRating : a.name.compareTo(b.name);
        };
      case SortOrder.nameAZ:
        return (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case SortOrder.newest:
        return (a, b) {
          final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final byDate = bt.compareTo(at);
          return byDate != 0 ? byDate : a.name.compareTo(b.name);
        };
    }
  }

  List<EventListing> filterEvents(List<EventListing> events, EventFilters filters) {
    final needle = filters.query.trim().toLowerCase();
    final now = DateTime.now();

    final out = events.where((e) {
      if (filters.categories.isNotEmpty &&
          !filters.categories.contains(e.category.toLowerCase())) {
        return false;
      }
      if (filters.freeOnly && e.ticketPrice > 0) {
        return false;
      }
      if (filters.upcomingOnly) {
        // An event with no date cannot be proven to be in the future, so it is
        // kept rather than silently hidden.
        if (e.eventDate != null && e.eventDate!.isBefore(now)) return false;
      }
      if (needle.isNotEmpty) {
        final haystack = '${e.title} ${e.description} ${e.location} ${e.organizer}'.toLowerCase();
        if (!haystack.contains(needle)) return false;
      }
      return true;
    }).toList();

    out.sort(_eventComparator(filters.sort));
    return out;
  }

  Comparator<EventListing> _eventComparator(SortOrder order) {
    switch (order) {
      case SortOrder.nameAZ:
        return (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case SortOrder.priceLow:
        return (a, b) => a.ticketPrice.compareTo(b.ticketPrice);
      case SortOrder.priceHigh:
        return (a, b) => b.ticketPrice.compareTo(a.ticketPrice);
      case SortOrder.rating:
        return (a, b) => a.title.compareTo(b.title);
      case SortOrder.newest:
        // Soonest first: the next thing happening is what the reader wants.
        return (a, b) {
          final ad = a.eventDate;
          final bd = b.eventDate;
          if (ad == null && bd == null) return a.title.compareTo(b.title);
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        };
    }
  }

  /// The distinct categories present in [items], from either listing type.
  List<String> categoriesIn(List<ProductListing> products, List<EventListing> events) {
    final found = <String>{};
    for (final p in products) {
      if (p.category.isNotEmpty) found.add(p.category.toLowerCase());
    }
    for (final e in events) {
      if (e.category.isNotEmpty) found.add(e.category.toLowerCase());
    }
    return found.toList()..sort();
  }

  /// Price bounds actually present in the data, so the filter sheet can offer
  /// a meaningful range instead of arbitrary numbers.
  ({double min, double max}) priceRange(List<ProductListing> products) {
    if (products.isEmpty) return (min: 0, max: 0);
    var min = double.infinity;
    var max = 0.0;
    for (final p in products) {
      if (p.price < min) min = p.price;
      if (p.price > max) max = p.price;
    }
    return (min: min, max: max);
  }
}
