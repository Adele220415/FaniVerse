import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/categories.dart';
import '../models/category.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';

/// Picks the fandoms a user follows.
///
/// Reached from the profile's overflow menu. The chips used to be rendered on
/// the profile itself with no way to change them from there - the only route
/// back to a picker was re-running onboarding - so the selection and its editor
/// live together now.
///
/// The vocabulary is the merged list, so categories an admin added to Firestore
/// are selectable alongside the compiled-in ones.
///
/// ## Why the minimum of three
///
/// `CategorySelectionScreen` requires three on first registration, and
/// `AuthWrapper` sends any user with an empty list back to it. If this screen
/// allowed a user to drop below three, or to clear the list, saving would land
/// them in onboarding on their next launch - having edited their profile and
/// landed somewhere else as a result. The floor keeps the two paths
/// consistent.
class EditCategoriesScreen extends StatefulWidget {
  const EditCategoriesScreen({super.key, this.authService});

  /// Injectable so the screen can be driven in a test without a live auth
  /// session.
  final AuthService? authService;

  @override
  State<EditCategoriesScreen> createState() => _EditCategoriesScreenState();
}

class _EditCategoriesScreenState extends State<EditCategoriesScreen> {
  static const int minimum = 3;

  final CategoryService _categoryService = CategoryService();
  final Set<String> _selected = {};

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = (widget.authService ?? AuthService()).currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final result = await (widget.authService ?? AuthService()).getUserData(uid);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.data != null) {
        // Normalised on the way in: a document written before the vocabulary
        // was lowercased would otherwise not match a chip and would silently
        // drop the user's existing selection.
        _selected
          ..clear()
          ..addAll(result.data!.categories.map(AppCategories.normalize));
      }
    });
  }

  bool get _canSave =>
      !_saving && _selected.length >= minimum && _selected.isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await (widget.authService ?? AuthService()).updateUserCategories(
      _selected.toList(),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      // `true`, not just a pop: the profile reloads only when something actually
      // changed, so backing out of this screen does not trigger a refetch.
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _saving = false;
      _error = result.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Categories',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCounter(),
                if (_error != null) _buildError(),
                Expanded(child: _buildGrid()),
              ],
            ),
      bottomNavigationBar: _buildSaveBar(),
    );
  }

  Widget _buildCounter() {
    final enough = _selected.length >= minimum;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: enough ? AppColors.success.withOpacity(0.08) : AppColors.surface,
      child: Row(
        children: [
          Icon(
            enough ? Icons.check_circle : Icons.info_outline,
            color: enough ? AppColors.success : AppColors.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              enough
                  ? '${_selected.length} selected'
                  : 'Pick at least $minimum fandoms - ${minimum - _selected.length} to go',
              style: TextStyle(
                color: enough ? AppColors.success : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return StreamBuilder<List<Category>>(
      stream: _categoryService.watchAllCategories(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load categories: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data ?? const <Category>[];

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryChip(
              category: category,
              selected: _selected.contains(category.name),
              onTap: () => setState(() {
                if (!_selected.remove(category.name)) {
                  _selected.add(category.name);
                }
              }),
            );
          },
        );
      },
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canSave ? _save : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.elevated,
              disabledForegroundColor: AppColors.textTertiary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  // A custom category carries an emoji; a compiled-in one is
                  // identified by its artwork, which the grid does not load.
                  category.isCustom
                      ? '${category.icon}  ${category.label}'
                      : category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? AppColors.primaryLight : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (selected)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.check_circle, color: AppColors.primary, size: 15),
              ),
          ],
        ),
      ),
    );
  }
}
