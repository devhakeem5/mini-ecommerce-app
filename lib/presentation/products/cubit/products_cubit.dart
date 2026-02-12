import 'package:flutter_bloc/flutter_bloc.dart';

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
                emit(ProductsError(message: failure.message));
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
}
