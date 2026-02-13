import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../entities/cart_item.dart';
import '../../repositories/cart_repository.dart';

class LoadCartUseCase {
  final CartRepository repository;

  LoadCartUseCase(this.repository);

  Future<Either<Failure, List<CartItem>>> call() {
    return repository.loadCart();
  }
}
