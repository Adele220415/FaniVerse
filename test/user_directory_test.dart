import 'package:faniverse_main/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel.fromFirebase', () {
    UserModel parse(Map<String, dynamic> data, [String id = 'u1']) =>
        UserModel.fromFirebase(data, id);

    test('reads a full-shape document', () {
      final user = parse({
        'uid': 'u1',
        'name': 'Daniel Smith',
        'email': 'dan@example.com',
        'username': 'daniel_1a2b',
        'profileImage': 'https://img/1.png',
        'bio': 'Anime fan',
        'categories': ['anime', 'comics'],
        'role': 'fan',
        'isActive': true,
      });

      expect(user.id, 'u1');
      expect(user.username, 'daniel_1a2b');
      expect(user.categories, ['anime', 'comics']);
      expect(user.role, 'fan');
      expect(user.isActive, isTrue);
    });

    test('preserves the admin role', () {
      expect(parse({'name': 'A B', 'role': 'admin'}).role, 'admin');
    });

    test('normalises an unrecognised role to fan rather than passing it on', () {
      // Roles are a whitelist, so an unknown value must fail closed. The seed
      // data still carries the old 'reader' value, so this is the live case.
      expect(parse({'name': 'A B', 'role': 'reader'}).role, 'fan');
      expect(parse({'name': 'A B', 'role': 'superuser'}).role, 'fan');
    });

    test('derives a username for a legacy document that lacks one', () {
      final user = parse({'name': 'Daniel Smith'});

      expect(user.username, startsWith('daniel_smith_'));
      expect(user.username.length, greaterThan('daniel_smith'.length));
    });

    test('falls back to a default avatar when none is stored', () {
      final user = parse({'name': 'No Avatar'});
      expect(user.profileImage, contains('u1'));
    });

    test('tolerates a non-list categories field', () {
      final user = parse({'name': 'x', 'categories': 'not-a-list'});
      expect(user.categories, isEmpty);
    });

    test('defaults isActive to true so a legacy user is not hidden', () {
      final user = parse({'name': 'x'});
      expect(user.isActive, isTrue);
    });

    test('keeps uid and id consistent when uid is absent', () {
      final user = parse({'name': 'x'}, 'abc123');
      expect(user.uid, 'abc123');
    });
  });

  group('UserModel.deriveUsername', () {
    test('produces a stable handle from a name and uid', () {
      final a = UserModel.deriveUsername('Daniel Smith', '1a2b3c4d');
      final b = UserModel.deriveUsername('Daniel Smith', '1a2b3c4d');
      expect(a, b);
    });

    test('differs for users sharing a name', () {
      final a = UserModel.deriveUsername('Alex Kim', 'aaaa1111');
      final b = UserModel.deriveUsername('Alex Kim', 'bbbb2222');
      expect(a, isNot(b));
    });

    test('falls back to a usable handle for a name with no alphanumerics', () {
      final handle = UserModel.deriveUsername('***', 'zzzz9999');
      expect(handle, startsWith('user_'));
    });

    test('survives a uid shorter than the four-character suffix', () {
      // This runs while parsing Firestore data, so a short id must not throw.
      expect(UserModel.deriveUsername('Dan', 'ab'), 'dan_ab');
      expect(UserModel.deriveUsername('Dan', ''), 'dan_');
    });

    test('parsing a document whose id is short does not throw', () {
      // `parse` is scoped to the fromFirebase group above, so go through the
      // factory directly here.
      final user = UserModel.fromFirebase({'name': 'Daniel Smith'}, 'ab');
      expect(user.username, 'daniel_smith_ab');
    });
  });

  group('UserModel.missingFields', () {
    test('reports absent fields on a legacy document', () {
      final missing = UserModel.missingFields({'name': 'x'});
      expect(missing, contains('username'));
      expect(missing, contains('bio'));
    });

    test('reports nothing for a full document', () {
      final full = UserModel.forNewUser(id: 'u1', name: 'A B', email: 'a@b.com').toJson();
      // toJson uses serverTimestamp sentinels, which still count as present.
      final missing = UserModel.missingFields(full);
      expect(missing, isEmpty, reason: 'unexpectedly missing: $missing');
    });
  });
}
