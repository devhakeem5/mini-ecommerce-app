import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/core/error/failures.dart';
import 'package:mini_commerce_app/domain/entities/product.dart';
import 'package:mini_commerce_app/domain/entities/products_result.dart';
import 'package:mini_commerce_app/domain/usecases/products/search_products_locally_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/products/search_products_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/search/add_to_search_history_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/search/delete_search_history_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/search/get_search_history_usecase.dart';
import 'package:mini_commerce_app/presentation/products/cubit/search_cubit.dart';
import 'package:mini_commerce_app/presentation/products/cubit/search_state.dart';
import 'package:mocktail/mocktail.dart';

class MockSearchProductsUseCase extends Mock implements SearchProductsUseCase {}

class MockSearchProductsLocallyUseCase extends Mock implements SearchProductsLocallyUseCase {}

class MockGetSearchHistoryUseCase extends Mock implements GetSearchHistoryUseCase {}

class MockAddToSearchHistoryUseCase extends Mock implements AddToSearchHistoryUseCase {}

class MockDeleteSearchHistoryUseCase extends Mock implements DeleteSearchHistoryUseCase {}

void main() {
  late SearchCubit searchCubit;
  late MockSearchProductsUseCase mockSearchProductsUseCase;
  late MockSearchProductsLocallyUseCase mockSearchProductsLocallyUseCase;
  late MockGetSearchHistoryUseCase mockGetSearchHistoryUseCase;
  late MockAddToSearchHistoryUseCase mockAddToSearchHistoryUseCase;
  late MockDeleteSearchHistoryUseCase mockDeleteSearchHistoryUseCase;

  setUp(() {
    mockSearchProductsUseCase = MockSearchProductsUseCase();
    mockSearchProductsLocallyUseCase = MockSearchProductsLocallyUseCase();
    mockGetSearchHistoryUseCase = MockGetSearchHistoryUseCase();
    mockAddToSearchHistoryUseCase = MockAddToSearchHistoryUseCase();
    mockDeleteSearchHistoryUseCase = MockDeleteSearchHistoryUseCase();

    when(() => mockGetSearchHistoryUseCase()).thenAnswer((_) async => const Right([]));

    searchCubit = SearchCubit(
      searchProductsUseCase: mockSearchProductsUseCase,
      searchProductsLocallyUseCase: mockSearchProductsLocallyUseCase,
      getSearchHistoryUseCase: mockGetSearchHistoryUseCase,
      addToSearchHistoryUseCase: mockAddToSearchHistoryUseCase,
      deleteSearchHistoryUseCase: mockDeleteSearchHistoryUseCase,
    );
  });

  tearDown(() {
    searchCubit.close();
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

  const tProductsResult = ProductsResult(products: [tProduct], isOffline: false);
  const tLocalProductsResult = ProductsResult(products: [tProduct], isOffline: true);

  group('SearchCubit', () {
    test('initial state is SearchInitial', () {
      expect(searchCubit.state, isA<SearchInitial>());
    });

    blocTest<SearchCubit, SearchState>(
      'emits [SearchHistoryLoaded] when loadHistory is called',
      build: () {
        when(() => mockGetSearchHistoryUseCase()).thenAnswer((_) async => const Right(['test']));
        return searchCubit;
      },
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        const SearchHistoryLoaded(history: ['test']),
      ],
      verify: (_) {
        verify(() => mockGetSearchHistoryUseCase()).called(1);
      },
    );

    blocTest<SearchCubit, SearchState>(
      'emits [SearchLoading, SearchResultsLoaded] when search is successful',
      build: () {
        when(() => mockAddToSearchHistoryUseCase(any())).thenAnswer((_) async => const Right(null));

        when(
          () => mockSearchProductsLocallyUseCase(query: 'test'),
        ).thenAnswer((_) async => const Right(ProductsResult(products: [], isOffline: true)));

        when(
          () => mockSearchProductsUseCase(query: 'test', limit: 20, skip: 0),
        ).thenAnswer((_) => Stream.value(const Right(tProductsResult)));
        return searchCubit;
      },
      act: (cubit) => cubit.search('test'),
      expect: () => [
        isA<SearchLoading>(),

        SearchResultsLoaded(products: [tProduct], isOffline: false, hasReachedMax: true),
      ],
      verify: (_) {
        verify(() => mockAddToSearchHistoryUseCase('test')).called(1);
        verify(() => mockSearchProductsLocallyUseCase(query: 'test')).called(1);
        verify(() => mockSearchProductsUseCase(query: 'test', limit: 20, skip: 0)).called(1);
      },
    );

    blocTest<SearchCubit, SearchState>(
      'emits local results immediately if found',
      build: () {
        when(() => mockAddToSearchHistoryUseCase(any())).thenAnswer((_) async => const Right(null));

        when(
          () => mockSearchProductsLocallyUseCase(query: 'test'),
        ).thenAnswer((_) async => const Right(tLocalProductsResult));

        when(
          () => mockSearchProductsUseCase(query: 'test', limit: 20, skip: 0),
        ).thenAnswer((_) => Stream.value(const Left(NetworkFailure('Offline'))));
        return searchCubit;
      },
      act: (cubit) => cubit.search('test'),
      expect: () => [
        isA<SearchLoading>(),
        SearchResultsLoaded(products: [tProduct], isOffline: true),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'deleteHistoryItem removes item and updates state',
      build: () {
        when(
          () => mockDeleteSearchHistoryUseCase('test'),
        ).thenAnswer((_) async => const Right(null));
        when(() => mockGetSearchHistoryUseCase()).thenAnswer((_) async => const Right(['other']));
        searchCubit.emit(
          const SearchHistoryLoaded(history: ['test', 'other'], suggestions: ['test']),
        );
        return searchCubit;
      },
      act: (cubit) => cubit.deleteHistoryItem('test'),
      expect: () => [
        const SearchHistoryLoaded(history: ['other'], suggestions: []),
      ],
      verify: (_) {
        verify(() => mockDeleteSearchHistoryUseCase('test')).called(1);
      },
    );

    test('search with empty query does nothing', () async {
      await searchCubit.search('');
      expect(searchCubit.state, isA<SearchInitial>());
    });

    blocTest<SearchCubit, SearchState>(
      'onSearchChanged with empty query resets to history',
      build: () {
        return searchCubit;
      },
      seed: () => const SearchHistoryLoaded(history: ['prev']),
      act: (cubit) => cubit.onSearchChanged(''),
      expect: () => [isA<SearchHistoryLoaded>()],
    );
  });
}
