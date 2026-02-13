import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/core/error/failures.dart';
import 'package:mini_commerce_app/data/datasources/local/products_local_data_source.dart';
import 'package:mini_commerce_app/data/datasources/remote/products_remote_data_source.dart';
import 'package:mini_commerce_app/data/models/product_model.dart';
import 'package:mini_commerce_app/data/repositories/products_repository_impl.dart';
import 'package:mini_commerce_app/domain/entities/products_result.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsRemoteDataSource extends Mock implements ProductsRemoteDataSource {}

class MockProductsLocalDataSource extends Mock implements ProductsLocalDataSource {}

void main() {
  late ProductsRepositoryImpl repository;
  late MockProductsRemoteDataSource mockRemote;
  late MockProductsLocalDataSource mockLocal;

  setUp(() {
    mockRemote = MockProductsRemoteDataSource();
    mockLocal = MockProductsLocalDataSource();
    repository = ProductsRepositoryImpl(remote: mockRemote, local: mockLocal);
  });

  const tProductModel = ProductModel(
    id: 1,
    title: 'Test',
    description: 'Desc',
    brand: 'Brand',
    category: 'Cat',
    price: 100.0,
    discountPercentage: 10.0,
    rating: 4.5,
    thumbnail: 'url',
    images: [],
    availabilityStatus: 'In Stock',
  );

  final tProductJson = {
    'id': 1,
    'title': 'Test',
    'description': 'Desc',
    'brand': 'Brand',
    'category': 'Cat',
    'price': 100.0,
    'discountPercentage': 10.0,
    'rating': 4.5,
    'thumbnail': 'url',
    'images': <String>[],
    'availabilityStatus': 'In Stock',
  };

  group('getProducts', () {
    test('yields cached data then remote data when both available', () async {
      when(
        () => mockLocal.getCachedProducts(cacheKey: any(named: 'cacheKey')),
      ).thenAnswer((_) async => [tProductJson]);
      when(
        () => mockRemote.getProducts(limit: 20, skip: 0, sortBy: null, order: null),
      ).thenAnswer((_) async => [tProductModel]);
      when(
        () => mockLocal.cacheProducts(
          cacheKey: any(named: 'cacheKey'),
          products: any(named: 'products'),
        ),
      ).thenAnswer((_) async {});

      final results = <Either<Failure, ProductsResult>>[];
      await for (final result in repository.getProducts(limit: 20, skip: 0)) {
        results.add(result);
      }

      expect(results.length, 2);
      expect(results[0].isRight(), true);
      results[0].fold((_) {}, (r) => expect(r.isOffline, true));
      expect(results[1].isRight(), true);
      results[1].fold((_) {}, (r) => expect(r.isOffline, false));
    });

    test('yields only remote data when cache is empty', () async {
      when(
        () => mockLocal.getCachedProducts(cacheKey: any(named: 'cacheKey')),
      ).thenAnswer((_) async => null);
      when(
        () => mockRemote.getProducts(limit: 20, skip: 0, sortBy: null, order: null),
      ).thenAnswer((_) async => [tProductModel]);
      when(
        () => mockLocal.cacheProducts(
          cacheKey: any(named: 'cacheKey'),
          products: any(named: 'products'),
        ),
      ).thenAnswer((_) async {});

      final results = <Either<Failure, ProductsResult>>[];
      await for (final result in repository.getProducts(limit: 20, skip: 0)) {
        results.add(result);
      }

      expect(results.length, 1);
      results[0].fold((_) {}, (r) {
        expect(r.isOffline, false);
        expect(r.products.length, 1);
      });
    });

    test('yields NetworkFailure when no cache and remote fails', () async {
      when(
        () => mockLocal.getCachedProducts(cacheKey: any(named: 'cacheKey')),
      ).thenAnswer((_) async => null);
      when(
        () => mockRemote.getProducts(limit: 20, skip: 0, sortBy: null, order: null),
      ).thenThrow(Exception('No internet'));

      final results = <Either<Failure, ProductsResult>>[];
      await for (final result in repository.getProducts(limit: 20, skip: 0)) {
        results.add(result);
      }

      expect(results.length, 1);
      expect(results[0].isLeft(), true);
      results[0].fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail('Expected Left'));
    });

    test('yields cached data + NetworkFailure when cache exists but remote fails', () async {
      when(
        () => mockLocal.getCachedProducts(cacheKey: any(named: 'cacheKey')),
      ).thenAnswer((_) async => [tProductJson]);
      when(
        () => mockRemote.getProducts(limit: 20, skip: 0, sortBy: null, order: null),
      ).thenThrow(Exception('No internet'));

      final results = <Either<Failure, ProductsResult>>[];
      await for (final result in repository.getProducts(limit: 20, skip: 0)) {
        results.add(result);
      }

      expect(results.length, 2);
      expect(results[0].isRight(), true);
      results[0].fold((_) {}, (r) => expect(r.isOffline, true));
      expect(results[1].isLeft(), true);
    });
  });

  group('searchProducts', () {
    test('yields cached + remote for search', () async {
      when(
        () => mockLocal.getCachedProducts(cacheKey: any(named: 'cacheKey')),
      ).thenAnswer((_) async => [tProductJson]);
      when(
        () => mockRemote.searchProducts(query: 'test', limit: 20, skip: 0),
      ).thenAnswer((_) async => [tProductModel]);
      when(
        () => mockLocal.cacheProducts(
          cacheKey: any(named: 'cacheKey'),
          products: any(named: 'products'),
        ),
      ).thenAnswer((_) async {});

      final results = <Either<Failure, ProductsResult>>[];
      await for (final result in repository.searchProducts(query: 'test', limit: 20, skip: 0)) {
        results.add(result);
      }

      expect(results.length, 2);
    });

    test('falls back to local search when remote fails', () async {
      when(
        () => mockLocal.getCachedProducts(cacheKey: any(named: 'cacheKey')),
      ).thenAnswer((_) async => null);
      when(
        () => mockRemote.searchProducts(query: 'test', limit: 20, skip: 0),
      ).thenThrow(Exception('Network error'));
      when(() => mockLocal.searchLocalProducts('test')).thenAnswer((_) async => [tProductJson]);
      when(
        () => mockLocal.cacheProducts(
          cacheKey: any(named: 'cacheKey'),
          products: any(named: 'products'),
        ),
      ).thenAnswer((_) async {});

      final results = <Either<Failure, ProductsResult>>[];
      await for (final result in repository.searchProducts(query: 'test', limit: 20, skip: 0)) {
        results.add(result);
      }

      expect(results.length, 1);
      expect(results[0].isRight(), true);
      results[0].fold((_) {}, (r) => expect(r.isOffline, true));
    });
  });

  group('getProductsByCategory', () {
    test('delegates with category cache key', () async {
      when(
        () => mockLocal.getCachedProducts(cacheKey: any(named: 'cacheKey')),
      ).thenAnswer((_) async => null);
      when(
        () => mockRemote.getProductsByCategory(category: 'electronics', limit: 20, skip: 0),
      ).thenAnswer((_) async => [tProductModel]);
      when(
        () => mockLocal.cacheProducts(
          cacheKey: any(named: 'cacheKey'),
          products: any(named: 'products'),
        ),
      ).thenAnswer((_) async {});

      final results = <Either<Failure, ProductsResult>>[];
      await for (final result in repository.getProductsByCategory(
        category: 'electronics',
        limit: 20,
        skip: 0,
      )) {
        results.add(result);
      }

      expect(results.length, 1);
      results[0].fold((_) {}, (r) {
        expect(r.products.length, 1);
        expect(r.isOffline, false);
      });
    });
  });

  group('searchProductsLocally', () {
    test('returns local results', () async {
      when(() => mockLocal.searchLocalProducts('apple')).thenAnswer((_) async => [tProductJson]);

      final result = await repository.searchProductsLocally(query: 'apple');

      result.fold((_) => fail('Expected Right'), (r) {
        expect(r.products.length, 1);
        expect(r.isOffline, true);
      });
    });

    test('returns empty list on error', () async {
      when(() => mockLocal.searchLocalProducts('fail')).thenThrow(Exception('DB error'));

      final result = await repository.searchProductsLocally(query: 'fail');

      result.fold((_) => fail('Expected Right'), (r) {
        expect(r.products, isEmpty);
        expect(r.isOffline, true);
      });
    });
  });
}
