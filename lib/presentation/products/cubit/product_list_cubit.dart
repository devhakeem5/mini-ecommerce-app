import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/product.dart';
import '../../../domain/usecases/products/get_products_by_category_usecase.dart';
import '../../../domain/usecases/products/get_products_usecase.dart';
import 'product_list_state.dart';

class ProductListCubit extends Cubit<ProductListState> {
  final GetProductsUseCase getProductsUseCase;
  final GetProductsByCategoryUseCase getProductsByCategoryUseCase;
  static const int _pageSize = 20;

  String? _category;
  bool _isFetchingMore = false;

  ProductListCubit({required this.getProductsUseCase, required this.getProductsByCategoryUseCase})
    : super(const ProductListInitial());

  Future<void> loadInitial({String? category}) async {
    _category = category;
    emit(const ProductListLoading());
    await _fetchProducts(isInitial: true);
  }

  Future<void> loadMore() async {
    if (state is! ProductListLoaded) return;
    final currentState = state as ProductListLoaded;
    if (currentState.hasReachedMax || _isFetchingMore) return;

    _isFetchingMore = true;
    await _fetchProducts(isInitial: false, currentProducts: currentState.products);
    _isFetchingMore = false;
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

      final stream = _category != null
          ? getProductsByCategoryUseCase(category: _category!, limit: _pageSize, skip: skip)
          : getProductsUseCase(limit: _pageSize, skip: skip);

      await stream.forEach((result) {
        if (isClosed) return;

        result.fold(
          (failure) {
            if (isInitial) {
              if (state is ProductListLoaded) {
                emit((state as ProductListLoaded).copyWith(loadMoreError: failure.message));
              } else {
                emit(ProductListError('load_failed'));
              }
            } else if (state is ProductListLoaded) {
              emit((state as ProductListLoaded).copyWith(loadMoreError: failure.message));
            }
          },
          (productsResult) {
            final newProducts = productsResult.products;
            final hasReachedMax = newProducts.length < _pageSize;
            final allProducts = _dedup(isInitial ? newProducts : (currentProducts + newProducts));

            if (isInitial && allProducts.isEmpty) {
              if (productsResult.isOffline) {
                emit(const ProductListError('no_internet_no_data'));
              } else {
                emit(const ProductListLoaded(products: [], hasReachedMax: true));
              }
              return;
            }

            if (!isInitial && productsResult.isOffline && newProducts.isEmpty) {
              emit(
                (state as ProductListLoaded).copyWith(
                  isOffline: true,
                  loadMoreError: 'no_internet',
                ),
              );
              return;
            }

            emit(
              ProductListLoaded(
                products: allProducts,
                isOffline: productsResult.isOffline,
                hasReachedMax: hasReachedMax,
                wasPagingAttempted: !isInitial,
              ),
            );
          },
        );
      });
    } catch (e) {
      if (isInitial) {
        emit(ProductListError('load_failed'));
      } else if (state is ProductListLoaded) {
        emit((state as ProductListLoaded).copyWith(loadMoreError: e.toString()));
      }
    }
  }
}
