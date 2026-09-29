import 'package:faniverse_main/models/community.dart';
import 'package:flutter_test/flutter_test.dart';

/// The community model has to read two different document shapes, because the
/// seeded communities and the ones created in-app were written by different
/// code paths.
///
/// The failures these cover are silent: a mis-parsed field produces an empty
/// string, the screen renders a placeholder, and nothing throws. They are easy
/// to ship and hard to notice, so they are pinned here.
void main() {
  group('Community.fromFirestore imageUrl', () {
    Community parse(Object? imageUrl) => Community.fromFirestore('c1', {
          'name': 'Anime Fans',
          if (imageUrl != null) 'imageUrl': imageUrl,
        });

    test('reads the string an in-app community writes', () {
      expect(parse('https://cdn/banner.png').imageUrl, 'https://cdn/banner.png');
    });

    test('unwraps the array the seeded communities write', () {
      // pickImages() in seed/generate.mjs returns an array. A bare toString()
      // here yields "[https://a, https://b]", which is not a URL, so
      // Image.network fails and every seeded community falls back to the
      // placeholder icon.
      expect(
        parse(['https://cdn/first.png', 'https://cdn/second.png']).imageUrl,
        'https://cdn/first.png',
      );
    });

    test('is empty for an empty list, not "[ ]"', () {
      expect(parse(<String>[]).imageUrl, isEmpty);
    });

    test('is empty when the field is absent or null', () {
      expect(parse(null).imageUrl, isEmpty);
    });
  });

  group('Community.fromFirestore createdBy', () {
    Community parse(Object? createdBy) => Community.fromFirestore('c1', {
          'name': 'Anime Fans',
          if (createdBy != null) 'createdBy': createdBy,
        });

    test('reads the bare uid an in-app community writes', () {
      expect(parse('u_0001').createdBy, 'u_0001');
    });

    test('reads a users/{uid} path', () {
      // What jsonEncode leaves behind after flattening a reference.
      expect(parse('users/u_0001').createdBy, 'u_0001');
    });

    test('reads a full resource path', () {
      // What a DocumentReference stringifies to. Without this the creator of
      // every seeded community resolves to the whole path, and no ownership
      // check can ever match it.
      expect(
        parse('projects/p/databases/(default)/documents/users/u_0001').createdBy,
        'u_0001',
      );
    });

    test('is empty when absent', () {
      expect(parse(null).createdBy, isEmpty);
    });

    test('is empty for a path with no user segment', () {
      expect(parse('some/other/path').createdBy, isEmpty);
    });
  });

  group('CommunityPost.fromFirestore', () {
    test('parses a seeded discussion', () {
      final post = CommunityPost.fromFirestore('d1', {
        'title': 'Best opening?',
        'content': 'The film one, easily.',
        'authorId': 'u_0001',
        'authorName': 'daniel_1a2b',
        'likesCount': 12,
        'commentsCount': 3,
      });

      expect(post.title, 'Best opening?');
      expect(post.authorId, 'u_0001');
      expect(post.likesCount, 12);
      expect(post.commentsCount, 3);
    });

    test('defaults the counters to zero for an older document', () {
      final post = CommunityPost.fromFirestore('d1', {'content': 'hi'});
      expect(post.likesCount, 0);
      expect(post.commentsCount, 0);
    });
  });
}
