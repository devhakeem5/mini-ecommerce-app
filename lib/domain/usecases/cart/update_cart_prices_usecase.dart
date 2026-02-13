import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../entities/product.dart';
import '../../repositories/cart_repository.dart';

class UpdateCartPricesUseCase {
  final CartRepository repository;

  UpdateCartPricesUseCase(this.repository);

  Future<Either<Failure, void>> call(List<Product> products) {
    return repository.updateProductPrices(products);
  }
}
