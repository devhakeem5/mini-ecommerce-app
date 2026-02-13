import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/domain/entities/cart.dart';
import 'package:mini_commerce_app/domain/entities/cart_item.dart';
import 'package:mini_commerce_app/domain/entities/product.dart';
import 'package:mini_commerce_app/domain/usecases/cart/add_to_cart_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/cart/clear_cart_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/cart/load_cart_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/cart/remove_from_cart_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/cart/update_cart_prices_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/cart/update_cart_quantity_usecase.dart';
import 'package:mini_commerce_app/presentation/cart/cubit/cart_cubit.dart';
import 'package:mini_commerce_app/presentation/cart/cubit/cart_state.dart';
import 'package:mocktail/mocktail.dart';

class MockLoadCartUseCase extends Mock implements LoadCartUseCase {}

class MockAddToCartUseCase extends Mock implements AddToCartUseCase {}

class MockUpdateCartQuantityUseCase extends Mock implements UpdateCartQuantityUseCase {}

class MockRemoveFromCartUseCase extends Mock implements RemoveFromCartUseCase {}

class MockClearCartUseCase extends Mock implements ClearCartUseCase {}

class MockUpdateCartPricesUseCase extends Mock implements UpdateCartPricesUseCase {}

void main() {
  late CartCubit cartCubit;
  late MockLoadCartUseCase mockLoadCartUseCase;
  late MockAddToCartUseCase mockAddToCartUseCase;
  late MockUpdateCartQuantityUseCase mockUpdateCartQuantityUseCase;
  late MockRemoveFromCartUseCase mockRemoveFromCartUseCase;
  late MockClearCartUseCase mockClearCartUseCase;
  late MockUpdateCartPricesUseCase mockUpdateCartPricesUseCase;

  setUp(() {
    mockLoadCartUseCase = MockLoadCartUseCase();
    mockAddToCartUseCase = MockAddToCartUseCase();
    mockUpdateCartQuantityUseCase = MockUpdateCartQuantityUseCase();
    mockRemoveFromCartUseCase = MockRemoveFromCartUseCase();
    mockClearCartUseCase = MockClearCartUseCase();
    mockUpdateCartPricesUseCase = MockUpdateCartPricesUseCase();

    cartCubit = CartCubit(
      loadCartUseCase: mockLoadCartUseCase,
      addToCartUseCase: mockAddToCartUseCase,
      updateCartQuantityUseCase: mockUpdateCartQuantityUseCase,
      removeFromCartUseCase: mockRemoveFromCartUseCase,
      clearCartUseCase: mockClearCartUseCase,
      updateCartPricesUseCase: mockUpdateCartPricesUseCase,
    );
  });

  tearDown(() {
    cartCubit.close();
  });

  const tProduct = Product(
    id: 1,
    title: 'Test Product',
    description: 'Desc',
    brand: 'Brand',
    category: 'Category',
    price: 100.0,
    discountPercentage: 0.0,
    rating: 4.5,
    thumbnail: 'url',
    images: [],
    availabilityStatus: 'In Stock',
  );

  final tCartItem = CartItem(product: tProduct, quantity: 1);
  final tCartItems = [tCartItem];

  group('CartCubit', () {
    test('initial state is CartInitial', () {
      expect(cartCubit.state, const CartInitial());
    });

    blocTest<CartCubit, CartState>(
      'emits [CartLoading, CartLoaded] when loadCart is successful',
      build: () {
        when(() => mockLoadCartUseCase()).thenAnswer((_) async => tCartItems);
        return cartCubit;
      },
      act: (cubit) => cubit.loadCart(),
      expect: () => [const CartLoading(), CartLoaded(cart: Cart(items: tCartItems))],
      verify: (_) {
        verify(() => mockLoadCartUseCase()).called(1);
      },
    );

    blocTest<CartCubit, CartState>(
      'emits [CartLoaded] when addToCart is successful',
      build: () {
        when(() => mockAddToCartUseCase(tProduct)).thenAnswer((_) async {});
        when(() => mockLoadCartUseCase()).thenAnswer((_) async => tCartItems);
        return cartCubit;
      },
      act: (cubit) => cubit.addToCart(tProduct),
      expect: () => [CartLoaded(cart: Cart(items: tCartItems))],
      verify: (_) {
        verify(() => mockAddToCartUseCase(tProduct)).called(1);
        verify(() => mockLoadCartUseCase()).called(1);
      },
    );

    blocTest<CartCubit, CartState>(
      'removes item when decrementing quantity 1',
      build: () {
        when(() => mockRemoveFromCartUseCase(tProduct.id)).thenAnswer((_) async {});
        when(() => mockLoadCartUseCase()).thenAnswer((_) async => []);

        cartCubit.emit(CartLoaded(cart: Cart(items: tCartItems)));
        return cartCubit;
      },
      act: (cubit) => cubit.decrement(tProduct.id),
      expect: () => [const CartLoaded(cart: Cart(items: []))],
      verify: (_) {
        verify(() => mockRemoveFromCartUseCase(tProduct.id)).called(1);
        verifyNever(
          () => mockUpdateCartQuantityUseCase(
            productId: any(named: 'productId'),
            quantity: any(named: 'quantity'),
          ),
        );
      },
    );

    blocTest<CartCubit, CartState>(
      'updates quantity when incrementing',
      build: () {
        const tNewQuantity = 2;
        when(
          () => mockUpdateCartQuantityUseCase(productId: tProduct.id, quantity: tNewQuantity),
        ).thenAnswer((_) async {});

        final tUpdatedItems = [tCartItem.copyWith(quantity: tNewQuantity)];
        when(() => mockLoadCartUseCase()).thenAnswer((_) async => tUpdatedItems);

        cartCubit.emit(CartLoaded(cart: Cart(items: tCartItems)));
        return cartCubit;
      },
      act: (cubit) => cubit.increment(tProduct.id),
      expect: () => [
        CartLoaded(cart: Cart(items: [tCartItem.copyWith(quantity: 2)])),
      ],
      verify: (_) {
        verify(() => mockUpdateCartQuantityUseCase(productId: tProduct.id, quantity: 2)).called(1);
      },
    );

    blocTest<CartCubit, CartState>(
      'emits [CartLoaded(empty)] when clearCart is successful',
      build: () {
        when(() => mockClearCartUseCase()).thenAnswer((_) async {});
        return cartCubit;
      },
      act: (cubit) => cubit.clearCart(),
      expect: () => [const CartLoaded(cart: Cart(items: []))],
      verify: (_) {
        verify(() => mockClearCartUseCase()).called(1);
      },
    );

    blocTest<CartCubit, CartState>(
      'emits [CartLoaded] when removeItem is successful',
      build: () {
        when(() => mockRemoveFromCartUseCase(tProduct.id)).thenAnswer((_) async {});
        when(() => mockLoadCartUseCase()).thenAnswer((_) async => []);
        return cartCubit;
      },
      act: (cubit) => cubit.removeItem(tProduct.id),
      expect: () => [const CartLoaded(cart: Cart(items: []))],
      verify: (_) {
        verify(() => mockRemoveFromCartUseCase(tProduct.id)).called(1);
      },
    );

    blocTest<CartCubit, CartState>(
      'emits [CartLoaded] when undoRemoveItem restores item with quantity 1',
      build: () {
        when(() => mockAddToCartUseCase(tProduct)).thenAnswer((_) async {});
        when(() => mockLoadCartUseCase()).thenAnswer((_) async => tCartItems);
        return cartCubit;
      },
      act: (cubit) => cubit.undoRemoveItem(tCartItem),
      expect: () => [CartLoaded(cart: Cart(items: tCartItems))],
      verify: (_) {
        verify(() => mockAddToCartUseCase(tProduct)).called(1);
        verifyNever(
          () => mockUpdateCartQuantityUseCase(
            productId: any(named: 'productId'),
            quantity: any(named: 'quantity'),
          ),
        );
      },
    );

    blocTest<CartCubit, CartState>(
      'emits [CartLoaded] when undoRemoveItem restores item with quantity > 1',
      build: () {
        final tMultiItem = CartItem(product: tProduct, quantity: 3);
        when(() => mockAddToCartUseCase(tProduct)).thenAnswer((_) async {});
        when(
          () => mockUpdateCartQuantityUseCase(productId: tProduct.id, quantity: 3),
        ).thenAnswer((_) async {});
        when(() => mockLoadCartUseCase()).thenAnswer((_) async => [tMultiItem]);
        return cartCubit;
      },
      act: (cubit) => cubit.undoRemoveItem(CartItem(product: tProduct, quantity: 3)),
      expect: () => [
        CartLoaded(
          cart: Cart(items: [CartItem(product: tProduct, quantity: 3)]),
        ),
      ],
      verify: (_) {
        verify(() => mockAddToCartUseCase(tProduct)).called(1);
        verify(() => mockUpdateCartQuantityUseCase(productId: tProduct.id, quantity: 3)).called(1);
      },
    );

    blocTest<CartCubit, CartState>(
      'emits [CartLoading, CartError] when loadCart throws',
      build: () {
        when(() => mockLoadCartUseCase()).thenThrow(Exception('DB error'));
        return cartCubit;
      },
      act: (cubit) => cubit.loadCart(),
      expect: () => [const CartLoading(), isA<CartError>()],
    );

    blocTest<CartCubit, CartState>(
      'emits [CartError] when addToCart throws',
      build: () {
        when(() => mockAddToCartUseCase(tProduct)).thenThrow(Exception('Write error'));
        return cartCubit;
      },
      act: (cubit) => cubit.addToCart(tProduct),
      expect: () => [isA<CartError>()],
    );

    blocTest<CartCubit, CartState>(
      'emits [CartError] when clearCart throws',
      build: () {
        when(() => mockClearCartUseCase()).thenThrow(Exception('Clear error'));
        return cartCubit;
      },
      act: (cubit) => cubit.clearCart(),
      expect: () => [isA<CartError>()],
    );

    blocTest<CartCubit, CartState>(
      'syncPrices does nothing when state is not CartLoaded',
      build: () => cartCubit,
      act: (cubit) => cubit.syncPrices([tProduct]),
      expect: () => [],
    );

    blocTest<CartCubit, CartState>(
      'syncPrices updates prices and reloads cart',
      build: () {
        const updatedProduct = Product(
          id: 1,
          title: 'Test Product',
          description: 'Desc',
          brand: 'Brand',
          category: 'Category',
          price: 90.0,
          discountPercentage: 0.0,
          rating: 4.5,
          thumbnail: 'url',
          images: [],
          availabilityStatus: 'In Stock',
        );
        final updatedItems = [CartItem(product: updatedProduct, quantity: 1)];
        when(() => mockUpdateCartPricesUseCase([tProduct])).thenAnswer((_) async {});
        when(() => mockLoadCartUseCase()).thenAnswer((_) async => updatedItems);
        return cartCubit;
      },
      seed: () => CartLoaded(cart: Cart(items: tCartItems)),
      act: (cubit) => cubit.syncPrices([tProduct]),
      expect: () => [isA<CartLoaded>()],
      verify: (_) {
        verify(() => mockUpdateCartPricesUseCase([tProduct])).called(1);
        verify(() => mockLoadCartUseCase()).called(1);
      },
    );
  });
}
