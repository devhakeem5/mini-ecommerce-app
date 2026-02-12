import 'package:equatable/equatable.dart';

import '../../../domain/entities/product.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final bool isOffline;
  final bool hasReachedMax;
  final String? loadMoreError;

  const ProductsLoaded({
    required this.products,
    required this.isOffline,
    this.hasReachedMax = false,
    this.loadMoreError,
  });

  ProductsLoaded copyWith({
    List<Product>? products,
    bool? isOffline,
    bool? hasReachedMax,
    String? loadMoreError,
  }) {
    return ProductsLoaded(
      products: products ?? this.products,
      isOffline: isOffline ?? this.isOffline,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      loadMoreError: loadMoreError,
    );
  }

  @override
  List<Object?> get props => [products, isOffline, hasReachedMax, loadMoreError];
}

class ProductsError extends ProductsState {
  final String message;

  const ProductsError({required this.message});

  @override
  List<Object?> get props => [message];
}
