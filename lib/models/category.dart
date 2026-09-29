import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/categories.dart';

/// A fandom category, whether it is compiled in or added by an admin.
///
/// The app has two category sources and one type for both, because the admin
/// screen has to present them as a single vocabulary and the pickers have to
/// resolve either one the same way:
///
///  * **Compiled in** - `AppCategories.catalog`, a fixed list of `CategoryArt`
///    with a value, a label and an SVG. Cannot change at runtime.
///  * **Added by an admin** - a document in the Firestore `categories`
///    collection, with a value and an emoji. Changes at runtime.
///
/// [isCustom] tells them apart, and so does [id]: a compiled-in category has no
/// document to read or write, which is exactly what the admin screen keys its
/// edit and delete controls off.
///
/// The two are kept apart in the *store* rather than in the type on purpose.
/// A compiled-in slug is referenced directly by the pickers, the shop filters,
/// the artwork loader and the seed data, so an admin renaming `anime` in the
/// database would leave the code resolving one slug while the stored documents
/// used another - and the category would silently stop matching anything.
/// `CategoryService.merge` therefore lets a compiled-in slug win a collision,
/// and refuses to delete one.
///
/// Named `Category` rather than `CategoryArt` for symmetry with the constants
/// file, which renamed its own entry type to `CategoryArt` to keep the two
/// unambiguous in an import graph.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.label,
    this.icon = '📌',
    this.artAsset,
    this.isCustom = false,
  });

  /// Firestore document id. Empty for a compiled-in category, which is what
  /// makes it non-editable.
  final String id;

  /// Canonical lowercase slug, e.g. `anime`. The identity every query and
  /// filter compares against.
  final String name;

  /// Human-readable label for display.
  final String label;

  /// A single emoji. Carries the visual for an admin-added category, which has
  /// no artwork.
  final String icon;

  /// Illustration path for a compiled-in category, or null for a custom one.
  ///
  /// Null rather than a placeholder: the artwork loader must not be handed a
  /// path to a file that does not exist.
  final String? artAsset;

  /// True when this came from Firestore rather than from `AppCategories`.
  final bool isCustom;

  /// A compiled-in category, for building the merged list in memory.
  factory Category.builtin(CategoryArt art) {
    return Category(
      id: '',
      name: art.value,
      label: art.label,
      artAsset: art.asset,
    );
  }

  /// An admin-added document.
  factory Category.fromFirestore(String id, Map<String, dynamic> data) {
    final rawIcon = data['icon']?.toString().trim() ?? '';
    final name = AppCategories.normalize(data['categoryName']?.toString() ?? '');

    return Category(
      id: id,
      name: name,
      label: AppCategories.label(name),
      icon: rawIcon.isEmpty ? '📌' : rawIcon,
      isCustom: true,
    );
  }

  /// The stored document.
  ///
  /// [id] is intentionally absent: Firestore holds it as the document key, and
  /// writing it into the body as well would let the two disagree.
  Map<String, dynamic> toFirestore() {
    return {
      'categoryName': name,
      'icon': icon,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Category copyWith({String? name, String? icon}) => Category(
        id: id,
        name: name ?? this.name,
        label: name != null ? AppCategories.label(name) : label,
        icon: icon ?? this.icon,
        artAsset: artAsset,
        isCustom: isCustom,
      );
}
