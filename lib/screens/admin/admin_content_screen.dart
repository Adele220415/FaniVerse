import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/category.dart';
import '../../models/content_item.dart';
import '../../services/admin_service.dart';
import '../../services/category_service.dart';
import '../../widgets/feature_list_screen.dart';
import 'admin_forms.dart';

/// Moderation over every post in the app, whoever wrote it.
///
/// Editing is limited to title, description and categories. Media, engagement
/// counters and authorship are not offered: the counters are maintained
/// transactionally by `EngagementService`, and letting an admin write them
/// would put a number in the document that no longer matches the sum of the
/// events that produced it. Authorship is pinned by the Firestore rule for the
/// same reason, so offering it here would only produce a write that fails.
class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  final AdminService _admin = AdminService();
  final CategoryService _categories = CategoryService();

  @override
  Widget build(BuildContext context) {
    return FeatureListScreen<ContentItem>(
      title: 'Content',
      itemsStream: _admin.watchAllContent(),
      emptyHint: 'No posts yet.',
      getTitle: (item) => item.title,
      getSubtitle: (item) => [
            if (item.type.isNotEmpty) item.type,
            if (item.category.isNotEmpty) item.category,
            if (item.creator.isNotEmpty) 'by ${item.creator}',
            '${item.likes} likes',
          ].join('  ·  '),
      buildLeading: (item) => CircleAvatar(
        backgroundColor: AppColors.surface,
        child: Icon(_iconFor(item.type), color: AppColors.primaryLight, size: 20),
      ),
      canAdd: false,
      canEdit: (_) => true,
      canDelete: (_) => true,
      onEdit: _editContent,
      onDelete: _deleteContent,
    );
  }

  Future<void> _editContent(ContentItem item) async {
    // Read the live category list so the admin can only assign a fandom that
    // actually exists - a typo here would be invisible in the feed, because a
    // post in an unknown category matches no filter and no recommendation.
    final available = await _categories.getAllCategories();
    if (!mounted) return;

    final names = (available.data ?? const <Category>[]).map((c) => c.name).toList();
    final current = item.categories.isEmpty ? [item.category] : item.categories;

    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ContentFormDialog(
        item: item,
        available: names,
        selected: current.where((c) => c.isNotEmpty).toList(),
      ),
    );
    if (values == null || !mounted) return;

    final result = await _admin.updateContentFields(
      contentId: item.id,
      title: values['title'] as String,
      description: values['description'] as String,
      categories: (values['categories'] as List<String>? ?? const []),
    );
    if (!mounted) return;
    showAdminResult(context, result, success: 'Post updated');
  }

  Future<void> _deleteContent(ContentItem item) async {
    final result = await _admin.deleteContent(item.id);
    if (!mounted) return;
    showAdminResult(context, result, success: 'Post removed');
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_outline;
      case 'audio':
        return Icons.graphic_eq;
      case 'image':
      case 'comic':
        return Icons.image_outlined;
      case 'text':
      case 'fanfic':
        return Icons.article_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }
}

/// Multi-select category picker plus the editable fields.
///
/// Built as its own widget rather than reusing `showAdminFormDialog` because
/// it needs checkbox state rather than a text field, and because it has to
/// dispose the title/description controllers itself.
class _ContentFormDialog extends StatefulWidget {
  const _ContentFormDialog({
    required this.item,
    required this.available,
    required this.selected,
  });

  final ContentItem item;
  final List<String> available;
  final List<String> selected;

  @override
  State<_ContentFormDialog> createState() => _ContentFormDialogState();
}

class _ContentFormDialogState extends State<_ContentFormDialog> {
  late final TextEditingController _title =
      TextEditingController(text: widget.item.title);
  late final TextEditingController _description =
      TextEditingController(text: widget.item.description);
  late final Set<String> _selected = {...widget.selected};

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;

    Navigator.of(context).pop({
      'title': title,
      'description': _description.text.trim(),
      'categories': _selected.toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.elevated,
      title: const Text(
        'Edit post',
        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: _decoration('Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: _decoration('Description'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Categories',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 6),
              if (widget.available.isEmpty)
                const Text(
                  'No categories available.',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final name in widget.available)
                      FilterChip(
                        label: Text(name, style: const TextStyle(fontSize: 11)),
                        selected: _selected.contains(name),
                        onSelected: (on) => setState(() {
                          if (on) {
                            _selected.add(name);
                          } else {
                            _selected.remove(name);
                          }
                        }),
                        backgroundColor: AppColors.field,
                        selectedColor: AppColors.primaryTint,
                        checkmarkColor: AppColors.primaryLight,
                        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Save'),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      filled: true,
      fillColor: AppColors.field,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
