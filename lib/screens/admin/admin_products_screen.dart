import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_listing.dart';
import '../../services/admin_service.dart';
import '../../widgets/feature_list_screen.dart';
import 'admin_forms.dart';

/// Moderation over every product, including the seeded listings.
///
/// The seeded inventory is the reason this screen exists. Those documents carry
/// no `sellerId`, so `CatalogService.deleteProduct` - which correctly refuses
/// anything the caller does not own - could never reach them, and the shop's
/// entire original inventory was effectively unmoderatable.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final AdminService _admin = AdminService();

  @override
  Widget build(BuildContext context) {
    return FeatureListScreen<ProductListing>(
      title: 'Products',
      itemsStream: _admin.watchAllProducts(),
      emptyHint: 'No products yet.',
      getTitle: (p) => p.name,
      getSubtitle: (p) => [
            '\$${p.price.toStringAsFixed(2)}',
            if (p.category.isNotEmpty) p.category,
            if (p.stockQuantity > 0) '${p.stockQuantity} in stock',
            // A listing with no sellerId predates in-app selling - it is seeded
            // inventory, and saying so explains why its seller is not editable.
            p.sellerId.isEmpty ? 'seeded' : 'seller ${p.sellerId.substring(0, 4)}',
            if (!p.isAvailable) 'unavailable',
          ].join('  ·  '),
      buildLeading: (p) => CircleAvatar(
        backgroundColor: AppColors.surface,
        child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryLight, size: 20),
      ),
      // Adding a product is intentionally not offered. A product created here
      // would have no seller, so it would appear in the shop with nobody to
      // manage or refund it, and `sellerId` is pinned by the rules. Sellers add
      // their own listings from the shop screen.
      canAdd: false,
      canEdit: (_) => true,
      canDelete: (_) => true,
      onEdit: _editProduct,
      onDelete: _deleteProduct,
    );
  }

  Future<void> _editProduct(ProductListing product) async {
    final values = await showAdminFormDialog(
      context,
      title: 'Edit product',
      fields: [
        AdminFormField(key: 'name', label: 'Name', initialValue: product.name),
        AdminFormField(
          key: 'description',
          label: 'Description',
          initialValue: product.description,
          maxLines: 3,
        ),
        AdminFormField(
          key: 'price',
          label: 'Price',
          initialValue: product.price.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // Parsed here as well as in the service, so a bad value is a field
          // error next to the field rather than a snackbar after the dialog
          // has already closed.
          validator: (value) {
            final parsed = double.tryParse(value);
            if (parsed == null) return 'Enter a number';
            if (parsed < 0) return 'Price cannot be negative';
            return null;
          },
        ),
        AdminFormField(
          key: 'stock',
          label: 'Stock',
          initialValue: product.stockQuantity.toString(),
          keyboardType: TextInputType.number,
          validator: (value) {
            final parsed = int.tryParse(value);
            if (parsed == null) return 'Enter a whole number';
            if (parsed < 0) return 'Stock cannot be negative';
            return null;
          },
        ),
      ],
    );
    if (values == null || !mounted) return;

    final result = await _admin.updateProductFields(
      productId: product.id,
      name: values['name']!,
      description: values['description']!,
      price: double.parse(values['price']!),
      stockQuantity: int.parse(values['stock']!),
      isAvailable: product.isAvailable,
    );
    if (!mounted) return;
    showAdminResult(context, result, success: 'Product updated');
  }

  Future<void> _deleteProduct(ProductListing product) async {
    final result = await _admin.deleteProduct(product.id);
    if (!mounted) return;
    showAdminResult(context, result, success: 'Product removed');
  }
}
