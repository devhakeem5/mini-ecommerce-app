import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/usecases/products/get_products_usecase.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final GetProductsUseCase getProductsUseCase;

  static const int _pageSize = 20;
  bool _isFetching = false;

  ProductsCubit({required this.getProductsUseCase}) : super(const ProductsInitial());

  Future<void> loadInitialProducts() async {
    if (_isFetching) return;
    _isFetching = true;
    emit(const ProductsLoading());
    await _fetchProducts(isInitial: true);
    _isFetching = false;
  }

  Future<void> loadMoreProducts() async {
    if (_isFetching) return;
    if (state is! ProductsLoaded) return;
    final currentState = state as ProductsLoaded;
    if (currentState.hasReachedMax) return;

    _isFetching = true;
    await _fetchProducts(isInitial: false, currentProducts: currentState.products);
    _isFetching = false;
  }

  List<Product> _dedup(List<Product> products) {
    final map = <int, Product>{};
    for (final p in products) {
      map[p.id] = p;
    }
    return map.values.toList();
  }

  Future<void> _fetchProducts({
    required bool isInitial,
    List<Product> currentProducts = const [],
  }) async {
    try {
      final int skip = currentProducts.length;
      final stream = getProductsUseCase(limit: _pageSize, skip: skip);

      await stream.forEach((result) {
        if (isClosed) return;

        result.fold(
          (failure) {
            if (isInitial) {
              if (state is ProductsLoaded) {
                emit((state as ProductsLoaded).copyWith(loadMoreError: failure.message));
              } else {
                if (failure is NetworkFailure) {
                  emit(const ProductsError(message: 'no_internet_no_data'));
                } else {
                  emit(ProductsError(message: failure.message));
                }
              }
            } else if (state is ProductsLoaded) {
              emit((state as ProductsLoaded).copyWith(loadMoreError: failure.message));
            }
          },
          (productsResult) {
            final newProducts = productsResult.products;
            final hasReachedMax = newProducts.length < _pageSize;
            final allProducts = _dedup(isInitial ? newProducts : (currentProducts + newProducts));

            if (isInitial && allProducts.isEmpty && productsResult.isOffline) {
              emit(const ProductsError(message: 'no_internet_no_data'));
              return;
            }

            emit(
              ProductsLoaded(
                products: allProducts,
                isOffline: productsResult.isOffline,
                hasReachedMax: hasReachedMax,
              ),
            );
          },
        );
      });
    } catch (e) {
      if (isInitial) {
        emit(ProductsError(message: e.toString()));
      } else if (state is ProductsLoaded) {
        emit((state as ProductsLoaded).copyWith(loadMoreError: e.toString()));
      }
    }
  }

  Future<void> refresh() async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final stream = getProductsUseCase(limit: _pageSize, skip: 0);
      await stream.forEach((result) {
        if (isClosed) return;

        result.fold(
          (failure) {
            // Silent failure - do not disturb UI
          },
          (productsResult) {
            final newProducts = _dedup(productsResult.products);
            final hasReachedMax = productsResult.products.length < _pageSize;

            if (state is ProductsLoaded) {
              final currentState = state as ProductsLoaded;
              if (!_areProductListsEqual(currentState.products, newProducts) ||
                  currentState.isOffline != productsResult.isOffline) {
                emit(
                  ProductsLoaded(
                    products: newProducts,
                    isOffline: productsResult.isOffline,
                    hasReachedMax: hasReachedMax,
                  ),
                );
              }
            } else {
              // If we were in Error/Loading state and got data, update
              if (newProducts.isNotEmpty || !productsResult.isOffline) {
                emit(
                  ProductsLoaded(
                    products: newProducts,
                    isOffline: productsResult.isOffline,
                    hasReachedMax: hasReachedMax,
                  ),
                );
              } else if (newProducts.isEmpty && productsResult.isOffline) {
                // Remain in error/empty state if still offline empty
              }
            }
          },
        );
      });
    } catch (_) {
      // Silent error
    } finally {
      _isFetching = false;
    }
  }

  bool _areProductListsEqual(List<Product> list1, List<Product> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
      // We could check other fields if needed, but ID is usually sufficient for identity
    }
    return true;
  }
}
