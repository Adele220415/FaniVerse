import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faniverse_main/models/content_item.dart';
import 'package:faniverse_main/services/feed_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ContentItem post({
    required String id,
    List<String> categories = const ['anime'],
    int likes = 0,
    int views = 0,
    int comments = 0,
    int saved = 0,
    DateTime? createdAt,
  }) {
    return ContentItem.fromFirebase(id, {
      'title': 'Post $id',
      'category': categories.isEmpty ? '' : categories.first,
      'categories': categories,
      'likes': likes,
      'views': views,
      'comments': comments,
      'saved': saved,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt),
    });
  }

  List<String> ids(List<ContentItem> items) => items.map((i) => i.id).toList();

  group('trending', () {
    test('ranks by engagement, most first', () {
      final items = [
        post(id: 'low', likes: 1),
        post(id: 'high', likes: 50, views: 500, comments: 10, saved: 20),
        post(id: 'mid', likes: 10, views: 100),
      ];

      final sorted = FeedSorter.sort(items, FeedMode.trending);
      expect(ids(sorted).first, 'high');
    });

    test('is reproducible - two runs give the same order', () {
      // Trending must be defensible, so no randomness here.
      final items = [
        post(id: 'a', likes: 5),
        post(id: 'b', likes: 5, comments: 1),
        post(id: 'c', likes: 5, views: 1),
      ];

      final first = ids(FeedSorter.sort(items, FeedMode.trending));
      final second = ids(FeedSorter.sort(items, FeedMode.trending));
      expect(first, second);
    });

    test('weights saves above views', () {
      // A saved post is a stronger signal than a scrolled-past one.
      final savedPost = post(id: 'saved', saved: 2);
      final viewedPost = post(id: 'viewed', views: 2);
      final sorted = FeedSorter.sort([viewedPost, savedPost], FeedMode.trending);
      expect(sorted.first.id, 'saved');
    });

    test('leaves the input list untouched', () {
      final items = [
        post(id: 'a', likes: 1),
        post(id: 'b', likes: 9),
      ];
      final before = ids(items);

      FeedSorter.sort(items, FeedMode.trending);
      expect(ids(items), before);
    });
  });

  group('latest', () {
    test('ranks newest first', () {
      final items = [
        post(id: 'old', createdAt: DateTime(2024)),
        post(id: 'new', createdAt: DateTime(2026)),
        post(id: 'mid', createdAt: DateTime(2025)),
      ];

      expect(ids(FeedSorter.sort(items, FeedMode.latest)), ['new', 'mid', 'old']);
    });

    test('puts undated posts last rather than throwing', () {
      final items = [
        post(id: 'none'),
        post(id: 'dated', createdAt: DateTime(2024)),
      ];

      final sorted = FeedSorter.sort(items, FeedMode.latest);
      expect(sorted.last.id, 'none');
    });

    test('ignores likes entirely', () {
      // A much older but more-liked post must still sort last.
      final items = [
        post(id: 'oldLiked', likes: 999, createdAt: DateTime(2020)),
        post(id: 'newQuiet', createdAt: DateTime(2026)),
      ];

      expect(FeedSorter.sort(items, FeedMode.latest).first.id, 'newQuiet');
    });
  });

  group('forYou', () {
    test('leads with the viewer\'s own fandoms on a near-tie', () {
      // Personalisation is meant to break ties, not to invert a clear gap, so
      // the two posts here are close on engagement.
      final items = [
        post(id: 'other', categories: const ['gaming'], likes: 10),
        post(id: 'mine', categories: const ['anime'], likes: 10),
      ];

      final sorted = FeedSorter.sort(
        items,
        FeedMode.forYou,
        preferredCategories: const {'anime'},
        random: Random(1),
      );
      expect(sorted.first.id, 'mine');
    });

    test('does not bury a genuinely popular post from another fandom', () {
      // The personalisation boost is bounded, so it breaks ties rather than
      // winning outright against a big engagement gap.
      final items = [
        post(id: 'other', categories: const ['gaming'], likes: 400, views: 4000),
        post(id: 'mine', categories: const ['anime'], likes: 1),
      ];

      final sorted = FeedSorter.sort(
        items,
        FeedMode.forYou,
        preferredCategories: const {'anime'},
        random: Random(1),
      );
      expect(sorted.first.id, 'other');
    });

    test('shuffles, so the same post does not sit at rank one forever', () {
      // A dozen posts with near-identical engagement, in a fandom the viewer
      // follows. Without jitter the order would be the insertion order.
      final items = [
        for (var i = 0; i < 12; i++) post(id: 'p$i', likes: 10),
      ];

      final orders = <List<String>>{};
      for (var seed = 0; seed < 8; seed++) {
        orders.add(ids(FeedSorter.sort(
          items,
          FeedMode.forYou,
          preferredCategories: const {'anime'},
          random: Random(seed),
        )));
      }

      // At least one run must differ from the first.
      expect(orders.skip(1).any((order) => order.join() != orders.first.join()), isTrue);
    });

    test('is deterministic for a given seed', () {
      // A rebuild must not reshuffle the feed under the reader.
      final items = [for (var i = 0; i < 6; i++) post(id: 'p$i', likes: 5)];

      List<String> run() => ids(FeedSorter.sort(
            items,
            FeedMode.forYou,
            preferredCategories: const {'anime'},
            random: Random(7),
          ));

      expect(run(), run());
    });

    test('works with no preferred categories at all', () {
      // A fan who has picked no fandoms still gets a feed.
      final items = [post(id: 'a', likes: 5), post(id: 'b', likes: 1)];

      final sorted = FeedSorter.sort(
        items,
        FeedMode.forYou,
        preferredCategories: const {},
        random: Random(1),
      );
      expect(sorted, hasLength(2));
    });
  });

  group('modes differ', () {
    test('the three modes do not all produce the same order', () {
      // Guards against the three pills being aliases, which is what they were
      // before any of this existed. Engagement here is kept close so the
      // personalisation boost is what decides forYou, while trending and
      // latest each follow their own rule.
      final items = [
        post(id: 'myFandomOld', categories: const ['anime'], likes: 10, createdAt: DateTime(2020)),
        post(id: 'otherFandomHot', categories: const ['gaming'], likes: 12, createdAt: DateTime(2024)),
        post(id: 'newQuiet', categories: const ['anime'], likes: 8, createdAt: DateTime(2026)),
      ];
      final preferred = const {'anime'};

      final forYou = ids(FeedSorter.sort(items, FeedMode.forYou, preferredCategories: preferred, random: Random(3)));
      final trending = ids(FeedSorter.sort(items, FeedMode.trending));
      final latest = ids(FeedSorter.sort(items, FeedMode.latest));

      expect(trending, ['otherFandomHot', 'myFandomOld', 'newQuiet']);
      expect(latest, ['newQuiet', 'otherFandomHot', 'myFandomOld']);
      // The boost is worth about 40 points, or roughly 13 likes at 3 each, so
      // the anime posts overtake a modestly more-liked gaming one.
      expect(forYou.first, 'myFandomOld');
    });
  });

  group('matchesAnyCategory', () {
    test('matches any of the candidates', () {
      final item = post(id: 'a', categories: const ['manga', 'anime']);
      expect(item.matchesAnyCategory({'anime', 'gaming'}), isTrue);
      expect(item.matchesAnyCategory({'gaming'}), isFalse);
    });

    test('tolerates Title Case in the stored value', () {
      final item = post(id: 'a', categories: const ['Anime']);
      expect(item.matchesAnyCategory({'anime'}), isTrue);
    });

    test('an empty candidate set matches nothing', () {
      final item = post(id: 'a');
      expect(item.matchesAnyCategory({}), isFalse);
    });
  });
}
