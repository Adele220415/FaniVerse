import 'package:faniverse_main/core/constants/app_roles.dart';
import 'package:faniverse_main/core/constants/categories.dart';
import 'package:faniverse_main/models/category.dart';
import 'package:faniverse_main/models/user_model.dart';
import 'package:faniverse_main/services/category_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRoles.normalize', () {
    test('keeps admin', () {
      expect(AppRoles.normalize('admin'), AppRoles.admin);
    });

    test('keeps fan', () {
      expect(AppRoles.normalize('fan'), AppRoles.fan);
    });

    test('collapses the retired ladder onto fan', () {
      // These documents already exist in the seeded data. None of these rungs
      // mean anything now, so they must resolve to the base role rather than to
      // a value the app has no branch for.
      for (final legacy in ['reader', 'writer', 'editor', 'moderator']) {
        expect(AppRoles.normalize(legacy), AppRoles.fan, reason: legacy);
      }
    });

    test('is case and whitespace insensitive for admin', () {
      expect(AppRoles.normalize('  ADMIN '), AppRoles.admin);
    });

    test('treats null as fan', () {
      // A user document written before the field existed. It must not be
      // classified as anything else.
      expect(AppRoles.normalize(null), AppRoles.fan);
    });

    test('fails closed on an unrecognised value', () {
      // The important direction. A corrupt or hostile role must never widen
      // access, so anything unrecognised becomes the base role.
      for (final junk in ['', 'ADMINISTRATOR', 'root', 'superuser']) {
        expect(AppRoles.normalize(junk), AppRoles.fan, reason: 'for "$junk"');
      }
    });
  });

  group('UserModel role', () {
    UserModel parse(Map<String, dynamic> data) =>
        UserModel.fromFirebase({'uid': 'u1', 'name': 'Sam', ...data}, 'u1');

    test('a new account is a fan', () {
      final user = UserModel.forNewUser(id: 'u1', name: 'Sam', email: 's@x.com');
      expect(user.role, AppRoles.fan);
      expect(user.isAdmin, isFalse);
      expect(user.isFan, isTrue);
    });

    test('an admin document reports isAdmin', () {
      final user = parse({'role': 'admin'});
      expect(user.isAdmin, isTrue);
      expect(user.isFan, isFalse);
    });

    test('a legacy ladder document is a fan', () {
      expect(parse({'role': 'moderator'}).isAdmin, isFalse);
    });

    test('a document with no role is a fan', () {
      expect(parse({}).isAdmin, isFalse);
    });
  });

  group('UserModel.toUpdateJson', () {
    UserModel user() => UserModel.fromFirebase(
          {
            'uid': 'u1',
            'name': 'Sam',
            'email': 's@x.com',
            'role': 'admin',
            'isActive': true,
          },
          'u1',
        );

    test('omits role and isActive', () {
      // Not tidiness - a correctness requirement. firestore.rules pins both
      // fields on update, so a payload carrying them has the entire write
      // rejected and the profile edit fails with PERMISSION_DENIED. Stripping
      // them here is also what stops a client shipping a role of its own.
      final patch = user().toUpdateJson();
      expect(patch.containsKey('role'), isFalse);
      expect(patch.containsKey('isActive'), isFalse);
    });

    test('omits uid, email and createdAt', () {
      final patch = user().toUpdateJson();
      for (final field in ['uid', 'email', 'createdAt']) {
        expect(patch.containsKey(field), isFalse, reason: field);
      }
    });

    test('toAdminJson does carry role and isActive', () {
      // The privileged path is deliberately a different method, so a call site
      // that grants admin rights is obvious at a glance.
      final patch = user().toAdminJson();
      expect(patch['role'], 'admin');
      expect(patch['isActive'], true);
      // Still never the immutable fields.
      expect(patch.containsKey('uid'), isFalse);
      expect(patch.containsKey('email'), isFalse);
      expect(patch.containsKey('createdAt'), isFalse);
    });
  });

  group('CategoryService.merge', () {
    Category custom(String name, {String icon = '📌'}) => Category(
          id: 'c_$name',
          name: name,
          label: AppCategories.label(name),
          icon: icon,
          isCustom: true,
        );

    test('returns the built-ins when the collection is empty', () {
      final merged = CategoryService.merge(AppCategories.catalog, const []);
      expect(merged.length, AppCategories.catalog.length);
      expect(merged.every((c) => !c.isCustom), isTrue);
    });

    test('appends an admin-added category', () {
      final merged =
          CategoryService.merge(AppCategories.catalog, [custom('k-pop')]);
      expect(merged.length, AppCategories.catalog.length + 1);
      expect(merged.any((c) => c.name == 'k-pop' && c.isCustom), isTrue);
    });

    test('does not duplicate a built-in', () {
      // A custom row named `anime` must not produce a second chip. The code and
      // the seed data reference the built-in slug directly, so the built-in
      // wins and the custom row is dropped.
      final merged =
          CategoryService.merge(AppCategories.catalog, [custom('anime')]);
      expect(merged.where((c) => c.name == 'anime').length, 1);
      expect(merged.length, AppCategories.catalog.length);
    });

    test('normalises casing on the way in', () {
      // Firestore arrayContains is case-sensitive, so a stored "K-Pop" would
      // never match a filter built from the lowercase slug.
      final merged =
          CategoryService.merge(AppCategories.catalog, [custom('K-Pop')]);
      expect(merged.any((c) => c.name == 'k-pop'), isTrue);
    });

    test('drops a blank name', () {
      final merged = CategoryService.merge(AppCategories.catalog, [custom('')]);
      expect(merged.length, AppCategories.catalog.length);
    });

    test('is sorted, so the picker order is stable across launches', () {
      final merged = CategoryService.merge(
        AppCategories.catalog,
        [custom('zzz'), custom('aaa')],
      );
      final names = merged.map((c) => c.name).toList();
      expect(names, orderedEquals([...names]..sort()));
    });

    test('a built-in row has no document id, so it cannot be edited', () {
      // This is what the admin screen keys its edit and delete controls off.
      final merged = CategoryService.merge(AppCategories.catalog, const []);
      expect(merged.every((c) => c.id.isEmpty), isTrue);
    });

    test('a custom row keeps its id and has no artwork', () {
      // A custom category must not be handed an art path - the file does not
      // exist, and the artwork loader would fail on it.
      final merged =
          CategoryService.merge(AppCategories.catalog, [custom('k-pop')]);
      final row = merged.firstWhere((c) => c.name == 'k-pop');
      expect(row.id, 'c_k-pop');
      expect(row.artAsset, isNull);
    });
  });

  group('CategoryService.isValidSlug', () {
    test('accepts the shapes AppCategories stores', () {
      for (final slug in ['anime', 'k-pop', 'e-sports', 'tv-shows', 'a1']) {
        expect(CategoryService.isValidSlug(slug), isTrue, reason: slug);
      }
    });

    test('rejects shapes that would break a query', () {
      for (final slug in ['K-Pop', 'k pop', 'k--pop', '-kpop', 'kpop-', '', 'k_pop']) {
        expect(CategoryService.isValidSlug(slug), isFalse, reason: 'for "$slug"');
      }
    });
  });

  group('Category.fromFirestore', () {
    test('normalises the stored name and derives a label', () {
      final category =
          Category.fromFirestore('c1', {'categoryName': 'K-Pop', 'icon': '🎤'});
      expect(category.name, 'k-pop');
      // The label is title-cased from the slug, since the slug is not in the
      // compiled-in vocabulary and has no hand-written label to use.
      expect(category.label, 'K-pop');
      expect(category.icon, '🎤');
      expect(category.isCustom, isTrue);
      expect(category.artAsset, isNull);
    });

    test('falls back to a pin icon for a missing or blank one', () {
      expect(Category.fromFirestore('c1', {'categoryName': 'x'}).icon, '📌');
      expect(
        Category.fromFirestore('c1', {'categoryName': 'x', 'icon': '  '}).icon,
        '📌',
      );
    });

    test('omits the id from the stored document', () {
      // Firestore holds the id as the document key. Writing it into the body as
      // well would let the two disagree.
      expect(
        Category.fromFirestore('c1', {}).toFirestore().containsKey('id'),
        isFalse,
      );
    });

    test('a built-in carries its artwork and no document id', () {
      final merged = CategoryService.merge(AppCategories.catalog, const []);
      final anime = merged.firstWhere((c) => c.name == 'anime');
      expect(anime.artAsset, isNotNull);
      expect(anime.id, isEmpty);
      expect(anime.isCustom, isFalse);
    });
  });
}
