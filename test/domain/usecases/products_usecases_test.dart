import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/core/error/failures.dart';
import 'package:mini_commerce_app/domain/entities/category.dart';
import 'package:mini_commerce_app/domain/entities/products_result.dart';
import 'package:mini_commerce_app/domain/repositories/category_repository.dart';
import 'package:mini_commerce_app/domain/repositories/products_repository.dart';
import 'package:mini_commerce_app/domain/usecases/products/get_categories_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/products/get_products_by_category_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/products/search_products_locally_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/products/search_products_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockProductsRepository mockProductsRepo;
  late MockCategoryRepository mockCategoryRepo;

  setUp(() {
    mockProductsRepo = MockProductsRepository();
    mockCategoryRepo = MockCategoryRepository();
  });

  final tProductsResult = ProductsResult(products: [], isOffline: false);

  group('SearchProductsUseCase', () {
    late SearchProductsUseCase useCase;

    setUp(() {
      useCase = SearchProductsUseCase(mockProductsRepo);
    });

    test('delegates to repository.searchProducts', () {
      when(
        () => mockProductsRepo.searchProducts(query: 'test', limit: 20, skip: 0),
      ).thenAnswer((_) => Stream.value(Right(tProductsResult)));

      final stream = useCase(query: 'test', limit: 20, skip: 0);

      expect(stream, emits(Right(tProductsResult)));
      verify(() => mockProductsRepo.searchProducts(query: 'test', limit: 20, skip: 0)).called(1);
    });

    test('emits failure when repository fails', () {
      const tFailure = ServerFailure('Error');
      when(
        () => mockProductsRepo.searchProducts(query: 'test', limit: 20, skip: 0),
      ).thenAnswer((_) => Stream.value(const Left(tFailure)));

      final stream = useCase(query: 'test', limit: 20, skip: 0);

      expect(stream, emits(const Left(tFailure)));
    });
  });

  group('GetProductsByCategoryUseCase', () {
    late GetProductsByCategoryUseCase useCase;

    setUp(() {
      useCase = GetProductsByCategoryUseCase(mockProductsRepo);
    });

    test('delegates to repository.getProductsByCategory', () {
      when(
        () => mockProductsRepo.getProductsByCategory(category: 'electronics', limit: 20, skip: 0),
      ).thenAnswer((_) => Stream.value(Right(tProductsResult)));

      final stream = useCase(category: 'electronics', limit: 20, skip: 0);

      expect(stream, emits(Right(tProductsResult)));
      verify(
        () => mockProductsRepo.getProductsByCategory(category: 'electronics', limit: 20, skip: 0),
      ).called(1);
    });
  });

  group('SearchProductsLocallyUseCase', () {
    late SearchProductsLocallyUseCase useCase;

    setUp(() {
      useCase = SearchProductsLocallyUseCase(mockProductsRepo);
    });

    test('delegates to repository.searchProductsLocally', () async {
      when(
        () => mockProductsRepo.searchProductsLocally(query: 'test'),
      ).thenAnswer((_) async => Right(tProductsResult));

      final result = await useCase(query: 'test');

      expect(result, Right(tProductsResult));
      verify(() => mockProductsRepo.searchProductsLocally(query: 'test')).called(1);
    });

    test('returns failure when repository fails', () async {
      const tFailure = NetworkFailure('Offline');
      when(
        () => mockProductsRepo.searchProductsLocally(query: 'test'),
      ).thenAnswer((_) async => const Left(tFailure));

      final result = await useCase(query: 'test');

      expect(result, const Left(tFailure));
    });
  });

  group('GetCategoriesUseCase', () {
    late GetCategoriesUseCase useCase;

    setUp(() {
      useCase = GetCategoriesUseCase(mockCategoryRepo);
    });

    test('delegates to repository.getCategories', () {
      final tCategories = [const Category(id: '1', name: 'Electronics', slug: 'electronics')];
      when(
        () => mockCategoryRepo.getCategories(),
      ).thenAnswer((_) => Stream.value(Right(tCategories)));

      final stream = useCase();

      expect(stream, emits(Right(tCategories)));
      verify(() => mockCategoryRepo.getCategories()).called(1);
    });

    test('emits failure when repository fails', () {
      when(
        () => mockCategoryRepo.getCategories(),
      ).thenAnswer((_) => Stream.value(const Left(ServerFailure('Error'))));

      final stream = useCase();

      expect(stream, emits(isA<Left>()));
    });
  });
}
