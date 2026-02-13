import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../entities/product.dart';
import '../../repositories/cart_repository.dart';

class AddToCartUseCase {
  final CartRepository repository;

  AddToCartUseCase(this.repository);

  Future<Either<Failure, void>> call(Product product) {
    return repository.addToCart(product);
  }
}
