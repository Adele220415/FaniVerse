import 'package:faniverse_main/models/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppNotification parse(Map<String, dynamic> data) =>
      AppNotification.fromFirestore('id', data);

  group('AppNotification', () {
    test('recognises a save as its own type, not a like', () {
      // Saves used to be indistinguishable from likes in the model, so a saved
      // video produced a notification the app could not describe.
      final save = parse({'type': 'save', 'actorName': 'Dana'});
      expect(save.isSave, isTrue);
      expect(save.isLike, isFalse);
    });

    test('describes a save in the reader-facing sentence', () {
      final save = parse({
        'type': 'save',
        'actorName': 'Dana',
        'contentId': 'c1',
        'contentTitle': 'Season 3 theory',
      });

      expect(save.body, 'Dana saved your post "Season 3 theory"');
    });

    test('omits the title when the post had none', () {
      final save = parse({'type': 'save', 'actorName': 'Dana'});
      expect(save.body, 'Dana saved your post');
    });

    test('falls back to "Someone" for an unnamed actor', () {
      final save = parse({'type': 'save'});
      expect(save.body, startsWith('Someone'));
    });

    test('keeps the actor and content identity needed to navigate', () {
      final save = parse({
        'type': 'save',
        'actorUid': 'u_1',
        'actorName': 'Dana',
        'contentId': 'c1',
      });

      expect(save.actorUid, 'u_1');
      expect(save.contentId, 'c1');
    });

    test('treats a missing read flag as unread', () {
      expect(parse({'type': 'save'}).read, isFalse);
      expect(parse({'type': 'save', 'read': true}).read, isTrue);
    });

    test('does not throw on an empty document', () {
      // Notifications written by an older client may be sparse.
      final notification = parse({});
      expect(notification.type, 'unknown');
      expect(notification.body, isNotEmpty);
    });
  });
}
