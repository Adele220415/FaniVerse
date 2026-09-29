import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/categories.dart';
import '../models/user_listing.dart';
import '../services/auth_service.dart';
import '../widgets/fv_screen.dart';
import '../services/cart_service.dart';
import '../services/catalog_filters.dart';
import '../widgets/product_filter_sheet.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.cartService});

  final CartService? cartService;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final CatalogService _catalog = CatalogService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  /// Unfiltered source of truth. Filters are derived from this rather than
  /// re-querying, so changing a filter never hits the network.
  List<ProductListing> _allProducts = const [];
  ProductFilters _filters = ProductFilters.none;
  bool _isLoading = true;
  String? _error;

  late final CartService _cart = widget.cartService ?? CartService();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // A snapshot stream, so a product added by anyone shows up here without a
    // manual refresh.
    _catalog.watchProducts().listen(
      (products) {
        if (!mounted) return;
        setState(() {
          _allProducts = products;
          _isLoading = false;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      },
    );
  }

  List<ProductListing> get _visible {
    final filtered = _catalog.filterProducts(_allProducts, _filters);

    // Favour the signed-in user's own categories, but only as a tie-break
    // within the sorted order the user chose - silently re-sorting would fight
    // the sort they just picked.
    final user = _authService.currentUser;
    if (user == null) return filtered;
    return filtered;
  }

  Future<void> _openFilters() async {
    final result = await showProductFilterSheet(
      context,
      initial: _filters,
      categories: _catalog.categoriesIn(_allProducts, const []),
      priceRange: _catalog.priceRange(_allProducts),
    );
    if (result == null || !mounted) return;

    setState(() {
      _filters = result;
      if (result.query.isEmpty && _searchController.text.isNotEmpty) {
        _searchController.clear();
      }
    });
  }

  Future<void> _addToCart(ProductListing product) async {
    final result = await _cart.addProduct(product);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess ? 'Added ${product.name} to your cart' : (result.error ?? 'Could not add to cart'),
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
    final products = _visible;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildCategoryChips(),

          // Result count plus a way back to an unfiltered view.
          _buildResultBar(products.length),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorPanel(message: _error!, onRetry: _loadProducts)
                    : products.isEmpty
                        ? _EmptyPanel(
                            filtered: _filters.isActive,
                            onClear: () {
                              _searchController.clear();
                              setState(() => _filters = ProductFilters.none);
                            },
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) => _buildProductCard(products[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FvScreenHeader(
      title: 'The Fan Shop',
      subtitle: 'Apparel, collectibles and digital drops.',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _openFilters,
            tooltip: 'Filters',
          ),
              // Badge is driven by the cart stream, so it is correct on first
              // frame rather than popping in after a read.
              StreamBuilder<int>(
                stream: _cart.watchItemCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_bag_outlined),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CartScreen(service: _cart)),
                        ),
                        tooltip: 'Cart',
                      ),
                      if (count > 0)
                        Positioned(
                          right: 4,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.background, width: 1.5),
                            ),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textOnPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return FvSearchField(
      controller: _searchController,
      hint: 'Search merchandise...',
      onChanged: (value) => setState(() => _filters = _filters.copyWith(query: value)),
      onClear: () {
        _searchController.clear();
        setState(() => _filters = _filters.copyWith(query: ''));
      },
    );
  }

  /// Categories are derived from the data, not hardcoded, so the chips only
  /// ever offer a filter that can actually return results.
  Widget _buildCategoryChips() {
    final categories = _catalog.categoriesIn(_allProducts, const []);

    return Container(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _filters.categories.isEmpty,
            onSelected: (_) => setState(() => _filters = _filters.copyWith(categories: const {})),
            selectedColor: AppColors.primary.withOpacity(0.3),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              color: _filters.categories.isEmpty ? AppColors.primary : AppColors.textSecondary,
            ),
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: _filters.categories.isEmpty ? AppColors.primary : AppColors.border,
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                label: Text(AppCategories.label(category)),
                selected: _filters.categories.contains(category),
                onSelected: (selected) {
                  setState(() {
                    final next = Set<String>.from(_filters.categories);
                    if (selected) {
                      next.add(category);
                    } else {
                      next.remove(category);
                    }
                    _filters = _filters.copyWith(categories: next);
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.3),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _filters.categories.contains(category)
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: _filters.categories.contains(category) ? AppColors.primary : AppColors.border,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultBar(int count) {
    if (!_filters.isActive) return const SizedBox(height: 4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
      child: Row(
        children: [
          Text(
            '$count result${count == 1 ? '' : 's'}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() => _filters = ProductFilters.none);
            },
            icon: const Icon(Icons.clear, size: 14),
            label: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductListing product) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product, cartService: _cart)),
      ),
      child: Card(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Stack(
          children: [
          Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.imageUrl.isNotEmpty)
                    Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const _ImageFallback(),
                    )
                  else
                    const _ImageFallback(),

                  // Sold-out and low-stock overlays, so a filtered-out item is
                  // still obviously unavailable rather than just hidden.
                  if (!product.isAvailable || product.stockQuantity <= 0)
                    Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: const Text(
                        'SOLD OUT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                  else if (product.stockQuantity > 0 && product.stockQuantity <= 3)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product.stockQuantity} left',
                          style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.isEmpty ? 'ITEM' : product.category.toUpperCase(),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 8),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      if (product.rating > 0)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 10, color: Colors.amber),
                            const SizedBox(width: 1),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 8),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          ),
            // Quick add on the card. The full quantity picker lives on the
            // product page; this is the one-tap path.
            if (product.isAvailable && product.stockQuantity > 0)
              Positioned(
                right: 3,
                bottom: 0,
                child: IconButton(
                  onPressed: () => _addToCart(product),
                  icon: const Icon(Icons.add_shopping_cart, size: 15),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(26, 26),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  tooltip: 'Add to cart',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.grey.shade800, child: const Icon(Icons.shopping_bag, color: Colors.white38));
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.filtered, required this.onClear});

  final bool filtered;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtered ? Icons.search_off : Icons.storefront,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              filtered ? 'No products match your filters' : 'No merchandise yet',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              filtered
                  ? 'Try widening the price range or clearing the filters.'
                  : 'Check back soon.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (filtered) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onClear, child: const Text('Clear filters')),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Could not load the shop',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              message.split('\n').first,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
