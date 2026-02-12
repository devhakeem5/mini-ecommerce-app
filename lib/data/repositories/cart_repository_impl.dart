import 'dart:async';

import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/local/cart_local_data_source.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartRepositoryImpl implements CartRepository {
  final CartLocalDataSource localDataSource;

  Future<void> _processingQueue = Future.value();

  CartRepositoryImpl({required this.localDataSource});

  Future<T> _enqueue<T>(Future<T> Function() task) {
    final completer = Completer<T>();

    _processingQueue = _processingQueue
        .then((_) {
          return task()
              .then((result) {
                completer.complete(result);
              })
              .catchError((e) {
                completer.completeError(e);
              });
        })
        .catchError((_) {});

    return completer.future;
  }

  @override
  Future<List<CartItem>> loadCart() async {
    final rawItems = await localDataSource.loadCart();

    return rawItems.map((map) {
      final productModel = ProductModel.fromJson(Map<String, dynamic>.from(map['product']));
      final quantity = map['quantity'] as int;

      return CartItemModel(product: productModel, quantity: quantity).toEntity();
    }).toList();
  }

  @override
  Future<void> addToCart(Product product) {
    return _enqueue(() async {
      final items = await _loadModels();

      final index = items.indexWhere((e) => e.product.id == product.id);

      if (index >= 0) {
        final existing = items[index];
        items[index] = existing.copyWith(quantity: existing.quantity + 1);
      } else {
        items.add(
          CartItemModel(
            product: ProductModel(
              id: product.id,
              title: product.title,
              description: product.description,
              brand: product.brand,
              category: product.category,
              price: product.price,
              discountPercentage: product.discountPercentage,
              rating: product.rating,
              thumbnail: product.thumbnail,
              images: product.images,
              availabilityStatus: product.availabilityStatus,
            ),
            quantity: 1,
          ),
        );
      }

      await _saveModels(items);
    });
  }

  @override
  Future<void> updateQuantity({required int productId, required int quantity}) {
    return _enqueue(() async {
      if (quantity < 1) return;

      final items = await _loadModels();
      final index = items.indexWhere((e) => e.product.id == productId);

      if (index == -1) return;

      items[index] = items[index].copyWith(quantity: quantity);
      await _saveModels(items);
    });
  }

  @override
  Future<void> removeFromCart(int productId) {
    return _enqueue(() async {
      final items = await _loadModels();
      items.removeWhere((e) => e.product.id == productId);
      await _saveModels(items);
    });
  }

  @override
  Future<void> clearCart() {
    return _enqueue(() async {
      await localDataSource.clearCart();
    });
  }

  Future<List<CartItemModel>> _loadModels() async {
    final rawItems = await localDataSource.loadCart();

    return rawItems.map((map) {
      return CartItemModel(
        product: ProductModel.fromJson(Map<String, dynamic>.from(map['product'])),
        quantity: map['quantity'] as int,
      );
    }).toList();
  }

  Future<void> _saveModels(List<CartItemModel> items) async {
    final maps = items.map((item) {
      return {
        'product': {
          'id': item.product.id,
          'title': item.product.title,
          'description': item.product.description,
          'brand': item.product.brand,
          'category': item.product.category,
          'price': item.product.price,
          'discountPercentage': item.product.discountPercentage,
          'rating': item.product.rating,
          'thumbnail': item.product.thumbnail,
          'images': item.product.images,
          'availabilityStatus': item.product.availabilityStatus,
        },
        'quantity': item.quantity,
      };
    }).toList();

    await localDataSource.saveCart(maps);
  }

  @override
  Future<void> updateProductPrices(List<Product> products) {
    return _enqueue(() async {
      final items = await _loadModels();
      if (items.isEmpty) return;

      final productMap = <int, Product>{for (final p in products) p.id: p};
      bool hasChanges = false;

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final freshProduct = productMap[item.product.id];

        if (freshProduct != null && freshProduct.price != item.product.price) {
          items[i] = item.copyWith(
            product: ProductModel(
              id: freshProduct.id,
              title: freshProduct.title,
              description: freshProduct.description,
              brand: freshProduct.brand,
              category: freshProduct.category,
              price: freshProduct.price,
              discountPercentage: freshProduct.discountPercentage,
              rating: freshProduct.rating,
              thumbnail: freshProduct.thumbnail,
              images: freshProduct.images,
              availabilityStatus: freshProduct.availabilityStatus,
            ),
          );
          hasChanges = true;
        }
      }

      if (hasChanges) {
        await _saveModels(items);
      }
    });
  }
}
