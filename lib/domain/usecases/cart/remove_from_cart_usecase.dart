import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../repositories/cart_repository.dart';

class RemoveFromCartUseCase {
  final CartRepository repository;

  RemoveFromCartUseCase(this.repository);

  Future<Either<Failure, void>> call(int productId) {
    return repository.removeFromCart(productId);
  }
}
