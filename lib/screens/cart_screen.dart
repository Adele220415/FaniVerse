import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/cart_service.dart';

/// The cart, with quantity steppers and a live total.
///
/// The badge in the shop header and the totals here read the same stream, so
/// the number on the icon always matches what is on screen.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.service});

  final CartService? service;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final CartService _cart = widget.service ?? CartService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Your Cart',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          StreamBuilder<List<CartItem>>(
            stream: _cart.watchCart(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <CartItem>[];
              if (items.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: _confirmClear,
                child: const Text('Clear', style: TextStyle(color: AppColors.error)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<CartItem>>(
        stream: _cart.watchCart(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? const <CartItem>[];

          if (items.isEmpty) {
            return const _EmptyCart();
          }

          final subtotal = items.fold<double>(0, (sum, i) => sum + i.lineTotal);

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _CartRow(
                    item: items[index],
                    cart: _cart,
                  ),
                ),
              ),
              _CheckoutBar(
                subtotal: subtotal,
                itemCount: items.fold<int>(0, (sum, i) => sum + i.quantity),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Empty cart?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This removes every item. It cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Empty'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final result = await _cart.clear();
    if (!mounted || result.isSuccess) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error ?? 'Could not empty the cart')),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item, required this.cart});

  final CartItem item;
  final CartService cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 64,
              width: 64,
              child: item.imageUrl.isEmpty
                  ? Container(
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.shopping_bag, color: Colors.white38),
                    )
                  : CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, _) => Container(color: Colors.grey.shade800),
                      errorWidget: (context, _, __) => Container(
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.shopping_bag, color: Colors.white38),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _QuantityStepper(item: item, cart: cart),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${item.lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () => cart.remove(item.id),
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textSecondary),
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatefulWidget {
  const _QuantityStepper({required this.item, required this.cart});

  final CartItem item;
  final CartService cart;

  @override
  State<_QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<_QuantityStepper> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepButton(Icons.remove, () => _change(-1)),
        Container(
          constraints: const BoxConstraints(minWidth: 32),
          alignment: Alignment.center,
          child: Text(
            '${widget.item.quantity}',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
        ),
        _stepButton(Icons.add, () => _change(1)),
      ],
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: _busy ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }

  /// Optimistic, then reconciled.
  ///
  /// The cart stream is the source of truth, so the count updates from the
  /// write rather than being assumed to have landed. Debounced by [_busy] so
  /// rapid taps do not queue writes that arrive out of order.
  Future<void> _change(int delta) async {
    if (_busy) return;
    setState(() => _busy = true);

    final result = await widget.cart.setQuantity(
      widget.item.id,
      widget.item.quantity + delta,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not update the quantity')),
      );
    }
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.subtotal, required this.itemCount});

  final double subtotal;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal ($itemCount item${itemCount == 1 ? '' : 's'})',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Checkout needs a payment backend, which does not exist yet.
                // Rather than a button that silently does nothing, say so.
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Checkout is not wired up yet - no payment provider is connected.'),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Your cart is empty',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add some merchandise from the Shop tab.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
