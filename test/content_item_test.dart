import 'package:faniverse_main/models/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ContentItem parse(Map<String, dynamic> data) =>
      ContentItem.fromFirebase('c1', {
        'title': 'Post',
        'category': 'anime',
        ...data,
      });

  group('ContentItem.authorId', () {
    test('accepts a bare uid from a legacy document', () {
      expect(parse({'author': 'u_0001'}).authorId, 'u_0001');
    });

    test('accepts a users/{uid} path, which is what the offline cache stores', () {
      // jsonEncode flattens a DocumentReference to its path, so a feed served
      // from the local cache has to resolve the uid from the string form. (The
      // reference form itself needs a live Firebase app to construct, so it is
      // not covered here.)
      expect(parse({'author': 'users/u_0001'}).authorId, 'u_0001');
    });

    test('is empty when there is no author field', () {
      // A display name is not an identity, so an unknown author stays unknown
      // and the avatar stays inert rather than opening a wrong profile.
      final item = parse({'creator': 'Daniel Smith'});
      expect(item.authorId, isEmpty);
      expect(item.creator, 'Daniel Smith');
    });

    test('is empty for an unrecognised author value', () {
      expect(parse({'author': 'products/p1'}).authorId, isEmpty);
      expect(parse({'author': 'a/b/c'}).authorId, isEmpty);
      expect(parse({'author': 'users/'}).authorId, isEmpty);
    });
  });

  group('ContentItem.copyWith', () {
    test('keeps the authorId so a patched item is still navigable', () {
      // copyWith is how the feed bumps counters; dropping authorId would
      // silently break the avatar link.
      final item = parse({'author': 'users/u_0001'}).copyWith(likes: 5);
      expect(item.authorId, 'u_0001');
      expect(item.likes, 5);
    });
  });
}
