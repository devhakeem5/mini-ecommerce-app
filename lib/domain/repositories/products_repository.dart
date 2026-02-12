import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/products_result.dart';

abstract class ProductsRepository {
  Stream<Either<Failure, ProductsResult>> getProducts({
    required int limit,
    required int skip,
    String? sortBy,
    String? order,
  });

  Stream<Either<Failure, ProductsResult>> getProductsByCategory({
    required String category,
    required int limit,
    required int skip,
  });

  Stream<Either<Failure, ProductsResult>> searchProducts({
    required String query,
    required int limit,
    required int skip,
  });

  Future<Either<Failure, ProductsResult>> searchProductsLocally({required String query});
}
