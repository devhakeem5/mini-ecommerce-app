import 'package:equatable/equatable.dart';

import '../../../domain/entities/product.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchResultsLoaded extends SearchState {
  final List<Product> products;
  final bool isOffline;
  final bool hasReachedMax;
  final bool wasPagingAttempted;
  final String? loadMoreError;

  const SearchResultsLoaded({
    required this.products,
    required this.isOffline,
    this.hasReachedMax = false,
    this.wasPagingAttempted = false,
    this.loadMoreError,
  });

  SearchResultsLoaded copyWith({
    List<Product>? products,
    bool? isOffline,
    bool? hasReachedMax,
    bool? wasPagingAttempted,
    String? loadMoreError,
  }) {
    return SearchResultsLoaded(
      products: products ?? this.products,
      isOffline: isOffline ?? this.isOffline,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      wasPagingAttempted: wasPagingAttempted ?? this.wasPagingAttempted,
      loadMoreError: loadMoreError,
    );
  }

  @override
  List<Object?> get props => [
    products,
    isOffline,
    hasReachedMax,
    wasPagingAttempted,
    loadMoreError,
  ];
}

class SearchHistoryLoaded extends SearchState {
  final List<String> history;
  final List<String> suggestions;

  const SearchHistoryLoaded({required this.history, this.suggestions = const []});

  @override
  List<Object?> get props => [history, suggestions];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
