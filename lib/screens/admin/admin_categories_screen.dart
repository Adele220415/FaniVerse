import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/categories.dart';
import '../../models/category.dart';
import '../../services/admin_service.dart';
import '../../services/category_service.dart';
import '../../widgets/feature_list_screen.dart';
import 'admin_forms.dart';

/// Add, rename and remove fandom categories.
///
/// The list is the *merged* vocabulary: the eleven compiled-in categories plus
/// whatever an admin has added to Firestore. Built-ins are shown but not
/// editable - `AppCategories.catalog` is referenced by the pickers, the shop
/// filters and the artwork loader, so a renamed `anime` in the database would
/// leave the code resolving one slug while the stored documents used another,
/// and the category would silently stop matching anything.
///
/// They are shown rather than hidden so the admin can see the full vocabulary
/// they are extending, which is the point of the screen.
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  /// Reads. [CategoryService] owns the built-in / custom merge, because that is
  /// where those rules live.
  final CategoryService _categories = CategoryService();

  /// Writes. [AdminService] owns the admin guard.
  final AdminService _admin = AdminService();

  @override
  Widget build(BuildContext context) {
    return FeatureListScreen<Category>(
      title: 'Categories',
      itemsStream: _categories.watchAllCategories(),
      emptyHint: 'No categories yet.',
      getTitle: (c) => c.label,
      getSubtitle: (c) => c.isCustom ? c.name : '${c.name}  ·  built in',
      buildLeading: (c) => CircleAvatar(
        backgroundColor: AppColors.surface,
        child: Text(c.icon, style: const TextStyle(fontSize: 18)),
      ),
      canAdd: true,
      // A built-in has no Firestore id, so there is nothing to write to. The
      // controls are hidden rather than disabled for exactly that reason - see
      // FeatureListScreen.
      canEdit: (c) => c.isCustom,
      canDelete: (c) => c.isCustom,
      onAdd: _addCategory,
      onEdit: _editCategory,
      onDelete: _deleteCategory,
    );
  }

  Future<void> _addCategory() async {
    final values = await showAdminFormDialog(
      context,
      title: 'Add category',
      submitLabel: 'Add',
      fields: const [
        AdminFormField(
          key: 'name',
          label: 'Name',
          hint: 'k-pop',
          validator: _validateName,
        ),
        AdminFormField(key: 'icon', label: 'Icon', initialValue: '📌', hint: '🎤'),
      ],
    );
    if (values == null || !mounted) return;

    final result = await _admin.addCategory(
      Category(
        id: '',
        name: values['name']!,
        label: AppCategories.label(values['name']!),
        icon: _iconOr(values['icon']),
        isCustom: true,
      ),
    );
    if (!mounted) return;
    showAdminResult(context, result, success: 'Category added');
  }

  Future<void> _editCategory(Category category) async {
    final values = await showAdminFormDialog(
      context,
      title: 'Edit category',
      fields: [
        AdminFormField(
          key: 'name',
          label: 'Name',
          initialValue: category.name,
          validator: _validateName,
        ),
        AdminFormField(key: 'icon', label: 'Icon', initialValue: category.icon),
      ],
    );
    if (values == null || !mounted) return;

    final result = await _admin.updateCategory(
      category.copyWith(
        name: values['name']!,
        icon: _iconOr(values['icon']),
      ),
    );
    if (!mounted) return;
    showAdminResult(context, result, success: 'Category updated');
  }

  Future<void> _deleteCategory(Category category) async {
    final result = await _admin.deleteCategory(category.id);
    if (!mounted) return;
    showAdminResult(context, result, success: 'Category removed');
  }

  static String _iconOr(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '📌' : trimmed;
  }

  /// Checked before the write so a bad value is a field error beside the field
  /// rather than a snackbar after the dialog has closed. `CategoryService`
  /// re-checks on the service side.
  static String? _validateName(String value) {
    if (value.trim().isEmpty) return 'A category needs a name';
    if (!CategoryService.isValidSlug(AppCategories.normalize(value))) {
      return 'Use lowercase letters, numbers and single dashes (e.g. k-pop)';
    }
    if (AppCategories.isValid(value)) return 'That category already exists';
    return null;
  }
}
