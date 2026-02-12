import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../entities/products_result.dart';
import '../../repositories/products_repository.dart';

class GetProductsByCategoryUseCase {
  final ProductsRepository repository;

  GetProductsByCategoryUseCase(this.repository);

  Stream<Either<Failure, ProductsResult>> call({
    required String category,
    required int limit,
    required int skip,
  }) {
    return repository.getProductsByCategory(category: category, limit: limit, skip: skip);
  }
}
