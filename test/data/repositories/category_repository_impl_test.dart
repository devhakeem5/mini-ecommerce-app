import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/core/error/failures.dart';
import 'package:mini_commerce_app/data/datasources/local/products_local_data_source.dart';
import 'package:mini_commerce_app/data/datasources/remote/products_remote_data_source.dart';
import 'package:mini_commerce_app/data/repositories/category_repository_impl.dart';
import 'package:mini_commerce_app/domain/entities/category.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsRemoteDataSource extends Mock implements ProductsRemoteDataSource {}

class MockProductsLocalDataSource extends Mock implements ProductsLocalDataSource {}

void main() {
  late CategoryRepositoryImpl repository;
  late MockProductsRemoteDataSource mockRemote;
  late MockProductsLocalDataSource mockLocal;

  setUp(() {
    mockRemote = MockProductsRemoteDataSource();
    mockLocal = MockProductsLocalDataSource();
    repository = CategoryRepositoryImpl(remote: mockRemote, local: mockLocal);
  });

  group('getCategories', () {
    test('yields cached then remote categories', () async {
      when(
        () => mockLocal.getCachedCategories(),
      ).thenAnswer((_) async => ['electronics', 'clothing']);
      when(
        () => mockRemote.getCategories(),
      ).thenAnswer((_) async => ['electronics', 'clothing', 'food']);
      when(() => mockLocal.cacheCategories(any())).thenAnswer((_) async {});

      final results = <Either<Failure, List<Category>>>[];
      await for (final result in repository.getCategories()) {
        results.add(result);
      }

      expect(results.length, 2);
      results[0].fold((_) {}, (cats) {
        expect(cats.length, 2);
        expect(cats[0].name, 'Electronics');
      });
      results[1].fold((_) {}, (cats) {
        expect(cats.length, 3);
      });
    });

    test('yields only remote when no cache', () async {
      when(() => mockLocal.getCachedCategories()).thenAnswer((_) async => null);
      when(() => mockRemote.getCategories()).thenAnswer((_) async => ['beauty']);
      when(() => mockLocal.cacheCategories(any())).thenAnswer((_) async {});

      final results = <Either<Failure, List<Category>>>[];
      await for (final result in repository.getCategories()) {
        results.add(result);
      }

      expect(results.length, 1);
      results[0].fold((_) {}, (cats) => expect(cats[0].slug, 'beauty'));
    });

    test('yields ServerFailure when remote fails', () async {
      when(() => mockLocal.getCachedCategories()).thenAnswer((_) async => null);
      when(() => mockRemote.getCategories()).thenThrow(Exception('Server down'));

      final results = <Either<Failure, List<Category>>>[];
      await for (final result in repository.getCategories()) {
        results.add(result);
      }

      expect(results.length, 1);
      expect(results[0].isLeft(), true);
      results[0].fold((f) => expect(f, isA<ServerFailure>()), (_) => fail('Expected Left'));
    });

    test('yields cache + ServerFailure when cache exists but remote fails', () async {
      when(() => mockLocal.getCachedCategories()).thenAnswer((_) async => ['cached']);
      when(() => mockRemote.getCategories()).thenThrow(Exception('Timeout'));

      final results = <Either<Failure, List<Category>>>[];
      await for (final result in repository.getCategories()) {
        results.add(result);
      }

      expect(results.length, 2);
      expect(results[0].isRight(), true);
      expect(results[1].isLeft(), true);
    });
  });
}
