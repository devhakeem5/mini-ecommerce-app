import '../../repositories/cart_repository.dart';

class RemoveFromCartUseCase {
  final CartRepository repository;

  RemoveFromCartUseCase(this.repository);

  Future<void> call(int productId) {
    return repository.removeFromCart(productId);
  }
}
