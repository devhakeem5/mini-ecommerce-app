import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' hide Category;

import '../../core/error/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local/products_local_data_source.dart';
import '../datasources/remote/products_remote_data_source.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final ProductsRemoteDataSource remote;
  final ProductsLocalDataSource local;

  CategoryRepositoryImpl({required this.remote, required this.local});

  @override
  Stream<Either<Failure, List<Category>>> getCategories() async* {
    try {
      final cached = await local.getCachedCategories();
      if (cached != null && cached.isNotEmpty) {
        yield Right(cached.map((e) => Category.fromString(e)).toList());
      }
    } catch (e) {
      debugPrint('Category Cache Error: $e');
    }

    try {
      final categories = await remote.getCategories();
      await local.cacheCategories(categories);
      yield Right(categories.map((e) => Category.fromString(e)).toList());
    } catch (e) {
      debugPrint('Category Remote Error: $e');
      yield const Left(ServerFailure('categories_load_failed'));
    }
  }
}
