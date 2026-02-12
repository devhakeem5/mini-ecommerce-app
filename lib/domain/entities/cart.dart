import 'package:equatable/equatable.dart';

import 'cart_item.dart';

class Cart extends Equatable {
  final List<CartItem> items;

  const Cart({required this.items});

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get totalDiscountedPrice =>
      items.fold(0.0, (sum, item) => sum + item.totalDiscountedPrice);

  double get totalSavings => totalPrice - totalDiscountedPrice;

  Cart copyWith({List<CartItem>? items}) {
    return Cart(items: items ?? this.items);
  }

  @override
  List<Object?> get props => [items];
}
