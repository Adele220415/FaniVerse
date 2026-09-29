import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/categories.dart';
import '../services/community_service.dart';
import '../widgets/fv_screen.dart';

/// Creates a community. Pops `true` on success so the caller can refresh.
class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key, this.service});

  final CommunityService? service;

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final CommunityService _service = widget.service ?? CommunityService();

  String _category = AppCategories.all.first;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give the community a name')),
      );
      return;
    }

    setState(() => _busy = true);
    final result = await _service.createCommunity(
      name: _nameController.text,
      description: _descriptionController.text,
      category: _category,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not create'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'New community',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Anime night crew',
              labelStyle: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'What is this community for?',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'CATEGORY',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppCategories.all.map((category) {
              final selected = _category == category;
              return FilterChip(
                label: Text(AppCategories.label(category)),
                selected: selected,
                onSelected: (_) => setState(() => _category = category),
                selectedColor: AppColors.primaryTint,
                checkmarkColor: AppColors.primaryLight,
                backgroundColor: AppColors.elevated,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primaryLight : AppColors.textSecondary,
                  fontSize: 12,
                ),
                side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          FvPrimaryButton(
            label: 'Create community',
            busy: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
