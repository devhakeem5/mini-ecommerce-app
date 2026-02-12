import '../../entities/product.dart';
import '../../repositories/cart_repository.dart';

class UpdateCartPricesUseCase {
  final CartRepository repository;

  UpdateCartPricesUseCase(this.repository);

  Future<void> call(List<Product> products) {
    return repository.updateProductPrices(products);
  }
}
