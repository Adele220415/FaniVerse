import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faniverse_main/models/user_listing.dart';
import 'package:faniverse_main/services/cart_service.dart';
import 'package:faniverse_main/services/catalog_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProductListing product({
    String id = 'p1',
    String name = 'Item',
    String category = 'anime',
    double price = 10,
    int stock = 5,
    bool available = true,
    String brand = '',
    String description = '',
    double rating = 0,
    DateTime? createdAt,
  }) =>
      ProductListing(
        id: id,
        name: name,
        category: category,
        price: price,
        stockQuantity: stock,
        isAvailable: available,
        brand: brand,
        description: description,
        rating: rating,
        createdAt: createdAt,
      );

  EventListing event({
    String id = 'e1',
    String title = 'Event',
    String category = 'anime',
    String location = 'Tokyo',
    double ticketPrice = 0,
    DateTime? eventDate,
    String organizer = '',
  }) =>
      EventListing(
        id: id,
        title: title,
        category: category,
        location: location,
        ticketPrice: ticketPrice,
        eventDate: eventDate,
        organizer: organizer,
      );

  group('filterProducts', () {
    final catalog = CatalogService();
    final products = [
      product(id: 'a', name: 'Naruto figure', category: 'anime', price: 30, stock: 2, brand: 'Bandai'),
      product(id: 'b', name: 'Comic bundle', category: 'comics', price: 10, stock: 0, available: false),
      product(id: 'c', name: 'Keyboard', category: 'gaming', price: 80, stock: 5, rating: 4.5),
    ];

    test('returns everything with no filters', () {
      expect(catalog.filterProducts(products, ProductFilters.none), hasLength(3));
    });

    test('matches the query across name, brand, description and category', () {
      List<String> namesFor(String q) =>
          catalog.filterProducts(products, ProductFilters(query: q)).map((p) => p.name).toList();

      expect(namesFor('naruto'), ['Naruto figure']);
      expect(namesFor('bandai'), ['Naruto figure']);
      expect(namesFor('gaming'), ['Keyboard']);
      // Case-insensitive, because a shopper types "naruto" not "Naruto".
      expect(namesFor('NARUTO'), ['Naruto figure']);
    });

    test('filters by category', () {
      final out = catalog.filterProducts(products, ProductFilters(categories: {'comics'}));
      expect(out.map((p) => p.id), ['b']);
    });

    test('treats several categories as OR, not AND', () {
      final out = catalog.filterProducts(
        products,
        ProductFilters(categories: {'comics', 'gaming'}),
      );
      expect(out.map((p) => p.id).toSet(), {'b', 'c'});
    });

    test('in-stock excludes both sold-out and zero-stock items', () {
      final out = catalog.filterProducts(products, ProductFilters(inStockOnly: true));
      // 'b' is both unavailable and at zero stock.
      expect(out.map((p) => p.id).toSet(), {'a', 'c'});
    });

    test('applies the price bounds inclusively', () {
      final out = catalog.filterProducts(
        products,
        const ProductFilters(minPrice: 10, maxPrice: 30),
      );
      expect(out.map((p) => p.id).toSet(), {'a', 'b'});
    });

    test('sorts by price in both directions', () {
      expect(
        catalog.filterProducts(products, const ProductFilters(sort: SortOrder.priceLow)).map((p) => p.price),
        [10, 30, 80],
      );
      expect(
        catalog.filterProducts(products, const ProductFilters(sort: SortOrder.priceHigh)).map((p) => p.price),
        [80, 30, 10],
      );
    });

    test('sorts by rating, breaking ties by name for stability', () {
      final tied = [
        product(id: 'z', name: 'Zeta', rating: 3),
        product(id: 'a', name: 'Alpha', rating: 3),
      ];
      final out = catalog.filterProducts(tied, const ProductFilters(sort: SortOrder.rating));
      expect(out.map((p) => p.name), ['Alpha', 'Zeta']);
    });

    test('sorts newest first and puts undated items last', () {
      final dated = [
        product(id: 'old', name: 'Old', createdAt: DateTime(2024)),
        product(id: 'new', name: 'New', createdAt: DateTime(2026)),
        product(id: 'none', name: 'None'),
      ];
      final out = catalog.filterProducts(dated, const ProductFilters(sort: SortOrder.newest));
      expect(out.map((p) => p.id), ['new', 'old', 'none']);
    });

    test('combines filters rather than short-circuiting', () {
      final out = catalog.filterProducts(
        products,
        const ProductFilters(categories: {'anime', 'gaming'}, inStockOnly: true, maxPrice: 50),
      );
      expect(out.map((p) => p.id), ['a']);
    });

    test('reports an active filter count for the badge', () {
      expect(ProductFilters.none.activeCount, 0);
      expect(ProductFilters.none.isActive, isFalse);
      expect(
        const ProductFilters(query: 'x', inStockOnly: true, sort: SortOrder.rating).activeCount,
        3,
      );
    });

    test('copyWith can clear the price bounds', () {
      const withPrice = ProductFilters(minPrice: 5, maxPrice: 50);
      final cleared = withPrice.copyWith(clearMinPrice: true, clearMaxPrice: true);
      expect(cleared.minPrice, isNull);
      expect(cleared.maxPrice, isNull);
    });
  });

  group('filterEvents', () {
    final catalog = CatalogService();
    final now = DateTime.now();
    final events = [
      event(id: 'past', title: 'Old con', eventDate: now.subtract(const Duration(days: 10))),
      event(id: 'soon', title: 'New con', eventDate: now.add(const Duration(days: 10)), ticketPrice: 25),
      event(id: 'free', title: 'Meetup', eventDate: now.add(const Duration(days: 5))),
      event(id: 'undated', title: 'TBA'),
      event(id: 'elsewhere', title: 'Comic fest', location: 'Osaka', eventDate: now.add(const Duration(days: 2))),
    ];

    test('hides past events by default', () {
      final out = catalog.filterEvents(events, EventFilters.none);
      expect(out.map((e) => e.id), isNot(contains('past')));
    });

    test('keeps an undated event, which cannot be proven to be over', () {
      // Dropping it would silently hide legitimate listings.
      final out = catalog.filterEvents(events, EventFilters.none);
      expect(out.map((e) => e.id), contains('undated'));
    });

    test('includes past events when asked', () {
      final out = catalog.filterEvents(events, const EventFilters(upcomingOnly: false));
      expect(out, hasLength(5));
    });

    test('sorts soonest first', () {
      final out = catalog.filterEvents(events, EventFilters.none);
      // Undated sorts last, as does the collection generally put unknowns.
      expect(out.last.id, 'undated');
      expect(out.first.id, isNot('undated'));
    });

    test('filters to free events', () {
      final out = catalog.filterEvents(events, const EventFilters(freeOnly: true));
      expect(out.map((e) => e.id), isNot(contains('soon')));
    });

    test('filters by category', () {
      final mixed = [event(id: 'a', category: 'comics'), event(id: 'b', category: 'anime')];
      final out = catalog.filterEvents(mixed, const EventFilters(categories: {'comics'}));
      expect(out.map((e) => e.id), ['a']);
    });

    test('searches title, location and organiser', () {
      List<String> titlesFor(String q) =>
          catalog.filterEvents(events, EventFilters(query: q)).map((e) => e.title).toList();

      expect(titlesFor('osaka'), contains('Comic fest'));
      expect(titlesFor('con'), isNotEmpty);
    });
  });

  group('citiesIn and categoriesIn', () {
    final catalog = CatalogService();

    test('normalises categories to lowercase and dedupes', () {
      final found = catalog.categoriesIn(
        [product(id: 'a', category: 'Anime'), product(id: 'b', category: 'anime')],
        [event(id: 'c', category: 'Gaming')],
      );
      expect(found, ['anime', 'gaming']);
    });

    test('returns the real price bounds for the slider', () {
      final range = catalog.priceRange([product(price: 5), product(price: 95), product(price: 50)]);
      expect(range.min, 5);
      expect(range.max, 95);
    });

    test('reports a zero range when there is nothing to price', () {
      expect(catalog.priceRange(const []).max, 0);
    });
  });

  group('ProductListing and EventListing', () {
    test('product parses the seeded shape', () {
      final parsed = ProductListing.fromFirestore('p1', {
        'name': 'Figure',
        'price': 29.99,
        'currency': 'EUR',
        'stockQuantity': 4,
        'isAvailable': true,
        'sellerId': 'u1',
        'createdAt': Timestamp.fromDate(DateTime(2026)),
      });

      expect(parsed.name, 'Figure');
      expect(parsed.price, 29.99);
      expect(parsed.currency, 'EUR');
      expect(parsed.createdAt, DateTime(2026));
    });

    test('product survives missing and wrongly typed fields', () {
      final parsed = ProductListing.fromFirestore('p1', {'name': 42});
      expect(parsed.name, '42');
      expect(parsed.price, 0);
      expect(parsed.stockQuantity, 0);
      expect(parsed.createdAt, isNull);
    });

    test('product serialises every field the seeded documents carry', () {
      final json = product(id: 'p1', name: 'X').toJson();
      for (final field in [
        'name', 'description', 'imageUrl', 'images', 'category', 'price', 'currency',
        'stockQuantity', 'size', 'color', 'brand', 'rating', 'reviewsCount', 'sellerId',
        'isAvailable', 'createdAt', 'updatedAt',
      ]) {
        expect(json.containsKey(field), isTrue, reason: 'missing $field');
      }
    });

    test('copyWith overrides the seller but nothing else', () {
      final original = product(id: 'p1', name: 'X', price: 5);
      final copy = original.copyWith(sellerId: 'u9');
      expect(copy.sellerId, 'u9');
      expect(copy.name, 'X');
      expect(copy.price, 5);
    });

    test('event parses a Timestamp date', () {
      final parsed = EventListing.fromFirestore('e1', {
        'title': 'Con',
        'eventDate': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'ticketPrice': 40,
        'organizerId': 'u1',
      });
      expect(parsed.eventDate, DateTime(2026, 5, 1));
      expect(parsed.ticketPrice, 40);
    });

    test('event serialises every field the seeded documents carry', () {
      final json = event(id: 'e1').toJson();
      for (final field in [
        'title', 'description', 'imageUrl', 'category', 'location', 'eventDate',
        'startTime', 'endTime', 'organizer', 'organizerId', 'ticketPrice', 'ticketUrl',
        'status', 'capacity', 'attendeesCount', 'createdAt', 'updatedAt',
      ]) {
        expect(json.containsKey(field), isTrue, reason: 'missing $field');
      }
    });
  });

  group('CartItem', () {
    test('computes a line total from price and quantity', () {
      final item = CartItem.fromFirestore('c1', {'price': 4.5, 'quantity': 3});
      expect(item.lineTotal, 13.5);
    });

    test('defaults a missing quantity to 1 rather than 0', () {
      // A 0 default would make a line free by accident.
      final item = CartItem.fromFirestore('c1', {'price': 10});
      expect(item.quantity, 1);
    });

    test('parses a copied product name and price', () {
      final item = CartItem.fromFirestore('c1', {
        'productId': 'p1',
        'name': 'Figure',
        'price': 12.0,
        'imageUrl': 'https://img/1.png',
        'quantity': 2,
      });
      expect(item.name, 'Figure');
      expect(item.imageUrl, contains('1.png'));
      expect(item.lineTotal, 24);
    });

    test('falls back to a placeholder name when none was copied', () {
      expect(CartItem.fromFirestore('c1', {}).name, 'Product');
    });

    test('serialises the fields the seeded cart_items carry', () {
      final json = CartItem(
        id: 'c1',
        productId: 'p1',
        name: 'X',
        price: 1,
        quantity: 2,
      ).toJson();
      for (final field in ['productId', 'name', 'imageUrl', 'price', 'quantity', 'addedAt', 'updatedAt']) {
        expect(json.containsKey(field), isTrue, reason: 'missing $field');
      }
    });
  });
}
