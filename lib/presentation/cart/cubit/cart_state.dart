import 'package:equatable/equatable.dart';

import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_item.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {
  const CartInitial();
}

class CartLoading extends CartState {
  const CartLoading();
}

class CartLoaded extends CartState {
  final Cart cart;

  const CartLoaded({required this.cart});

  List<CartItem> get items => cart.items;
  int get itemCount => cart.itemCount;
  double get totalPrice => cart.totalPrice;
  double get totalDiscountedPrice => cart.totalDiscountedPrice;
  double get totalSavings => cart.totalSavings;

  @override
  List<Object?> get props => [cart];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}
