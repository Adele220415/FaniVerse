import 'package:faniverse_main/models/content_item.dart';
import 'package:faniverse_main/models/content_media.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContentMedia.tryParse', () {
    test('reads a well-formed entry', () {
      final item = ContentMedia.tryParse({
        'type': 'video',
        'url': 'https://res.cloudinary.com/x/video/upload/v1/clip.mp4',
        'thumbnailUrl': 'https://res.cloudinary.com/x/video/upload/so_1/clip.jpg',
        'durationMs': 4200,
      });

      expect(item, isNotNull);
      expect(item!.type, 'video');
      expect(item.isVideo, isTrue);
      expect(item.thumbnailUrl, contains('so_1'));
      expect(item.durationMs, 4200);
    });

    test('rejects entries with no usable url', () {
      expect(ContentMedia.tryParse({'type': 'image'}), isNull);
      expect(ContentMedia.tryParse({'type': 'image', 'url': '   '}), isNull);
      expect(ContentMedia.tryParse('not a map'), isNull);
      expect(ContentMedia.tryParse(null), isNull);
    });

    test('treats an empty thumbnail as absent', () {
      final item = ContentMedia.tryParse({'type': 'image', 'url': 'https://x/a.png', 'thumbnailUrl': ''});
      expect(item!.thumbnailUrl, isNull);
    });

    test('falls back to secure_url for older entries', () {
      final item = ContentMedia.tryParse({
        'secure_url': 'https://res.cloudinary.com/x/image/upload/v1/a.png',
      });
      expect(item!.url, contains('a.png'));
    });
  });

  group('ContentMedia.inferTypeFromUrl', () {
    test('reads the resource type out of the Cloudinary path', () {
      expect(ContentMedia.inferTypeFromUrl('https://res.cloudinary.com/x/image/upload/v1/a.png'), 'image');
      expect(ContentMedia.inferTypeFromUrl('https://res.cloudinary.com/x/video/upload/v1/a.mp4'), 'video');
      expect(ContentMedia.inferTypeFromUrl('https://res.cloudinary.com/x/audio/upload/v1/a.mp3'), 'audio');
    });

    test('falls back to the extension when the path is ambiguous', () {
      // Audio is served by the video pipeline, so /video/ alone cannot tell an
      // mp3 from an mp4 - the extension has to decide.
      expect(ContentMedia.inferTypeFromUrl('https://example.com/tune.mp3'), 'audio');
      expect(ContentMedia.inferTypeFromUrl('https://example.com/clip.mp4'), 'video');
      expect(ContentMedia.inferTypeFromUrl('https://example.com/photo.JPG'), 'image');
    });

    test('defaults to image for anything unrecognised', () {
      expect(ContentMedia.inferTypeFromUrl('https://example.com/asset'), 'image');
    });
  });

  group('ContentItem media', () {
    ContentItem parse(Map<String, dynamic> data) => ContentItem.fromFirebase('id1', data);

    test('preserves the authored slideshow order', () {
      final item = parse({
        'title': 'Trip',
        'category': 'anime',
        'media': [
          {'type': 'image', 'url': 'https://x/1.png'},
          {'type': 'video', 'url': 'https://x/2.mp4'},
          {'type': 'audio', 'url': 'https://x/3.mp3'},
        ],
      });

      expect(item.media.map((m) => m.type).toList(), ['image', 'video', 'audio']);
      expect(item.isSlideshow, isTrue);
    });

    test('synthesises media from the legacy fields when media is absent', () {
      // Documents written before the slideshow existed must still render.
      final item = parse({
        'title': 'Old post',
        'category': 'anime',
        'imageUrl': ['https://x/cover.png'],
        'videoUrl': ['https://x/clip.mp4'],
        'audioUrl': <String>[],
      });

      expect(item.media.map((m) => m.url).toList(), [
        'https://x/cover.png',
        'https://x/clip.mp4',
      ]);
      expect(item.media.first.type, 'image');
      expect(item.isSlideshow, isTrue);
    });

    test('falls back when media is present but empty or unusable', () {
      final item = parse({
        'title': 'Broken media array',
        'category': 'anime',
        'media': <Object>[], // nothing parseable
        'imageUrl': 'https://x/cover.png',
      });

      expect(item.media, hasLength(1));
      expect(item.media.single.url, 'https://x/cover.png');
    });

    test('skips unparseable entries but keeps the rest', () {
      final item = parse({
        'title': 'Partly broken',
        'category': 'anime',
        'media': [
          {'type': 'image', 'url': 'https://x/1.png'},
          {'type': 'image'}, // no url
          'garbage',
          {'type': 'video', 'url': 'https://x/2.mp4'},
        ],
      });

      expect(item.media, hasLength(2));
      expect(item.media.map((m) => m.type).toList(), ['image', 'video']);
    });

    test('is not a slideshow when there is a single item', () {
      final item = parse({
        'title': 'One image',
        'category': 'anime',
        'media': [
          {'type': 'image', 'url': 'https://x/1.png'},
        ],
      });

      expect(item.media, hasLength(1));
      expect(item.isSlideshow, isFalse);
    });
  });

  group('ContentMedia aspect ratio', () {
    test('reads the intrinsic size from the document', () {
      final item = ContentItem.fromFirebase('id1', {
        'title': 'Portrait photo',
        'category': 'anime',
        'media': [
          {'type': 'image', 'url': 'https://x/1.png', 'width': 1080, 'height': 1920},
        ],
      });

      expect(item.media.single.hasDimensions, isTrue);
      expect(item.media.single.aspectRatio, closeTo(1080 / 1920, 0.001));
    });

    test('reports no ratio when the size was never recorded', () {
      final item = ContentItem.fromFirebase('id1', {
        'title': 'Unknown size',
        'category': 'anime',
        'media': [
          {'type': 'image', 'url': 'https://x/1.png'},
        ],
      });

      expect(item.media.single.hasDimensions, isFalse);
      expect(item.media.single.aspectRatio, isNull);
    });

    test('ignores a nonsensical zero size', () {
      final item = ContentMedia(type: 'image', url: 'https://x/1.png', width: 0, height: 100);
      expect(item.hasDimensions, isFalse);
      expect(item.aspectRatio, isNull);
    });
  });

  group('ContentItem.copyWith', () {
    test('keeps every untouched field', () {
      // Regression guard. Rebuilding a post by hand to bump a counter used to
      // drop media/description/creator silently, which made a slideshow
      // disappear the moment someone viewed or liked it.
      final original = ContentItem.fromFirebase('id1', {
        'title': 'Trip',
        'description': 'Photos from the convention',
        'category': 'anime',
        'creator': 'daniel',
        'imageUrl': ['https://x/1.png'],
        'media': [
          {'type': 'image', 'url': 'https://x/1.png', 'width': 100, 'height': 50},
          {'type': 'video', 'url': 'https://x/2.mp4'},
        ],
        'likes': 4,
        'views': 9,
      });

      final bumped = original.copyWith(views: 10, likes: 5);

      expect(bumped.views, 10);
      expect(bumped.likes, 5);
      // Everything else must survive.
      expect(bumped.id, original.id);
      expect(bumped.title, original.title);
      expect(bumped.description, original.description);
      expect(bumped.creator, original.creator);
      expect(bumped.imageUrl, original.imageUrl);
      expect(bumped.media, hasLength(2));
      expect(bumped.media.first.width, 100);
      expect(bumped.isSlideshow, isTrue);
    });

    test('leaves the original untouched', () {
      final original = ContentItem.fromFirebase('id1', {
        'title': 'Trip',
        'category': 'anime',
        'views': 1,
      });

      original.copyWith(views: 99);
      expect(original.views, 1);
    });
  });
}
