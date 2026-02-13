import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/data/datasources/local/cart_local_data_source.dart';
import 'package:mini_commerce_app/data/repositories/cart_repository_impl.dart';
import 'package:mini_commerce_app/domain/entities/product.dart';
import 'package:mocktail/mocktail.dart';

class MockCartLocalDataSource extends Mock implements CartLocalDataSource {}

void main() {
  late CartRepositoryImpl repository;
  late MockCartLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockCartLocalDataSource();
    repository = CartRepositoryImpl(localDataSource: mockLocalDataSource);
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

  group('CartRepositoryImpl', () {
    test('should add item to cart and return Right', () async {
      when(() => mockLocalDataSource.loadCart()).thenAnswer((_) async => []);
      when(() => mockLocalDataSource.saveCartItem(any())).thenAnswer((_) async {});

      final result = await repository.addToCart(tProduct);

      expect(result, const Right(null));
      verify(() => mockLocalDataSource.loadCart()).called(1);
      verify(() => mockLocalDataSource.saveCartItem(any())).called(1);
    });

    test('should load cart items and return Right', () async {
      final tCartMap = {
        'product': {
          'id': 1,
          'title': 'Test Product',
          'description': 'Desc',
          'brand': 'Brand',
          'category': 'Category',
          'price': 100.0,
          'discountPercentage': 0.0,
          'rating': 4.5,
          'thumbnail': 'url',
          'images': [],
          'availabilityStatus': 'In Stock',
        },
        'quantity': 1,
      };
      when(() => mockLocalDataSource.loadCart()).thenAnswer((_) async => [tCartMap]);

      final result = await repository.loadCart();

      result.fold((failure) => fail('Expected Right but got Left: $failure'), (items) {
        expect(items.length, 1);
        expect(items.first.product.id, tProduct.id);
        expect(items.first.quantity, 1);
      });
    });

    test('should return Right with empty list when cart is empty', () async {
      when(() => mockLocalDataSource.loadCart()).thenAnswer((_) async => []);

      final result = await repository.loadCart();

      result.fold(
        (failure) => fail('Expected Right but got Left: $failure'),
        (items) => expect(items, isEmpty),
      );
    });

    test('should increment quantity when adding existing product', () async {
      final tExistingCartMap = {
        'product': {
          'id': 1,
          'title': 'Test Product',
          'description': 'Desc',
          'brand': 'Brand',
          'category': 'Category',
          'price': 100.0,
          'discountPercentage': 0.0,
          'rating': 4.5,
          'thumbnail': 'url',
          'images': [],
          'availabilityStatus': 'In Stock',
        },
        'quantity': 1,
      };
      when(() => mockLocalDataSource.loadCart()).thenAnswer((_) async => [tExistingCartMap]);
      when(() => mockLocalDataSource.saveCartItem(any())).thenAnswer((_) async {});

      final result = await repository.addToCart(tProduct);

      expect(result, const Right(null));
      final captured =
          verify(() => mockLocalDataSource.saveCartItem(captureAny())).captured.single as Map;
      expect(captured['quantity'], 2);
    });

    test('should update quantity for existing item and return Right', () async {
      final tCartMap = {
        'product': {
          'id': 1,
          'title': 'Test Product',
          'description': 'Desc',
          'brand': 'Brand',
          'category': 'Category',
          'price': 100.0,
          'discountPercentage': 0.0,
          'rating': 4.5,
          'thumbnail': 'url',
          'images': [],
          'availabilityStatus': 'In Stock',
        },
        'quantity': 1,
      };
      when(() => mockLocalDataSource.loadCart()).thenAnswer((_) async => [tCartMap]);
      when(() => mockLocalDataSource.saveCartItem(any())).thenAnswer((_) async {});

      final result = await repository.updateQuantity(productId: 1, quantity: 5);

      expect(result, const Right(null));
      final captured =
          verify(() => mockLocalDataSource.saveCartItem(captureAny())).captured.single as Map;
      expect(captured['quantity'], 5);
    });

    test('should remove item from cart and return Right', () async {
      when(() => mockLocalDataSource.removeCartItem(any())).thenAnswer((_) async {});

      final result = await repository.removeFromCart(1);

      expect(result, const Right(null));
      verify(() => mockLocalDataSource.removeCartItem(1)).called(1);
    });

    test('should clear cart and return Right', () async {
      when(() => mockLocalDataSource.clearCart()).thenAnswer((_) async {});

      final result = await repository.clearCart();

      expect(result, const Right(null));
      verify(() => mockLocalDataSource.clearCart()).called(1);
    });

    test('should return Left when loadCart throws', () async {
      when(() => mockLocalDataSource.loadCart()).thenThrow(Exception('DB error'));

      final result = await repository.loadCart();

      expect(result.isLeft(), true);
    });
  });
}
