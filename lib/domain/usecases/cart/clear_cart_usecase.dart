import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../repositories/cart_repository.dart';

class ClearCartUseCase {
  final CartRepository repository;

  ClearCartUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.clearCart();
  }
}
