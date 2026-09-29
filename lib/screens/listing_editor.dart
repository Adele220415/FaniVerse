import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/result.dart';
import '../models/user_listing.dart';
import '../services/catalog_filters.dart';

/// Which kind of listing the editor creates.
enum ListingKind { product, event }

/// Opens the editor for [kind]. Resolves to true when something was saved.
Future<bool?> showListingEditor(BuildContext context, {required ListingKind kind}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.elevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      // The sheet holds a scrollable form, so it has to be inset for the
      // keyboard and the safe area or the save button sits under both.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _ListingEditor(kind: kind),
    ),
  );
}

/// Form for adding merchandise or an event to your own profile.
///
/// The seller/organizer uid is deliberately absent from the form:
/// [CatalogService] stamps the signed-in user's uid at write time, so a listing
/// cannot be published under someone else's name no matter what is typed here.
class _ListingEditor extends StatefulWidget {
  const _ListingEditor({required this.kind});

  final ListingKind kind;

  @override
  State<_ListingEditor> createState() => _ListingEditorState();
}

class _ListingEditorState extends State<_ListingEditor> {
  final CatalogService _service = CatalogService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _imageUrl = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _category = TextEditingController();
  final TextEditingController _location = TextEditingController();

  bool _saving = false;
  String? _error;

  bool get _isProduct => widget.kind == ListingKind.product;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _price.dispose();
    _category.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = _isProduct ? await _createProduct() : await _createEvent();

    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _saving = false;
      _error = result.error ?? 'Could not save';
    });
  }

  Future<Result<String>> _createProduct() {
    return _service.createProduct(
      ProductListing(
        id: '',
        name: _name.text.trim(),
        description: _description.text.trim(),
        imageUrl: _imageUrl.text.trim(),
        category: _category.text.trim(),
        price: double.tryParse(_price.text.trim()) ?? 0,
        isAvailable: true,
      ),
    );
  }

  Future<Result<String>> _createEvent() {
    return _service.createEvent(
      EventListing(
        id: '',
        title: _name.text.trim(),
        description: _description.text.trim(),
        imageUrl: _imageUrl.text.trim(),
        category: _category.text.trim(),
        location: _location.text.trim(),
        // Tomorrow, so a newly added event is not immediately hidden by the
        // shop's "upcoming only" default.
        eventDate: DateTime.now().add(const Duration(days: 1)),
        status: 'upcoming',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isProduct ? 'Add merchandise' : 'Add an event',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isProduct
                    ? 'It appears on your profile and in the shop.'
                    : 'It appears on your profile and in Events.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _field(_name, _isProduct ? 'Name' : 'Title', required: true),
              const SizedBox(height: 12),
              _field(_description, 'Description', maxLines: 3),
              const SizedBox(height: 12),
              _field(_category, 'Category'),
              const SizedBox(height: 12),
              if (_isProduct)
                _field(_price, 'Price', required: true, numeric: true, prefix: '\$')
              else
                _field(_location, 'Location'),
              const SizedBox(height: 12),
              _field(_imageUrl, 'Image URL (optional)'),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.accent, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isProduct ? 'Add merchandise' : 'Add event'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool numeric = false,
    int maxLines = 1,
    String? prefix,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : null,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixStyle: const TextStyle(color: AppColors.textSecondary),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.field,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return '$label is required';
        if (numeric && text.isNotEmpty && double.tryParse(text) == null) {
          return 'Enter a number';
        }
        return null;
      },
    );
  }
}
