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
    final result = await loadCartUseCase();
    result.fold(
      (failure) => emit(CartError(failure.message)),
      (items) => emit(CartLoaded(cart: Cart(items: items))),
    );
  }

  Future<void> addToCart(Product product) async {
    try {
      final addResult = await addToCartUseCase(product);
      addResult.fold(
        (failure) {
          emit(CartError(failure.message));
        },
        (_) async {
          final loadResult = await loadCartUseCase();
          loadResult.fold(
            (failure) {
              emit(CartError(failure.message));
            },
            (items) {
              emit(CartLoaded(cart: Cart(items: items)));
            },
          );
        },
      );
    } catch (_) {}
  }

  Future<void> increment(int productId) async {
    if (state is! CartLoaded) return;
    final currentItems = (state as CartLoaded).items;
    final item = currentItems.firstWhere((e) => e.product.id == productId);

    final updateResult = await updateCartQuantityUseCase(
      productId: productId,
      quantity: item.quantity + 1,
    );
    updateResult.fold((failure) => emit(CartError(failure.message)), (_) async {
      final loadResult = await loadCartUseCase();
      loadResult.fold(
        (failure) => emit(CartError(failure.message)),
        (items) => emit(CartLoaded(cart: Cart(items: items))),
      );
    });
  }

  Future<void> decrement(int productId) async {
    if (state is! CartLoaded) return;
    final currentItems = (state as CartLoaded).items;
    final item = currentItems.firstWhere((e) => e.product.id == productId);

    if (item.quantity <= 1) {
      final removeResult = await removeFromCartUseCase(productId);
      removeResult.fold((failure) => emit(CartError(failure.message)), (_) async {
        final loadResult = await loadCartUseCase();
        loadResult.fold(
          (failure) => emit(CartError(failure.message)),
          (items) => emit(CartLoaded(cart: Cart(items: items))),
        );
      });
    } else {
      final updateResult = await updateCartQuantityUseCase(
        productId: productId,
        quantity: item.quantity - 1,
      );
      updateResult.fold((failure) => emit(CartError(failure.message)), (_) async {
        final loadResult = await loadCartUseCase();
        loadResult.fold(
          (failure) => emit(CartError(failure.message)),
          (items) => emit(CartLoaded(cart: Cart(items: items))),
        );
      });
    }
  }

  Future<void> removeItem(int productId) async {
    final removeResult = await removeFromCartUseCase(productId);
    removeResult.fold((failure) => emit(CartError(failure.message)), (_) async {
      final loadResult = await loadCartUseCase();
      loadResult.fold(
        (failure) => emit(CartError(failure.message)),
        (items) => emit(CartLoaded(cart: Cart(items: items))),
      );
    });
  }

  Future<void> undoRemoveItem(CartItem item) async {
    final addResult = await addToCartUseCase(item.product);
    addResult.fold((failure) => emit(CartError(failure.message)), (_) async {
      if (item.quantity > 1) {
        await updateCartQuantityUseCase(productId: item.product.id, quantity: item.quantity);
      }
      final loadResult = await loadCartUseCase();
      loadResult.fold(
        (failure) => emit(CartError(failure.message)),
        (items) => emit(CartLoaded(cart: Cart(items: items))),
      );
    });
  }

  Future<void> clearCart() async {
    final result = await clearCartUseCase();
    result.fold(
      (failure) => emit(CartError(failure.message)),
      (_) => emit(const CartLoaded(cart: Cart(items: []))),
    );
  }

  Future<void> syncPrices(List<Product> latestProducts) async {
    if (state is! CartLoaded) {
      return;
    }

    try {
      final updateResult = await updateCartPricesUseCase(latestProducts);
      updateResult.fold(
        (_) {},
        (_) async {
          if (!isClosed) {
            final loadResult = await loadCartUseCase();
            loadResult.fold((_) {}, (items) {
              emit(CartLoaded(cart: Cart(items: items)));
            });
          }
        },
      );
    } catch (_) {}
  }
}
