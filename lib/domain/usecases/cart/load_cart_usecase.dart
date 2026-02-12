import '../../entities/cart_item.dart';
import '../../repositories/cart_repository.dart';

class LoadCartUseCase {
  final CartRepository repository;

  LoadCartUseCase(this.repository);

  Future<List<CartItem>> call() {
    return repository.loadCart();
  }
}
