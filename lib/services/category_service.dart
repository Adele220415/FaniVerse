import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/categories.dart';
import '../core/result.dart';
import '../models/category.dart';

/// Reads and writes the admin-added `categories` collection.
///
/// ## Why categories are merged rather than replaced
///
/// The eleven compiled-in categories are referenced directly by the pickers,
/// the shop filters, the artwork loader and the seed data, so they have to
/// exist before any query has returned - the category picker and the AI
/// recommender both need a non-empty list on a cold start. Making Firestore the
/// only source would turn every one of those into an async call that can fail
/// or arrive empty, and would put an artwork path at the mercy of a document
/// field.
///
/// So the two are merged in [merge]: compiled-in first, then admin-added. A
/// compiled-in slug wins a collision, and deleting a compiled-in category is
/// refused for the same reason - see [Category].
class CategoryService {
  final FirebaseFirestore? _firestore;

  /// Resolved lazily so the pure merge logic can be exercised in a test
  /// without initialising Firebase.
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CategoryService({FirebaseFirestore? firestore}) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('categories');

  /// Live list of admin-added categories only. The collection is usually
  /// empty, which is normal rather than an error - the compiled-ins live in
  /// code.
  Stream<List<Category>> watchCustomCategories() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Category.fromFirestore(doc.id, doc.data()))
          .where((c) => c.name.isNotEmpty)
          .toList();
    });
  }

  /// The full vocabulary: compiled-in plus admin-added.
  ///
  /// Sorted so the picker order is stable across launches. Firestore returns
  /// documents in document-id order, which is arbitrary to a person reading a
  /// grid of fandoms.
  Stream<List<Category>> watchAllCategories() {
    return watchCustomCategories().map(
      (custom) => merge(AppCategories.catalog, custom),
    );
  }

  /// One-shot read, for callers that need the list outside a widget.
  Future<Result<List<Category>>> getAllCategories() async {
    try {
      final snapshot = await _collection.get();
      final custom = snapshot.docs
          .map((doc) => Category.fromFirestore(doc.id, doc.data()))
          .where((c) => c.name.isNotEmpty)
          .toList();
      return Result.success(merge(AppCategories.catalog, custom));
    } catch (e) {
      return Result.error('Could not load categories: $e');
    }
  }

  /// The flat slug list, for the callers that only need strings - the
  /// `arrayContains` filters and the recommender's prompt builder.
  Stream<List<String>> watchCategoryNames() {
    return watchAllCategories().map((list) => list.map((c) => c.name).toList());
  }

  /// Merges [custom] onto [builtins], dropping duplicates.
  ///
  /// Static so the ordering and de-duplication rules are testable without a
  /// Firestore instance.
  static List<Category> merge(
    List<CategoryArt> builtins,
    List<Category> custom,
  ) {
    final seen = builtins.map((c) => AppCategories.normalize(c.value)).toSet();
    final merged = <Category>[
      for (final art in builtins) Category.builtin(art),
    ];

    for (final category in custom) {
      final name = AppCategories.normalize(category.name);
      if (name.isEmpty || seen.contains(name)) continue;
      seen.add(name);
      merged.add(category.copyWith(name: name));
    }

    merged.sort((a, b) => a.name.compareTo(b.name));
    return merged;
  }

  /// Creates a category. Refuses a name that is already taken.
  ///
  /// The duplicate check is client-side and therefore advisory. The real
  /// protection is that a duplicate would produce two identical filter chips,
  /// and [merge] de-duplicates on read regardless - so even a race between two
  /// admins tapping Add cannot corrupt the picker.
  Future<Result<String>> addCategory(Category category) async {
    final name = AppCategories.normalize(category.name);
    if (name.isEmpty) {
      return Result.error('A category needs a name');
    }
    if (!isValidSlug(name)) {
      return Result.error(
        'Use lowercase letters, numbers and single dashes (e.g. "k-pop")',
      );
    }
    if (AppCategories.isValid(name)) {
      return Result.error('"${AppCategories.label(name)}" already exists');
    }

    try {
      final existing = await _collection
          .where('categoryName', isEqualTo: name)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return Result.error('"${AppCategories.label(name)}" already exists');
      }

      final docRef = await _collection.add(
        Category(
          id: '',
          name: name,
          label: AppCategories.label(name),
          icon: category.icon,
          isCustom: true,
        ).toFirestore(),
      );
      return Result.success(docRef.id);
    } catch (e) {
      return Result.error('Could not add the category: $e');
    }
  }

  Future<Result<void>> updateCategory(Category category) async {
    if (category.id.isEmpty) {
      return Result.error('That category cannot be edited');
    }

    final name = AppCategories.normalize(category.name);
    if (name.isEmpty) {
      return Result.error('A category needs a name');
    }
    if (!isValidSlug(name)) {
      return Result.error(
        'Use lowercase letters, numbers and single dashes (e.g. "k-pop")',
      );
    }

    try {
      await _collection.doc(category.id).update({
        'categoryName': name,
        'icon': category.icon,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not update the category: $e');
    }
  }

  /// Deletes an admin-added category.
  ///
  /// Refuses compiled-in categories: they have no document id to delete, and
  /// they are referenced by compiled-in code.
  Future<Result<void>> deleteCategory(String id) async {
    if (id.isEmpty) {
      return Result.error('That category is built in and cannot be deleted');
    }

    try {
      await _collection.doc(id).delete();
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not delete the category: $e');
    }
  }

  /// Slug shape guard, in step with the lowercase single-dash form that
  /// `AppCategories` stores and every `arrayContains` query assumes.
  static bool isValidSlug(String value) {
    return RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(value);
  }
}
