import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/core/error/failures.dart';
import 'package:mini_commerce_app/domain/entities/product.dart';
import 'package:mini_commerce_app/domain/entities/products_result.dart';
import 'package:mini_commerce_app/domain/usecases/products/get_products_usecase.dart';
import 'package:mini_commerce_app/presentation/products/cubit/promotions_cubit.dart';
import 'package:mini_commerce_app/presentation/products/cubit/promotions_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetProductsUseCase extends Mock implements GetProductsUseCase {}

void main() {
  late PromotionsCubit promotionsCubit;
  late MockGetProductsUseCase mockGetProductsUseCase;

  setUp(() {
    mockGetProductsUseCase = MockGetProductsUseCase();
    promotionsCubit = PromotionsCubit(getProductsUseCase: mockGetProductsUseCase);
  });

  tearDown(() {
    promotionsCubit.close();
  });

  const tProduct = Product(
    id: 1,
    title: 'Promo Product',
    description: 'Desc',
    brand: 'Brand',
    category: 'Category',
    price: 100.0,
    discountPercentage: 10.0,
    rating: 4.5,
    thumbnail: 'url',
    images: [],
    availabilityStatus: 'In Stock',
  );

  final tProductsResult = ProductsResult(products: [tProduct], isOffline: false);
  final tEmptyOfflineResult = ProductsResult(products: [], isOffline: true);

  group('PromotionsCubit', () {
    test('initial state is PromotionsInitial', () {
      expect(promotionsCubit.state, isA<PromotionsInitial>());
    });

    blocTest<PromotionsCubit, PromotionsState>(
      'emits [PromotionsLoading, PromotionsLoaded] when loadPromotions is successful',
      build: () {
        when(
          () => mockGetProductsUseCase(
            limit: 5,
            skip: 0,
            sortBy: 'discountPercentage',
            order: 'desc',
          ),
        ).thenAnswer((_) => Stream.value(Right(tProductsResult)));
        return promotionsCubit;
      },
      act: (cubit) => cubit.loadPromotions(),
      expect: () => [
        isA<PromotionsLoading>(),
        PromotionsLoaded(products: [tProduct], isOffline: false),
      ],
    );

    blocTest<PromotionsCubit, PromotionsState>(
      'emits [PromotionsLoading, PromotionsError] with no_internet_no_data when offline empty',
      build: () {
        when(
          () => mockGetProductsUseCase(
            limit: 5,
            skip: 0,
            sortBy: 'discountPercentage',
            order: 'desc',
          ),
        ).thenAnswer((_) => Stream.value(Right(tEmptyOfflineResult)));
        return promotionsCubit;
      },
      act: (cubit) => cubit.loadPromotions(),
      expect: () => [isA<PromotionsLoading>(), const PromotionsError('no_internet_no_data')],
    );

    blocTest<PromotionsCubit, PromotionsState>(
      'refresh emits new state when data changes',
      build: () {
        when(
          () => mockGetProductsUseCase(
            limit: 5,
            skip: 0,
            sortBy: 'discountPercentage',
            order: 'desc',
          ),
        ).thenAnswer((_) => Stream.value(Right(tProductsResult)));
        // Initial state is empty offline (error) to loaded
        promotionsCubit.emit(const PromotionsError('no_internet_no_data'));
        return promotionsCubit;
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [
        PromotionsLoaded(products: [tProduct], isOffline: false),
      ],
    );

    blocTest<PromotionsCubit, PromotionsState>(
      'refresh does NOT emit when data is same',
      build: () {
        when(
          () => mockGetProductsUseCase(
            limit: 5,
            skip: 0,
            sortBy: 'discountPercentage',
            order: 'desc',
          ),
        ).thenAnswer((_) => Stream.value(Right(tProductsResult)));
        promotionsCubit.emit(PromotionsLoaded(products: [tProduct], isOffline: false));
        return promotionsCubit;
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [],
    );
    blocTest<PromotionsCubit, PromotionsState>(
      'emits [PromotionsLoading, PromotionsLoaded] and ignores subsequent NetworkFailure if data exists',
      build: () {
        when(
          () => mockGetProductsUseCase(
            limit: 5,
            skip: 0,
            sortBy: 'discountPercentage',
            order: 'desc',
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            Right(tProductsResult), // Cache
            const Left(NetworkFailure()), // Network Error
          ]),
        );
        return promotionsCubit;
      },
      act: (cubit) => cubit.loadPromotions(),
      expect: () => [
        isA<PromotionsLoading>(),
        PromotionsLoaded(products: [tProduct], isOffline: false),
        // Should NOT emit Error here
      ],
    );
  });
}
