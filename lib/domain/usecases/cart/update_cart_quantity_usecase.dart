import '../../repositories/cart_repository.dart';

class UpdateCartQuantityUseCase {
  final CartRepository repository;

  UpdateCartQuantityUseCase(this.repository);

  Future<void> call({required int productId, required int quantity}) {
    return repository.updateQuantity(productId: productId, quantity: quantity);
  }
}
