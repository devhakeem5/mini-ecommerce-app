import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/usecases/cart/add_to_cart_usecase.dart';
import '../../../domain/usecases/cart/clear_cart_usecase.dart';
import '../../../domain/usecases/cart/load_cart_usecase.dart';
import '../../../domain/usecases/cart/remove_from_cart_usecase.dart';
import '../../../domain/usecases/cart/update_cart_prices_usecase.dart';
import '../../../domain/usecases/cart/update_cart_quantity_usecase.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final LoadCartUseCase loadCartUseCase;
  final AddToCartUseCase addToCartUseCase;
  final UpdateCartQuantityUseCase updateCartQuantityUseCase;
  final RemoveFromCartUseCase removeFromCartUseCase;
  final ClearCartUseCase clearCartUseCase;
  final UpdateCartPricesUseCase updateCartPricesUseCase;

  CartCubit({
    required this.loadCartUseCase,
    required this.addToCartUseCase,
    required this.updateCartQuantityUseCase,
    required this.removeFromCartUseCase,
    required this.clearCartUseCase,
    required this.updateCartPricesUseCase,
  }) : super(const CartInitial());

  Future<void> loadCart() async {
    emit(const CartLoading());
    try {
      final items = await loadCartUseCase();
      emit(CartLoaded(cart: Cart(items: items)));
    } catch (e) {
      emit(CartError('Failed to load cart: $e'));
    }
  }

  Future<void> addToCart(Product product) async {
    try {
      await addToCartUseCase(product);
      final items = await loadCartUseCase();
      emit(CartLoaded(cart: Cart(items: items)));
    } catch (e) {
      emit(CartError('Failed to add item: $e'));
    }
  }

  Future<void> increment(int productId) async {
    if (state is! CartLoaded) return;
    final currentItems = (state as CartLoaded).items;
    final item = currentItems.firstWhere((e) => e.product.id == productId);

    try {
      await updateCartQuantityUseCase(productId: productId, quantity: item.quantity + 1);
      final items = await loadCartUseCase();
      emit(CartLoaded(cart: Cart(items: items)));
    } catch (e) {
      emit(CartError('Failed to update quantity: $e'));
    }
  }

  Future<void> decrement(int productId) async {
    if (state is! CartLoaded) return;
    final currentItems = (state as CartLoaded).items;
    final item = currentItems.firstWhere((e) => e.product.id == productId);

    try {
      if (item.quantity <= 1) {
        await removeFromCartUseCase(productId);
      } else {
        await updateCartQuantityUseCase(productId: productId, quantity: item.quantity - 1);
      }
      final items = await loadCartUseCase();
      emit(CartLoaded(cart: Cart(items: items)));
    } catch (e) {
      emit(CartError('Failed to update quantity: $e'));
    }
  }

  Future<void> removeItem(int productId) async {
    try {
      await removeFromCartUseCase(productId);
      final items = await loadCartUseCase();
      emit(CartLoaded(cart: Cart(items: items)));
    } catch (e) {
      emit(CartError('Failed to remove item: $e'));
    }
  }

  Future<void> undoRemoveItem(CartItem item) async {
    try {
      await addToCartUseCase(item.product);
      if (item.quantity > 1) {
        await updateCartQuantityUseCase(productId: item.product.id, quantity: item.quantity);
      }
      final items = await loadCartUseCase();
      emit(CartLoaded(cart: Cart(items: items)));
    } catch (e) {
      emit(CartError('Failed to undo removal: $e'));
    }
  }

  Future<void> clearCart() async {
    try {
      await clearCartUseCase();
      emit(const CartLoaded(cart: Cart(items: [])));
    } catch (e) {
      emit(CartError('Failed to clear cart: $e'));
    }
  }

  Future<void> syncPrices(List<Product> latestProducts) async {
    if (state is! CartLoaded) return;

    try {
      await updateCartPricesUseCase(latestProducts);

      if (!isClosed) {
        final items = await loadCartUseCase();
        emit(CartLoaded(cart: Cart(items: items)));
      }
    } catch (e) {}
  }
}
