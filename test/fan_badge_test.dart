import 'package:faniverse_main/models/community.dart';
import 'package:faniverse_main/models/fan_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BadgeRules.evaluate', () {
    test('gives a brand new fan only the newcomer badge', () {
      final badges = BadgeRules.evaluate(const FanActivity());
      final unlocked = badges.where((b) => b.unlocked).map((b) => b.id).toList();

      expect(unlocked, ['newcomer']);
    });

    test('unlocks first post at one post', () {
      final badges = BadgeRules.evaluate(const FanActivity(postCount: 1));
      final first = badges.firstWhere((b) => b.id == 'first-post');

      expect(first.unlocked, isTrue);
      // The higher tier is still locked.
      expect(badges.firstWhere((b) => b.id == 'lorekeeper').unlocked, isFalse);
    });

    test('unlocks lorekeeper at five posts and archivist at twenty', () {
      final atFive = BadgeRules.evaluate(const FanActivity(postCount: 5));
      expect(atFive.firstWhere((b) => b.id == 'lorekeeper').unlocked, isTrue);
      expect(atFive.firstWhere((b) => b.id == 'archivist').unlocked, isFalse);

      final atTwenty = BadgeRules.evaluate(const FanActivity(postCount: 20));
      expect(atTwenty.firstWhere((b) => b.id == 'archivist').unlocked, isTrue);
    });

    test('does not unlock from likes alone', () {
      // Guards against a threshold being met by the wrong signal.
      final badges = BadgeRules.evaluate(const FanActivity(likesReceived: 500));
      expect(badges.firstWhere((b) => b.id == 'first-post').unlocked, isFalse);
      expect(badges.firstWhere((b) => b.id == 'appreciated').unlocked, isTrue);
    });

    test('tracks saves separately from likes', () {
      final badges = BadgeRules.evaluate(const FanActivity(savesReceived: 10));
      expect(badges.firstWhere((b) => b.id == 'curator').unlocked, isTrue);
      expect(badges.firstWhere((b) => b.id == 'appreciated').unlocked, isFalse);
    });

    test('unlocks creator badges from listings and events', () {
      final badges = BadgeRules.evaluate(const FanActivity(eventsCreated: 3, productsListed: 5));
      expect(badges.firstWhere((b) => b.id == 'convention-hero').unlocked, isTrue);
      expect(badges.firstWhere((b) => b.id == 'collector').unlocked, isTrue);
    });

    test('gives every badge a label, description and icon', () {
      for (final badge in BadgeRules.evaluate(const FanActivity())) {
        expect(badge.id, isNotEmpty, reason: badge.label);
        expect(badge.label, isNotEmpty);
        expect(badge.description, isNotEmpty);
        expect(badge.icon, isNotEmpty);
        expect(badge.target, greaterThan(0));
      }
    });

    test('never reports the same id twice', () {
      final ids = BadgeRules.evaluate(const FanActivity()).map((b) => b.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('locks nothing for an account that has done everything', () {
      final badges = BadgeRules.evaluate(const FanActivity(
        postCount: 100,
        likesReceived: 1000,
        savesReceived: 100,
        eventsCreated: 10,
        productsListed: 10,
        communitiesJoined: 10,
      ));
      expect(badges.every((b) => b.unlocked), isTrue);
    });
  });

  group('FanBadge progress', () {
    test('clamps the ratio to 0..1', () {
      expect(const FanBadge(id: 'a', label: 'a', description: '', icon: '', progress: 5, target: 10).ratio, 0.5);
      expect(const FanBadge(id: 'a', label: 'a', description: '', icon: '', progress: 50, target: 10).ratio, 1.0);
      // A zero target would divide by zero.
      expect(const FanBadge(id: 'a', label: 'a', description: '', icon: '', progress: 3, target: 0).ratio, 0.0);
    });

    test('describes what is left', () {
      const badge = FanBadge(id: 'a', label: 'Lorekeeper', description: '', icon: '', progress: 3, target: 5);
      expect(badge.progressLabel, '2 to go');

      const done = FanBadge(id: 'a', label: 'x', description: '', icon: '', progress: 5, target: 5);
      expect(done.progressLabel, 'Unlocked');
    });

    test('copyWith preserves untouched fields', () {
      const original = FanBadge(
        id: 'lorekeeper',
        label: 'Lorekeeper',
        description: 'Published 5 posts',
        icon: 'book',
        progress: 3,
        target: 5,
      );
      final updated = original.copyWith(progress: 5);

      expect(updated.progress, 5);
      expect(updated.unlocked, isTrue);
      expect(updated.label, 'Lorekeeper');
      expect(updated.target, 5);
      // The original must not have been mutated.
      expect(original.progress, 3);
    });
  });

  group('Community model', () {
    test('parses a seeded document', () {
      final community = Community.fromFirestore('c1', {
        'name': 'Anime Night',
        'description': 'Weekly screenings',
        'category': 'anime',
        'createdBy': 'u1',
        'memberCount': 42,
      });

      expect(community.name, 'Anime Night');
      expect(community.memberCount, 42);
      expect(community.createdAt, isNull);
    });

    test('survives a document with no fields', () {
      final community = Community.fromFirestore('c1', {});
      expect(community.name, '');
      expect(community.memberCount, 0);
    });

    test('carries every field the seeded documents use', () {
      final json = const Community(id: '', name: 'X').toJson();
      for (final field in [
        'name', 'description', 'imageUrl', 'category', 'createdBy', 'memberCount', 'createdAt',
      ]) {
        expect(json.containsKey(field), isTrue, reason: 'missing $field');
      }
    });
  });

  group('CommunityPost model', () {
    test('parses a discussion', () {
      final post = CommunityPost.fromFirestore('p1', {
        'title': 'Best watch order?',
        'content': 'Where should I start?',
        'authorId': 'u1',
        'authorName': 'Nova',
        'likesCount': 4,
        'commentsCount': 2,
      });

      expect(post.title, 'Best watch order?');
      expect(post.authorName, 'Nova');
      expect(post.likesCount, 4);
    });

    test('starts a new post at zero engagement', () {
      final json = const CommunityPost(id: '', content: 'hi').toJson();
      // A post that starts pre-liked is a bug waiting to happen.
      expect(json['likesCount'], 0);
      expect(json['commentsCount'], 0);
    });
  });
}
