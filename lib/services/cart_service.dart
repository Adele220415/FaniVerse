import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/result.dart';
import '../models/user_listing.dart';

/// One line in the cart.
///
/// The product's name, price and image are copied onto the cart item rather
/// than looked up, so a cart renders without one read per line - and still
/// renders if a product is deleted afterwards. This mirrors the shape the
/// seed data already writes to `cart_items`.
class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl = '',
    this.quantity = 1,
    this.brand = '',
    this.addedAt,
  });

  final String id;
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  final String brand;
  final DateTime? addedAt;

  double get lineTotal => price * quantity;

  factory CartItem.fromFirestore(String id, Map<String, dynamic> data) {
    return CartItem(
      id: id,
      productId: data['productId']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Product',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      imageUrl: data['imageUrl']?.toString() ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      brand: data['brand']?.toString() ?? '',
      addedAt: _toDate(data['addedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'imageUrl': imageUrl,
        'price': price,
        'quantity': quantity,
        'brand': brand,
        'addedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

/// A user's cart, persisted to Firestore.
///
/// Stored in `users/{uid}/cart_items` so it follows the account across
/// devices, matching the subcollection the seed data already populates and the
/// rules already permit.
class CartService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CartService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? get _items {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('cart_items');
  }

  /// The whole cart, live. Signed out emits empty rather than erroring, so the
  /// badge can be built before auth resolves.
  Stream<List<CartItem>> watchCart() {
    final items = _items;
    if (items == null) return Stream.value(const []);

    return items.snapshots().map((snapshot) {
      final list = snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => CartItem.fromFirestore(doc.id, doc.data()))
          .toList();
      // Newest first, with missing timestamps last so they do not lead.
      list.sort((a, b) {
        final at = a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    });
  }

  /// Item count for the header badge, counting quantities so it matches what a
  /// shopper expects rather than the number of distinct lines.
  Stream<int> watchItemCount() {
    return watchCart().map((items) => items.fold<int>(0, (sum, i) => sum + i.quantity));
  }

  Stream<double> watchTotal() {
    return watchCart().map((items) => items.fold<double>(0, (sum, i) => sum + i.lineTotal));
  }

  /// Add [product] to the cart, or bump its quantity if already present.
  ///
  /// The document id is derived from the product id, which is what makes the
  /// add idempotent - tapping "add" twice cannot create two lines for one
  /// product.
  Future<Result<void>> addProduct(ProductListing product, {int quantity = 1}) async {
    final items = _items;
    if (items == null) {
      return Result.error('You must be logged in to use the cart');
    }

    try {
      final docRef = items.doc(product.id);
      final existing = await docRef.get();

      if (existing.exists) {
        final current = (existing.data()?['quantity'] as num?)?.toInt() ?? 0;
        await docRef.update({
          'quantity': current + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.set(CartItem(
          id: product.id,
          productId: product.id,
          name: product.name,
          price: product.price,
          imageUrl: product.imageUrl,
          brand: product.brand,
          quantity: quantity,
        ).toJson());
      }
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not add to the cart: $e');
    }
  }

  /// Set an absolute quantity. A request for 0 or less removes the line, which
  /// keeps the caller from having to special-case "minus to zero".
  Future<Result<void>> setQuantity(String itemId, int quantity) async {
    final items = _items;
    if (items == null) {
      return Result.error('You must be logged in to use the cart');
    }

    try {
      if (quantity <= 0) {
        await items.doc(itemId).delete();
        return Result.success(null);
      }
      await items.doc(itemId).update({
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not update the quantity: $e');
    }
  }

  Future<Result<void>> remove(String itemId) async {
    final items = _items;
    if (items == null) {
      return Result.error('You must be logged in to use the cart');
    }

    try {
      await items.doc(itemId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not remove the item: $e');
    }
  }

  Future<Result<void>> clear() async {
    final items = _items;
    if (items == null) {
      return Result.error('You must be logged in to use the cart');
    }

    try {
      // A batch rather than a recursive delete: a user with many lines would
      // otherwise need a chain of deletes.
      final snapshot = await items.get();
      if (snapshot.docs.isEmpty) return Result.success(null);

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not empty the cart: $e');
    }
  }
}
