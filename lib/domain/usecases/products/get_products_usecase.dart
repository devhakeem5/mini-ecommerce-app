import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../entities/products_result.dart';
import '../../repositories/products_repository.dart';

class GetProductsUseCase {
  final ProductsRepository repository;

  GetProductsUseCase(this.repository);

  Stream<Either<Failure, ProductsResult>> call({
    required int limit,
    required int skip,
    String? sortBy,
    String? order,
  }) {
    return repository.getProducts(limit: limit, skip: skip, sortBy: sortBy, order: order);
  }
}
