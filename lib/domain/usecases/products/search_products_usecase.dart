import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../entities/products_result.dart';
import '../../repositories/products_repository.dart';

class SearchProductsUseCase {
  final ProductsRepository repository;

  SearchProductsUseCase(this.repository);

  Stream<Either<Failure, ProductsResult>> call({
    required String query,
    required int limit,
    required int skip,
  }) {
    return repository.searchProducts(query: query, limit: limit, skip: skip);
  }
}
