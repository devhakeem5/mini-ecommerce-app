import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/products_result.dart';
import '../../domain/repositories/products_repository.dart';
import '../datasources/local/products_local_data_source.dart';
import '../datasources/remote/products_remote_data_source.dart';
import '../models/product_model.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsRemoteDataSource remote;
  final ProductsLocalDataSource local;

  ProductsRepositoryImpl({required this.remote, required this.local});

  @override
  Stream<Either<Failure, ProductsResult>> getProducts({
    required int limit,
    required int skip,
    String? sortBy,
    String? order,
  }) async* {
    final cacheKey = _browseCacheKey(limit: limit, skip: skip, sortBy: sortBy, order: order);
    yield* _fetchProductsStream(
      limit: limit,
      skip: skip,
      cacheKey: cacheKey,
      sortBy: sortBy,
      order: order,
    );
  }

  @override
  Stream<Either<Failure, ProductsResult>> getProductsByCategory({
    required String category,
    required int limit,
    required int skip,
  }) async* {
    final cacheKey = _categoryCacheKey(category: category, limit: limit, skip: skip);
    yield* _fetchProductsStream(limit: limit, skip: skip, cacheKey: cacheKey, category: category);
  }

  @override
  Stream<Either<Failure, ProductsResult>> searchProducts({
    required String query,
    required int limit,
    required int skip,
  }) async* {
    final cacheKey = 'search_${query}_skip_${skip}_limit_$limit';
    yield* _fetchProductsStream(limit: limit, skip: skip, cacheKey: cacheKey, query: query);
  }

  Stream<Either<Failure, ProductsResult>> _fetchProductsStream({
    required int limit,
    required int skip,
    required String cacheKey,
    String? category,
    String? query,
    String? sortBy,
    String? order,
  }) async* {
    try {
      final cached = await local.getCachedProducts(cacheKey: cacheKey);
      if (cached != null) {
        final products = cached.map((e) => ProductModel.fromJson(e).toEntity()).toList();
        yield Right(ProductsResult(products: products, isOffline: true));
      }
    } catch (e) {
      debugPrint('Cache Read Error: $e');
    }

    try {
      final List<ProductModel> remoteProducts;
      if (category != null) {
        remoteProducts = await remote.getProductsByCategory(
          category: category,
          limit: limit,
          skip: skip,
        );
      } else if (query != null) {
        remoteProducts = await remote.searchProducts(query: query, limit: limit, skip: skip);
      } else {
        remoteProducts = await remote.getProducts(
          limit: limit,
          skip: skip,
          sortBy: sortBy,
          order: order,
        );
      }

      await local.cacheProducts(
        cacheKey: cacheKey,
        products: remoteProducts.map(_modelToMap).toList(),
      );

      yield Right(
        ProductsResult(
          products: remoteProducts.map((e) => e.toEntity()).toList(),
          isOffline: false,
        ),
      );
    } catch (e) {
      debugPrint('ProductsRepositoryImpl Error: $e');

      if (query != null) {
        try {
          final localResults = await local.searchLocalProducts(query);
          if (localResults.isNotEmpty) {
            await local.cacheProducts(cacheKey: cacheKey, products: localResults);
            final products = localResults.map((e) => ProductModel.fromJson(e).toEntity()).toList();
            yield Right(ProductsResult(products: products, isOffline: true));
            return;
          }
        } catch (le) {
          debugPrint('Local Fallback Search Error: $le');
        }
      }

      yield const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, ProductsResult>> searchProductsLocally({required String query}) async {
    try {
      final localResults = await local.searchLocalProducts(query);
      final products = localResults.map((e) => ProductModel.fromJson(e).toEntity()).toList();
      return Right(ProductsResult(products: products, isOffline: true));
    } catch (e) {
      debugPrint('Local Search Error: $e');
      return Right(const ProductsResult(products: [], isOffline: true));
    }
  }

  Map<String, dynamic> _modelToMap(ProductModel model) {
    return {
      'id': model.id,
      'title': model.title,
      'description': model.description,
      'brand': model.brand,
      'category': model.category,
      'price': model.price,
      'discountPercentage': model.discountPercentage,
      'rating': model.rating,
      'thumbnail': model.thumbnail,
      'images': model.images,
      'availabilityStatus': model.availabilityStatus,
    };
  }

  String _browseCacheKey({required int limit, required int skip, String? sortBy, String? order}) =>
      'products_skip_${skip}_limit_${limit}_sort_${sortBy ?? 'none'}_order_${order ?? 'none'}';

  String _categoryCacheKey({required String category, required int limit, required int skip}) =>
      'category_${category}_skip_${skip}_limit_$limit';
}
