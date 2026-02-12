import '../../entities/product.dart';
import '../../repositories/cart_repository.dart';

class AddToCartUseCase {
  final CartRepository repository;

  AddToCartUseCase(this.repository);

  Future<void> call(Product product) {
    return repository.addToCart(product);
  }
}
