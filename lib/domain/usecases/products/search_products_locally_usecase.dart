import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../entities/products_result.dart';
import '../../repositories/products_repository.dart';

class SearchProductsLocallyUseCase {
  final ProductsRepository repository;

  SearchProductsLocallyUseCase(this.repository);

  Future<Either<Failure, ProductsResult>> call({required String query}) {
    return repository.searchProductsLocally(query: query);
  }
}
