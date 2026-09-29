import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/result.dart';

/// Shared bits for the admin screens: a form dialog shell and a result snackbar.
///
/// The five admin sections are the same screen with different fields, and the
/// parts that are easy to get subtly wrong - dropping a keyboard, leaking a
/// [TextEditingController], showing a blank snackbar on failure - are worth
/// writing once.

/// Shows a modal form built from [fields] and returns the entered values.
///
/// Controllers are created here and disposed by [StatefulBuilder] once the
/// dialog closes, which is the only point at which it is safe: a controller
/// disposed while the dialog is still animating out throws on the teardown
/// frame. The dialog's own `State` is not accessible from the builder, so a
/// small [_FormDialog] widget owns the lifecycle instead.
///
/// Returns null when the dialog is dismissed without saving.
Future<Map<String, String>?> showAdminFormDialog(
  BuildContext context, {
  required String title,
  required List<AdminFormField> fields,
  String submitLabel = 'Save',
}) {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (_) => _FormDialog(
      title: title,
      fields: fields,
      submitLabel: submitLabel,
    ),
  );
}

/// One input in an [showAdminFormDialog] form.
class AdminFormField {
  const AdminFormField({
    required this.key,
    required this.label,
    this.initialValue = '',
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  /// Identifies the field in the returned map. Must be unique within a form.
  final String key;

  final String label;
  final String initialValue;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  /// Return an error string to block submission, or null to accept.
  final String? Function(String value)? validator;
}

class _FormDialog extends StatefulWidget {
  const _FormDialog({
    required this.title,
    required this.fields,
    required this.submitLabel,
  });

  final String title;
  final List<AdminFormField> fields;
  final String submitLabel;

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      _controllers[field.key] = TextEditingController(text: field.initialValue);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final values = <String, String>{};
    for (final entry in _controllers.entries) {
      values[entry.key] = entry.value.text.trim();
    }
    Navigator.of(context).pop(values);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.elevated,
      title: Text(
        widget.title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      // Sized rather than scroll-constrained: an AlertDialog already bounds its
      // child, and a long form needs to scroll inside that bound.
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in widget.fields) ...[
                  TextFormField(
                    controller: _controllers[field.key],
                    maxLines: field.maxLines,
                    keyboardType: field.keyboardType,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: field.label,
                      hintText: field.hint,
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
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
                    ),
                    validator: (value) => field.validator?.call(value ?? ''),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

/// Reports the outcome of an admin write.
///
/// Always says something. A silent failure on a moderation action reads as a
/// write that worked, which is the more expensive mistake of the two.
void showAdminResult(BuildContext context, Result<Object?> result, {String? success}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result.isSuccess ? (success ?? 'Saved') : (result.error ?? 'Something went wrong'),
      ),
      backgroundColor: result.isSuccess ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// A small switch row, used for the is-available toggle on products.
class AdminSwitchRow extends StatelessWidget {
  const AdminSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}
