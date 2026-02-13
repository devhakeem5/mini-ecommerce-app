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
    test('should add item to cart', () async {
      when(() => mockLocalDataSource.loadCart()).thenAnswer((_) async => []);
      when(() => mockLocalDataSource.saveCart(any())).thenAnswer((_) async {});

      await repository.addToCart(tProduct);

      verify(() => mockLocalDataSource.loadCart()).called(1);
      verify(() => mockLocalDataSource.saveCart(any())).called(1);
    });

    test('should load cart items', () async {
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

      expect(result.length, 1);
      expect(result.first.product.id, tProduct.id);
      expect(result.first.quantity, 1);
    });

    test('should return empty list when cart is empty', () async {
      when(() => mockLocalDataSource.loadCart()).thenAnswer((_) async => []);

      final result = await repository.loadCart();

      expect(result, isEmpty);
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
      when(() => mockLocalDataSource.saveCart(any())).thenAnswer((_) async {});

      await repository.addToCart(tProduct);

      final captured =
          verify(() => mockLocalDataSource.saveCart(captureAny())).captured.single as List;
      expect(captured.length, 1);
      expect(captured.first['quantity'], 2);
    });

    test('should update quantity for existing item', () async {
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
      when(() => mockLocalDataSource.saveCart(any())).thenAnswer((_) async {});

      await repository.updateQuantity(productId: 1, quantity: 5);

      final captured =
          verify(() => mockLocalDataSource.saveCart(captureAny())).captured.single as List;
      expect(captured.first['quantity'], 5);
    });

    test('should remove item from cart', () async {
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
      when(() => mockLocalDataSource.saveCart(any())).thenAnswer((_) async {});

      await repository.removeFromCart(1);

      final captured =
          verify(() => mockLocalDataSource.saveCart(captureAny())).captured.single as List;
      expect(captured, isEmpty);
    });

    test('should clear cart', () async {
      when(() => mockLocalDataSource.clearCart()).thenAnswer((_) async {});

      await repository.clearCart();

      verify(() => mockLocalDataSource.clearCart()).called(1);
    });
  });
}
