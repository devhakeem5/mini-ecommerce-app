import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../repositories/cart_repository.dart';

class UpdateCartQuantityUseCase {
  final CartRepository repository;

  UpdateCartQuantityUseCase(this.repository);

  Future<Either<Failure, void>> call({required int productId, required int quantity}) {
    return repository.updateQuantity(productId: productId, quantity: quantity);
  }
}
