import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/product.dart';
import '../../../domain/usecases/products/search_products_locally_usecase.dart';
import '../../../domain/usecases/products/search_products_usecase.dart';
import '../../../domain/usecases/search/add_to_search_history_usecase.dart';
import '../../../domain/usecases/search/delete_search_history_usecase.dart';
import '../../../domain/usecases/search/get_search_history_usecase.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchProductsUseCase searchProductsUseCase;
  final SearchProductsLocallyUseCase searchProductsLocallyUseCase;
  final GetSearchHistoryUseCase getSearchHistoryUseCase;
  final AddToSearchHistoryUseCase addToSearchHistoryUseCase;
  final DeleteSearchHistoryUseCase deleteSearchHistoryUseCase;

  static const int _pageSize = 20;
  Timer? _debounce;
  List<String> _fullHistory = [];
  int _searchId = 0;
  String _lastQuery = '';
  bool _isFetching = false;

  SearchCubit({
    required this.searchProductsUseCase,
    required this.searchProductsLocallyUseCase,
    required this.getSearchHistoryUseCase,
    required this.addToSearchHistoryUseCase,
    required this.deleteSearchHistoryUseCase,
  }) : super(SearchInitial());

  Future<void> loadHistory() async {
    final result = await getSearchHistoryUseCase();
    result.fold((failure) => _fullHistory = [], (history) => _fullHistory = history);
    emit(SearchHistoryLoaded(history: _fullHistory));
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      _searchId++;
      _lastQuery = '';
      emit(SearchHistoryLoaded(history: _fullHistory));
      return;
    }

    final suggestions = _fullHistory
        .where((e) => e.toLowerCase().contains(query.toLowerCase()))
        .toList();
    emit(SearchHistoryLoaded(history: _fullHistory, suggestions: suggestions));

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        search(query);
      }
    });
  }

  Future<void> search(String query) async {
    if (query.isEmpty) return;

    _lastQuery = query;
    final int currentSearchId = ++_searchId;

    emit(SearchLoading());

    await addToSearchHistoryUseCase(query);
    final historyResult = await getSearchHistoryUseCase();
    historyResult.fold((l) {}, (r) => _fullHistory = r);

    if (currentSearchId != _searchId) return;

    final localResult = await searchProductsLocallyUseCase(query: query);
    localResult.fold((failure) {}, (productsResult) {
      if (!isClosed && currentSearchId == _searchId && productsResult.products.isNotEmpty) {
        emit(SearchResultsLoaded(products: productsResult.products, isOffline: true));
      }
    });

    if (currentSearchId != _searchId) return;

    try {
      final stream = searchProductsUseCase(query: query, limit: _pageSize, skip: 0);

      await stream.forEach((result) {
        if (isClosed || currentSearchId != _searchId) return;

        result.fold(
          (failure) {
            if (state is! SearchResultsLoaded) {
              emit(SearchError(failure.message));
            }
          },
          (productsResult) {
            final hasReachedMax = productsResult.products.length < _pageSize;
            emit(
              SearchResultsLoaded(
                products: _dedup(productsResult.products),
                isOffline: productsResult.isOffline,
                hasReachedMax: hasReachedMax,
                wasPagingAttempted: false,
              ),
            );
          },
        );
      });
    } catch (e) {
      if (!isClosed && currentSearchId == _searchId && state is! SearchResultsLoaded) {
        emit(SearchError(e.toString()));
      }
    }
  }

  Future<void> loadMoreResults() async {
    if (_isFetching) return;
    if (state is! SearchResultsLoaded) return;
    final currentState = state as SearchResultsLoaded;
    if (currentState.hasReachedMax) return;
    if (_lastQuery.isEmpty) return;

    _isFetching = true;
    final localId = _searchId;

    try {
      final skip = currentState.products.length;
      final stream = searchProductsUseCase(query: _lastQuery, limit: _pageSize, skip: skip);

      await stream.forEach((result) {
        if (isClosed || localId != _searchId) return;

        result.fold(
          (failure) {
            if (state is SearchResultsLoaded) {
              emit((state as SearchResultsLoaded).copyWith(loadMoreError: failure.message));
            }
          },
          (productsResult) {
            final newProducts = productsResult.products;
            final hasReachedMax = newProducts.length < _pageSize;
            final allProducts = _dedup(currentState.products + newProducts);

            emit(
              SearchResultsLoaded(
                products: allProducts,
                isOffline: productsResult.isOffline,
                hasReachedMax: hasReachedMax,
                wasPagingAttempted: true,
              ),
            );
          },
        );
      });
    } catch (e) {
      if (!isClosed && localId == _searchId && state is SearchResultsLoaded) {
        emit((state as SearchResultsLoaded).copyWith(loadMoreError: e.toString()));
      }
    }

    _isFetching = false;
  }

  List<Product> _dedup(List<Product> products) {
    final map = <int, Product>{};
    for (final p in products) {
      map[p.id] = p;
    }
    return map.values.toList();
  }

  Future<void> deleteHistoryItem(String query) async {
    await deleteSearchHistoryUseCase(query);
    final historyResult = await getSearchHistoryUseCase();
    historyResult.fold((l) {}, (r) => _fullHistory = r);

    if (state is SearchHistoryLoaded) {
      final currentState = state as SearchHistoryLoaded;
      final suggestions = currentState.suggestions.where((e) => e != query).toList();
      emit(SearchHistoryLoaded(history: _fullHistory, suggestions: suggestions));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
