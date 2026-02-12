import 'package:equatable/equatable.dart';

import '../../../../domain/entities/product.dart';

abstract class PromotionsState extends Equatable {
  const PromotionsState();

  @override
  List<Object?> get props => [];
}

class PromotionsInitial extends PromotionsState {}

class PromotionsLoading extends PromotionsState {}

class PromotionsLoaded extends PromotionsState {
  final List<Product> products;
  final bool isOffline;

  const PromotionsLoaded({required this.products, required this.isOffline});

  @override
  List<Object?> get props => [products, isOffline];
}

class PromotionsError extends PromotionsState {
  final String message;

  const PromotionsError(this.message);

  @override
  List<Object?> get props => [message];
}
