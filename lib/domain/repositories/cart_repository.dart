import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/cart_item.dart';
import '../entities/product.dart';

abstract class CartRepository {
  Future<Either<Failure, List<CartItem>>> loadCart();

  Future<Either<Failure, void>> addToCart(Product product);

  Future<Either<Failure, void>> updateQuantity({required int productId, required int quantity});

  Future<Either<Failure, void>> removeFromCart(int productId);

  Future<Either<Failure, void>> clearCart();

  Future<Either<Failure, void>> updateProductPrices(List<Product> products);
}
