import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/core/error/failures.dart';
import 'package:mini_commerce_app/domain/entities/product.dart';
import 'package:mini_commerce_app/domain/entities/products_result.dart';
import 'package:mini_commerce_app/domain/usecases/products/get_products_usecase.dart';
import 'package:mini_commerce_app/presentation/products/cubit/products_cubit.dart';
import 'package:mini_commerce_app/presentation/products/cubit/products_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetProductsUseCase extends Mock implements GetProductsUseCase {}

void main() {
  late ProductsCubit productsCubit;
  late MockGetProductsUseCase mockGetProductsUseCase;

  setUp(() {
    mockGetProductsUseCase = MockGetProductsUseCase();
    productsCubit = ProductsCubit(getProductsUseCase: mockGetProductsUseCase);
  });

  tearDown(() {
    productsCubit.close();
  });

  const tProduct = Product(
    id: 1,
    title: 'Test Product',
    description: 'Desc',
    brand: 'Brand',
    category: 'Category',
    price: 100.0,
    discountPercentage: 0.0,
    rating: 4.5,
    thumbnail: 'url',
    images: [],
    availabilityStatus: 'In Stock',
  );

  final tProductsResult = ProductsResult(products: [tProduct], isOffline: false);

  group('ProductsCubit', () {
    test('initial state is ProductsInitial', () {
      expect(productsCubit.state, const ProductsInitial());
    });

    blocTest<ProductsCubit, ProductsState>(
      'emits [ProductsLoading, ProductsLoaded] when loadInitialProducts is successful',
      build: () {
        when(
          () => mockGetProductsUseCase(limit: 20, skip: 0),
        ).thenAnswer((_) => Stream.value(Right(tProductsResult)));
        return productsCubit;
      },
      act: (cubit) => cubit.loadInitialProducts(),
      expect: () => [
        const ProductsLoading(),
        ProductsLoaded(products: [tProduct], isOffline: false, hasReachedMax: true),
      ],
      verify: (_) {
        verify(() => mockGetProductsUseCase(limit: 20, skip: 0)).called(1);
      },
    );

    blocTest<ProductsCubit, ProductsState>(
      'emits [ProductsLoading, ProductsError] when loadInitialProducts fails',
      build: () {
        when(
          () => mockGetProductsUseCase(limit: 20, skip: 0),
        ).thenAnswer((_) => Stream.value(const Left(ServerFailure('Error'))));
        return productsCubit;
      },
      act: (cubit) => cubit.loadInitialProducts(),
      expect: () => [const ProductsLoading(), const ProductsError(message: 'Error')],
    );

    blocTest<ProductsCubit, ProductsState>(
      'loadMoreProducts appends new products to existing list',
      build: () {
        const tProduct2 = Product(
          id: 20,
          title: 'Product 2',
          description: 'Desc',
          brand: 'Brand',
          category: 'Category',
          price: 200.0,
          discountPercentage: 0.0,
          rating: 3.0,
          thumbnail: 'url2',
          images: [],
          availabilityStatus: 'In Stock',
        );
        // Create a full page of 20 products with distinct IDs (0-19)
        final initialProducts = List.generate(
          20,
          (i) => Product(
            id: i,
            title: 'P$i',
            description: '',
            brand: '',
            category: '',
            price: 10.0,
            discountPercentage: 0,
            rating: 0,
            thumbnail: '',
            images: [],
            availabilityStatus: '',
          ),
        );
        when(() => mockGetProductsUseCase(limit: 20, skip: 20)).thenAnswer(
          (_) => Stream.value(Right(ProductsResult(products: [tProduct2], isOffline: false))),
        );

        productsCubit.emit(
          ProductsLoaded(products: initialProducts, isOffline: false, hasReachedMax: false),
        );
        return productsCubit;
      },
      act: (cubit) => cubit.loadMoreProducts(),
      expect: () => [isA<ProductsLoaded>()],
      verify: (_) {
        final state = productsCubit.state as ProductsLoaded;
        expect(state.products.length, 21);
        expect(state.hasReachedMax, true);
      },
    );

    blocTest<ProductsCubit, ProductsState>(
      'loadMoreProducts does nothing when hasReachedMax is true',
      build: () {
        productsCubit.emit(
          const ProductsLoaded(products: [tProduct], isOffline: false, hasReachedMax: true),
        );
        return productsCubit;
      },
      act: (cubit) => cubit.loadMoreProducts(),
      expect: () => [],
    );

    blocTest<ProductsCubit, ProductsState>(
      'emits ProductsError with no_internet_no_data when offline and empty cache',
      build: () {
        when(() => mockGetProductsUseCase(limit: 20, skip: 0)).thenAnswer(
          (_) => Stream.value(const Right(ProductsResult(products: [], isOffline: true))),
        );
        return productsCubit;
      },
      act: (cubit) => cubit.loadInitialProducts(),
      expect: () => [const ProductsLoading(), const ProductsError(message: 'no_internet_no_data')],
    );
  });
}
