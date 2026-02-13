import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/domain/entities/address.dart';
import 'package:mini_commerce_app/domain/entities/cart.dart';
import 'package:mini_commerce_app/domain/entities/cart_item.dart';
import 'package:mini_commerce_app/domain/entities/category.dart';
import 'package:mini_commerce_app/domain/entities/product.dart';
import 'package:mini_commerce_app/domain/entities/products_result.dart';
import 'package:mini_commerce_app/domain/entities/user.dart';

void main() {
  group('Product', () {
    const tProduct = Product(
      id: 1,
      title: 'Test',
      description: 'Desc',
      brand: 'Brand',
      category: 'Category',
      price: 200.0,
      discountPercentage: 10.0,
      rating: 4.5,
      thumbnail: 'url',
      images: ['img1', 'img2'],
      availabilityStatus: 'In Stock',
    );

    test('discountedPrice is calculated correctly', () {
      expect(tProduct.discountedPrice, 180.0);
    });

    test('discountedPrice with 0% discount returns full price', () {
      const product = Product(
        id: 2,
        title: 'No Discount',
        description: '',
        brand: '',
        category: '',
        price: 100.0,
        discountPercentage: 0.0,
        rating: 0,
        thumbnail: '',
        images: [],
        availabilityStatus: '',
      );
      expect(product.discountedPrice, 100.0);
    });

    test('discountedPrice with 50% discount', () {
      const product = Product(
        id: 3,
        title: 'Half Off',
        description: '',
        brand: '',
        category: '',
        price: 100.0,
        discountPercentage: 50.0,
        rating: 0,
        thumbnail: '',
        images: [],
        availabilityStatus: '',
      );
      expect(product.discountedPrice, 50.0);
    });

    test('Equatable: equal products are equal', () {
      const product2 = Product(
        id: 1,
        title: 'Test',
        description: 'Desc',
        brand: 'Brand',
        category: 'Category',
        price: 200.0,
        discountPercentage: 10.0,
        rating: 4.5,
        thumbnail: 'url',
        images: ['img1', 'img2'],
        availabilityStatus: 'In Stock',
      );
      expect(tProduct, equals(product2));
    });

    test('Equatable: different products are not equal', () {
      const product2 = Product(
        id: 2,
        title: 'Other',
        description: 'Desc',
        brand: 'Brand',
        category: 'Category',
        price: 200.0,
        discountPercentage: 10.0,
        rating: 4.5,
        thumbnail: 'url',
        images: [],
        availabilityStatus: 'In Stock',
      );
      expect(tProduct, isNot(equals(product2)));
    });
  });

  group('CartItem', () {
    const tProduct = Product(
      id: 1,
      title: 'Test',
      description: 'Desc',
      brand: 'Brand',
      category: 'Category',
      price: 100.0,
      discountPercentage: 20.0,
      rating: 4.0,
      thumbnail: 'url',
      images: [],
      availabilityStatus: 'In Stock',
    );

    final tCartItem = CartItem(product: tProduct, quantity: 3);

    test('totalPrice is price * quantity', () {
      expect(tCartItem.totalPrice, 300.0);
    });

    test('totalDiscountedPrice is discountedPrice * quantity', () {
      expect(tCartItem.totalDiscountedPrice, 240.0);
    });

    test('copyWith changes quantity', () {
      final updated = tCartItem.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.product, tProduct);
    });

    test('copyWith changes product', () {
      const newProduct = Product(
        id: 2,
        title: 'New',
        description: '',
        brand: '',
        category: '',
        price: 50.0,
        discountPercentage: 0,
        rating: 0,
        thumbnail: '',
        images: [],
        availabilityStatus: '',
      );
      final updated = tCartItem.copyWith(product: newProduct);
      expect(updated.product.id, 2);
      expect(updated.quantity, 3);
    });

    test('Equatable: same product and quantity are equal', () {
      final item2 = CartItem(product: tProduct, quantity: 3);
      expect(tCartItem, equals(item2));
    });
  });

  group('Cart', () {
    const tProduct1 = Product(
      id: 1,
      title: 'P1',
      description: '',
      brand: '',
      category: '',
      price: 100.0,
      discountPercentage: 10.0,
      rating: 0,
      thumbnail: '',
      images: [],
      availabilityStatus: '',
    );

    const tProduct2 = Product(
      id: 2,
      title: 'P2',
      description: '',
      brand: '',
      category: '',
      price: 200.0,
      discountPercentage: 50.0,
      rating: 0,
      thumbnail: '',
      images: [],
      availabilityStatus: '',
    );

    final tCart = Cart(
      items: [
        CartItem(product: tProduct1, quantity: 2),
        CartItem(product: tProduct2, quantity: 1),
      ],
    );

    test('itemCount sums all quantities', () {
      expect(tCart.itemCount, 3);
    });

    test('totalPrice sums price * quantity for all items', () {
      expect(tCart.totalPrice, 400.0);
    });

    test('totalDiscountedPrice sums discounted prices', () {
      final expected = (100.0 * 0.9 * 2) + (200.0 * 0.5 * 1);
      expect(tCart.totalDiscountedPrice, expected);
    });

    test('totalSavings is totalPrice - totalDiscountedPrice', () {
      expect(tCart.totalSavings, tCart.totalPrice - tCart.totalDiscountedPrice);
    });

    test('copyWith replaces items', () {
      final newCart = tCart.copyWith(items: []);
      expect(newCart.items, isEmpty);
    });

    test('copyWith without arguments keeps items', () {
      final newCart = tCart.copyWith();
      expect(newCart.items.length, 2);
    });

    test('empty cart has zero totals', () {
      const emptyCart = Cart(items: []);
      expect(emptyCart.itemCount, 0);
      expect(emptyCart.totalPrice, 0.0);
      expect(emptyCart.totalDiscountedPrice, 0.0);
      expect(emptyCart.totalSavings, 0.0);
    });
  });

  group('Category', () {
    test('fromString creates correct Category', () {
      final category = Category.fromString('electronics');
      expect(category.id, 'electronics');
      expect(category.name, 'Electronics');
      expect(category.slug, 'electronics');
    });

    test('fromString handles single character', () {
      final category = Category.fromString('a');
      expect(category.name, 'A');
    });

    test('capitalize on empty string returns empty', () {
      expect(''.capitalize(), '');
    });

    test('Equatable: same categories are equal', () {
      const cat1 = Category(id: '1', name: 'Test', slug: 'test');
      const cat2 = Category(id: '1', name: 'Test', slug: 'test');
      expect(cat1, equals(cat2));
    });
  });

  group('Address', () {
    const tAddress = Address(
      id: '1',
      label: 'Home',
      city: 'Riyadh',
      street: 'King Fahd Street',
      details: 'Building 5',
      isDefault: true,
    );

    test('fullAddress includes street, city and details', () {
      expect(tAddress.fullAddress, 'King Fahd Street, Riyadh - Building 5');
    });

    test('fullAddress without details omits dash', () {
      const address = Address(id: '2', label: 'Work', city: 'Jeddah', street: 'Main St');
      expect(address.fullAddress, 'Main St, Jeddah');
    });

    test('copyWith changes specific fields', () {
      final updated = tAddress.copyWith(city: 'Jeddah', isDefault: false);
      expect(updated.city, 'Jeddah');
      expect(updated.isDefault, false);
      expect(updated.label, 'Home');
      expect(updated.street, 'King Fahd Street');
    });

    test('copyWith without args returns identical', () {
      final updated = tAddress.copyWith();
      expect(updated.id, tAddress.id);
      expect(updated.label, tAddress.label);
    });
  });

  group('ProductsResult', () {
    test('stores products and isOffline flag', () {
      const result = ProductsResult(products: [], isOffline: true);
      expect(result.products, isEmpty);
      expect(result.isOffline, true);
    });

    test('stores products list correctly', () {
      const product = Product(
        id: 1,
        title: 'P',
        description: '',
        brand: '',
        category: '',
        price: 10,
        discountPercentage: 0,
        rating: 0,
        thumbnail: '',
        images: [],
        availabilityStatus: '',
      );
      const result = ProductsResult(products: [product], isOffline: false);
      expect(result.products.length, 1);
      expect(result.isOffline, false);
    });
  });

  group('User', () {
    test('Equatable: same users are equal', () {
      const user1 = User(id: '1', name: 'Ali', email: 'a@b.com');
      const user2 = User(id: '1', name: 'Ali', email: 'a@b.com');
      expect(user1, equals(user2));
    });

    test('Equatable: different users are not equal', () {
      const user1 = User(id: '1', name: 'Ali', email: 'a@b.com');
      const user2 = User(id: '2', name: 'Omar', email: 'o@b.com');
      expect(user1, isNot(equals(user2)));
    });

    test('optional fields default to null', () {
      const user = User(id: '1', name: 'Ali', email: 'a@b.com');
      expect(user.avatarUrl, isNull);
      expect(user.role, isNull);
    });

    test('optional fields can be set', () {
      const user = User(
        id: '1',
        name: 'Ali',
        email: 'a@b.com',
        avatarUrl: 'http://img.com/a.png',
        role: 'admin',
      );
      expect(user.avatarUrl, 'http://img.com/a.png');
      expect(user.role, 'admin');
    });
  });
}
