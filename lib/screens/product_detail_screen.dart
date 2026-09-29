import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/user_listing.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';

/// A product's own page.
///
/// Replaces routing a product through `ContentDetailScreen`, which is the post
/// viewer: a product is not a post, so it got an empty title, no price and no
/// way to buy it.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    this.cartService,
  });

  final ProductListing product;
  final CartService? cartService;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final CartService _cart = widget.cartService ?? CartService();
  int _quantity = 1;
  bool _adding = false;

  Future<void> _addToCart() async {
    if (_adding) return;
    setState(() => _adding = true);

    final result = await _cart.addProduct(widget.product, quantity: _quantity);
    if (!mounted) return;
    setState(() => _adding = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? 'Added ${widget.product.quantityIn(_quantity)} to your cart'
              : (result.error ?? 'Could not add to cart'),
        ),
        backgroundColor: result.isSuccess ? null : AppColors.error,
        action: result.isSuccess
            ? SnackBarAction(
                label: 'View cart',
                textColor: Colors.white,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CartScreen(service: _cart)),
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final soldOut = !product.isAvailable || product.stockQuantity <= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Product',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: product.imageUrl.isEmpty
                        ? Container(
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.shopping_bag, size: 48, color: Colors.white38),
                          )
                        : CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, _) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, _, __) => Container(
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.shopping_bag, size: 48, color: Colors.white38),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                if (product.category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.category.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    if (product.rating > 0) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${product.rating.toStringAsFixed(1)} (${product.reviewsCount})',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Availability is stated plainly rather than left to inference.
                Text(
                  soldOut
                      ? 'Out of stock'
                      : '${product.stockQuantity} in stock',
                  style: TextStyle(
                    color: soldOut ? AppColors.error : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: soldOut ? FontWeight.bold : FontWeight.normal,
                  ),
                ),

                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    product.description,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                  ),
                ],

                if (product.brand.isNotEmpty || product.size.isNotEmpty || product.color.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 8),
                  if (product.brand.isNotEmpty) _spec('Brand', product.brand),
                  if (product.size.isNotEmpty) _spec('Size', product.size),
                  if (product.color.isNotEmpty) _spec('Colour', product.color),
                ],
              ],
            ),
          ),

          if (!soldOut)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    _quantityStepper(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _adding ? null : _addToCart,
                        icon: _adding
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.add_shopping_cart, size: 18),
                        label: Text(
                          _adding
                              ? 'Adding...'
                              : 'Add to cart - \$${(product.price * _quantity).toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _spec(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _quantityStepper() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
            icon: const Icon(Icons.remove, size: 16),
            color: AppColors.textPrimary,
            disabledColor: AppColors.border,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            '$_quantity',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          IconButton(
            // Capped at stock: letting a shopper add 99 of a 3-in-stock item
            // would create a cart the shop cannot fulfil.
            onPressed: _quantity < widget.product.stockQuantity
                ? () => setState(() => _quantity++)
                : null,
            icon: const Icon(Icons.add, size: 16),
            color: AppColors.textPrimary,
            disabledColor: AppColors.border,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
