import 'package:faniverse_main/models/content_item.dart';
import 'package:faniverse_main/models/user_listing.dart';
import 'package:faniverse_main/services/search_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = SearchService();

  ContentItem post({
    String id = 'c1',
    String title = 'Post',
    String description = '',
    String category = 'anime',
    String creator = '',
  }) =>
      ContentItem(
        id: id,
        title: title,
        description: description,
        category: category,
        categories: [category],
        creator: creator,
      );

  ProductListing product({
    String id = 'p1',
    String name = 'Item',
    String brand = '',
    String category = 'apparel',
    String description = '',
  }) =>
      ProductListing(
        id: id,
        name: name,
        price: 10,
        brand: brand,
        category: category,
        description: description,
      );

  EventListing event({
    String id = 'e1',
    String title = 'Event',
    String location = '',
    String organizer = '',
    String category = 'con',
  }) =>
      EventListing(
        id: id,
        title: title,
        location: location,
        organizer: organizer,
        category: category,
      );

  group('SearchScope', () {
    test('offers a scope per searchable collection', () {
      expect(
        SearchScope.values.map((s) => s.label),
        containsAll(['All', 'Users', 'Content', 'Merchandise', 'Events']),
      );
    });

    test('only "All" fans out across collections', () {
      expect(SearchScope.all.isAll, isTrue);
      expect(SearchScope.users.isAll, isFalse);
    });
  });

  group('filterContent', () {
    final posts = [
      post(id: 'a', title: 'Attack on Titan theory'),
      post(id: 'b', title: 'Best ramen in Osaka', description: 'food'),
      post(id: 'c', title: 'Unrelated', creator: 'daniel_1a2b'),
    ];

    test('matches on the title, case-insensitively', () {
      final hits = service.filterContent('TITAN', posts);
      expect(hits.map((p) => p.id), ['a']);
    });

    test('matches on the description', () {
      final hits = service.filterContent('osaka', posts);
      expect(hits.map((p) => p.id), ['b']);
    });

    test('matches the creator, so a handle finds that user\'s posts', () {
      final hits = service.filterContent('daniel', posts);
      expect(hits.map((p) => p.id), ['c']);
    });

    test('returns nothing for a blank query rather than everything', () {
      // The caller only searches when a query is present, but a whitespace-only
      // query must not silently list the whole collection.
      expect(service.filterContent('   ', posts), isEmpty);
    });

    test('ignores surrounding whitespace in the query', () {
      expect(service.filterContent('  titan  ', posts).map((p) => p.id), ['a']);
    });

    test('caps the number of results', () {
      final many = [for (var i = 0; i < 40; i++) post(id: '$i', title: 'titan $i')];
      expect(service.filterContent('titan', many, limit: 5), hasLength(5));
    });
  });

  group('filterProducts', () {
    final products = [
      product(id: 'a', name: 'Levi jacket', brand: 'Survey Corps'),
      product(id: 'b', name: 'Charm', category: 'keychains'),
    ];

    test('matches on the name', () {
      expect(service.filterProducts('levi', products).map((p) => p.id), ['a']);
    });

    test('matches on the brand', () {
      expect(service.filterProducts('survey', products).map((p) => p.id), ['a']);
    });

    test('matches on the category', () {
      expect(service.filterProducts('keychain', products).map((p) => p.id), ['b']);
    });

    test('returns nothing for a query that matches no listing', () {
      expect(service.filterProducts('nothing', products), isEmpty);
    });
  });

  group('filterEvents', () {
    final events = [
      event(id: 'a', title: 'Comic Con', location: 'Lagos'),
      event(id: 'b', title: 'Rooftop screening', organizer: 'daniel_1a2b'),
    ];

    test('matches on the title', () {
      expect(service.filterEvents('comic', events).map((e) => e.id), ['a']);
    });

    test('matches on the location', () {
      expect(service.filterEvents('lagos', events).map((e) => e.id), ['a']);
    });

    test('matches the organiser', () {
      expect(service.filterEvents('daniel', events).map((e) => e.id), ['b']);
    });
  });
}
