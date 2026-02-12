import '../entities/cart_item.dart';
import '../entities/product.dart';

abstract class CartRepository {
  Future<List<CartItem>> loadCart();

  Future<void> addToCart(Product product);

  Future<void> updateQuantity({required int productId, required int quantity});

  Future<void> removeFromCart(int productId);

  Future<void> clearCart();

  Future<void> updateProductPrices(List<Product> products);
}
