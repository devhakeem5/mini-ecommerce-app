import '../../../domain/entities/product.dart';

abstract class ProductListState {
  const ProductListState();
}

class ProductListInitial extends ProductListState {
  const ProductListInitial();
}

class ProductListLoading extends ProductListState {
  const ProductListLoading();
}

class ProductListLoaded extends ProductListState {
  final List<Product> products;
  final bool hasReachedMax;
  final bool isOffline;
  final bool wasPagingAttempted;
  final String? loadMoreError;

  const ProductListLoaded({
    this.products = const [],
    this.hasReachedMax = false,
    this.isOffline = false,
    this.wasPagingAttempted = false,
    this.loadMoreError,
  });

  ProductListLoaded copyWith({
    List<Product>? products,
    bool? hasReachedMax,
    bool? isOffline,
    bool? wasPagingAttempted,
    String? loadMoreError,
  }) {
    return ProductListLoaded(
      products: products ?? this.products,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isOffline: isOffline ?? this.isOffline,
      wasPagingAttempted: wasPagingAttempted ?? this.wasPagingAttempted,
      loadMoreError: loadMoreError,
    );
  }
}

class ProductListError extends ProductListState {
  final String message;

  const ProductListError(this.message);
}
