import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/core/error/failures.dart';
import 'package:mini_commerce_app/domain/entities/cart_item.dart';
import 'package:mini_commerce_app/domain/entities/product.dart';
import 'package:mini_commerce_app/domain/repositories/cart_repository.dart';
import 'package:mini_commerce_app/domain/usecases/cart/add_to_cart_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/cart/clear_cart_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/cart/load_cart_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/cart/remove_from_cart_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/cart/update_cart_prices_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/cart/update_cart_quantity_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockCartRepository extends Mock implements CartRepository {}

void main() {
  late MockCartRepository mockRepository;

  setUp(() {
    mockRepository = MockCartRepository();
  });

  const tProduct = Product(
    id: 1,
    title: 'Test',
    description: 'Desc',
    brand: 'Brand',
    category: 'Cat',
    price: 100.0,
    discountPercentage: 0,
    rating: 4.0,
    thumbnail: 'url',
    images: [],
    availabilityStatus: 'In Stock',
  );

  group('AddToCartUseCase', () {
    late AddToCartUseCase useCase;

    setUp(() {
      useCase = AddToCartUseCase(mockRepository);
    });

    test('delegates to repository.addToCart and returns Right on success', () async {
      when(() => mockRepository.addToCart(tProduct)).thenAnswer((_) async => const Right(null));
      final result = await useCase(tProduct);
      expect(result, const Right(null));
      verify(() => mockRepository.addToCart(tProduct)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('returns Left on failure', () async {
      when(
        () => mockRepository.addToCart(tProduct),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      final result = await useCase(tProduct);
      expect(result, const Left(CacheFailure()));
    });
  });

  group('LoadCartUseCase', () {
    late LoadCartUseCase useCase;

    setUp(() {
      useCase = LoadCartUseCase(mockRepository);
    });

    test('delegates to repository.loadCart and returns Right with items', () async {
      final tItems = [CartItem(product: tProduct, quantity: 1)];
      when(() => mockRepository.loadCart()).thenAnswer((_) async => Right(tItems));

      final result = await useCase();

      expect(result, Right(tItems));
      verify(() => mockRepository.loadCart()).called(1);
    });

    test('returns Left on failure', () async {
      when(() => mockRepository.loadCart()).thenAnswer((_) async => const Left(CacheFailure()));
      final result = await useCase();
      expect(result, const Left(CacheFailure()));
    });
  });

  group('RemoveFromCartUseCase', () {
    late RemoveFromCartUseCase useCase;

    setUp(() {
      useCase = RemoveFromCartUseCase(mockRepository);
    });

    test('delegates to repository.removeFromCart and returns Right', () async {
      when(() => mockRepository.removeFromCart(1)).thenAnswer((_) async => const Right(null));
      final result = await useCase(1);
      expect(result, const Right(null));
      verify(() => mockRepository.removeFromCart(1)).called(1);
    });
  });

  group('ClearCartUseCase', () {
    late ClearCartUseCase useCase;

    setUp(() {
      useCase = ClearCartUseCase(mockRepository);
    });

    test('delegates to repository.clearCart and returns Right', () async {
      when(() => mockRepository.clearCart()).thenAnswer((_) async => const Right(null));
      final result = await useCase();
      expect(result, const Right(null));
      verify(() => mockRepository.clearCart()).called(1);
    });
  });

  group('UpdateCartQuantityUseCase', () {
    late UpdateCartQuantityUseCase useCase;

    setUp(() {
      useCase = UpdateCartQuantityUseCase(mockRepository);
    });

    test('delegates to repository.updateQuantity and returns Right', () async {
      when(
        () => mockRepository.updateQuantity(productId: 1, quantity: 3),
      ).thenAnswer((_) async => const Right(null));
      final result = await useCase(productId: 1, quantity: 3);
      expect(result, const Right(null));
      verify(() => mockRepository.updateQuantity(productId: 1, quantity: 3)).called(1);
    });
  });

  group('UpdateCartPricesUseCase', () {
    late UpdateCartPricesUseCase useCase;

    setUp(() {
      useCase = UpdateCartPricesUseCase(mockRepository);
    });

    test('delegates to repository.updateProductPrices and returns Right', () async {
      when(
        () => mockRepository.updateProductPrices([tProduct]),
      ).thenAnswer((_) async => const Right(null));
      final result = await useCase([tProduct]);
      expect(result, const Right(null));
      verify(() => mockRepository.updateProductPrices([tProduct])).called(1);
    });
  });
}
