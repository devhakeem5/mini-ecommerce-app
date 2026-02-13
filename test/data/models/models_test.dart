import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/data/models/address_model.dart';
import 'package:mini_commerce_app/data/models/cart_item_model.dart';
import 'package:mini_commerce_app/data/models/product_model.dart';
import 'package:mini_commerce_app/data/models/user_model.dart';
import 'package:mini_commerce_app/domain/entities/address.dart';
import 'package:mini_commerce_app/domain/entities/cart_item.dart';
import 'package:mini_commerce_app/domain/entities/product.dart';

void main() {
  group('ProductModel', () {
    const tJson = {
      'id': 1,
      'title': 'Test Product',
      'description': 'A great product',
      'brand': 'TestBrand',
      'category': 'electronics',
      'price': 99.99,
      'discountPercentage': 10.0,
      'rating': 4.5,
      'thumbnail': 'http://img.com/thumb.jpg',
      'images': ['http://img.com/1.jpg', 'http://img.com/2.jpg'],
      'availabilityStatus': 'In Stock',
    };

    test('fromJson creates correct ProductModel', () {
      final model = ProductModel.fromJson(tJson);

      expect(model.id, 1);
      expect(model.title, 'Test Product');
      expect(model.description, 'A great product');
      expect(model.brand, 'TestBrand');
      expect(model.category, 'electronics');
      expect(model.price, 99.99);
      expect(model.discountPercentage, 10.0);
      expect(model.rating, 4.5);
      expect(model.thumbnail, 'http://img.com/thumb.jpg');
      expect(model.images.length, 2);
      expect(model.availabilityStatus, 'In Stock');
    });

    test('fromJson handles null/missing fields with defaults', () {
      final model = ProductModel.fromJson({});

      expect(model.id, 0);
      expect(model.title, 'No Title');
      expect(model.description, '');
      expect(model.brand, 'No Brand');
      expect(model.category, 'Uncategorized');
      expect(model.price, 0.0);
      expect(model.discountPercentage, 0.0);
      expect(model.rating, 0.0);
      expect(model.thumbnail, '');
      expect(model.images, isEmpty);
      expect(model.availabilityStatus, 'In Stock');
    });

    test('fromJson handles partial data', () {
      final model = ProductModel.fromJson({'id': 5, 'title': 'Partial', 'price': 50});

      expect(model.id, 5);
      expect(model.title, 'Partial');
      expect(model.price, 50.0);
      expect(model.brand, 'No Brand');
    });

    test('toEntity returns correct Product', () {
      final model = ProductModel.fromJson(tJson);
      final entity = model.toEntity();

      expect(entity, isA<Product>());
      expect(entity.id, model.id);
      expect(entity.title, model.title);
      expect(entity.price, model.price);
      expect(entity.discountPercentage, model.discountPercentage);
      expect(entity.images.length, model.images.length);
    });

    test('Equatable: same models are equal', () {
      final model1 = ProductModel.fromJson(tJson);
      final model2 = ProductModel.fromJson(tJson);
      expect(model1, equals(model2));
    });

    test('Equatable: different models are not equal', () {
      final model1 = ProductModel.fromJson(tJson);
      final model2 = ProductModel.fromJson({...tJson, 'id': 99});
      expect(model1, isNot(equals(model2)));
    });
  });

  group('CartItemModel', () {
    const tProductModel = ProductModel(
      id: 1,
      title: 'Test',
      description: 'Desc',
      brand: 'Brand',
      category: 'Cat',
      price: 100.0,
      discountPercentage: 10.0,
      rating: 4.0,
      thumbnail: 'url',
      images: [],
      availabilityStatus: 'In Stock',
    );

    const tCartItemModel = CartItemModel(product: tProductModel, quantity: 2);

    test('toEntity returns correct CartItem', () {
      final entity = tCartItemModel.toEntity();

      expect(entity, isA<CartItem>());
      expect(entity.product.id, 1);
      expect(entity.quantity, 2);
    });

    test('fromEntity creates correct CartItemModel', () {
      const tProduct = Product(
        id: 1,
        title: 'Test',
        description: 'Desc',
        brand: 'Brand',
        category: 'Cat',
        price: 100.0,
        discountPercentage: 10.0,
        rating: 4.0,
        thumbnail: 'url',
        images: [],
        availabilityStatus: 'In Stock',
      );
      final entity = CartItem(product: tProduct, quantity: 3);

      final model = CartItemModel.fromEntity(entity);

      expect(model.product.id, 1);
      expect(model.quantity, 3);
      expect(model.product.title, 'Test');
    });

    test('toEntity and fromEntity round-trip preserves data', () {
      const tProduct = Product(
        id: 5,
        title: 'Round Trip',
        description: 'Test',
        brand: 'B',
        category: 'C',
        price: 200.0,
        discountPercentage: 15.0,
        rating: 3.5,
        thumbnail: 'thumb',
        images: ['a', 'b'],
        availabilityStatus: 'Low Stock',
      );
      final entity = CartItem(product: tProduct, quantity: 4);
      final model = CartItemModel.fromEntity(entity);
      final backToEntity = model.toEntity();

      expect(backToEntity.product.id, entity.product.id);
      expect(backToEntity.product.price, entity.product.price);
      expect(backToEntity.quantity, entity.quantity);
    });

    test('copyWith changes quantity', () {
      final updated = tCartItemModel.copyWith(quantity: 10);
      expect(updated.quantity, 10);
      expect(updated.product, tProductModel);
    });

    test('copyWith changes product', () {
      const newProduct = ProductModel(
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
      final updated = tCartItemModel.copyWith(product: newProduct);
      expect(updated.product.id, 2);
      expect(updated.quantity, 2);
    });
  });

  group('AddressModel', () {
    const tJson = {
      'id': '1',
      'label': 'Home',
      'city': 'Riyadh',
      'street': 'Main St',
      'details': 'Apt 5',
      'isDefault': true,
    };

    test('fromJson creates correct model', () {
      final model = AddressModel.fromJson(tJson);

      expect(model.id, '1');
      expect(model.label, 'Home');
      expect(model.city, 'Riyadh');
      expect(model.street, 'Main St');
      expect(model.details, 'Apt 5');
      expect(model.isDefault, true);
    });

    test('fromJson handles optional fields with defaults', () {
      final model = AddressModel.fromJson({
        'id': '2',
        'label': 'Work',
        'city': 'Jeddah',
        'street': 'King St',
      });

      expect(model.details, '');
      expect(model.isDefault, false);
    });

    test('toJson returns correct map', () {
      final model = AddressModel.fromJson(tJson);
      final json = model.toJson();

      expect(json['id'], '1');
      expect(json['label'], 'Home');
      expect(json['isDefault'], true);
    });

    test('toEntity returns correct Address', () {
      final model = AddressModel.fromJson(tJson);
      final entity = model.toEntity();

      expect(entity, isA<Address>());
      expect(entity.id, '1');
      expect(entity.city, 'Riyadh');
      expect(entity.isDefault, true);
    });

    test('fromEntity creates correct model', () {
      const address = Address(
        id: '3',
        label: 'Office',
        city: 'Dammam',
        street: 'Industrial St',
        details: 'Floor 2',
        isDefault: false,
      );

      final model = AddressModel.fromEntity(address);

      expect(model.id, '3');
      expect(model.label, 'Office');
      expect(model.details, 'Floor 2');
    });

    test('round-trip: fromJson → toJson preserves data', () {
      final model = AddressModel.fromJson(tJson);
      final json = model.toJson();
      final model2 = AddressModel.fromJson(json);

      expect(model2.id, model.id);
      expect(model2.label, model.label);
      expect(model2.city, model.city);
    });
  });

  group('UserModel', () {
    test('fromJson creates correct UserModel', () {
      final model = UserModel.fromJson({
        'id': 'u1',
        'name': 'Ali',
        'email': 'ali@test.com',
        'avatar_url': 'http://img.com/a.png',
        'role': 'admin',
      });

      expect(model.id, 'u1');
      expect(model.name, 'Ali');
      expect(model.email, 'ali@test.com');
      expect(model.avatarUrl, 'http://img.com/a.png');
      expect(model.role, 'admin');
    });

    test('fromJson handles null optional fields', () {
      final model = UserModel.fromJson({'id': 'u2', 'name': 'Omar', 'email': 'omar@test.com'});

      expect(model.avatarUrl, isNull);
      expect(model.role, isNull);
    });

    test('toJson returns correct map', () {
      const model = UserModel(
        id: 'u1',
        name: 'Ali',
        email: 'ali@test.com',
        avatarUrl: 'http://img.com/a.png',
        role: 'admin',
      );
      final json = model.toJson();

      expect(json['id'], 'u1');
      expect(json['name'], 'Ali');
      expect(json['avatar_url'], 'http://img.com/a.png');
    });

    test('round-trip: fromJson → toJson → fromJson preserves data', () {
      final original = UserModel.fromJson({
        'id': 'u1',
        'name': 'Ali',
        'email': 'ali@test.com',
        'avatar_url': 'http://img.com/a.png',
        'role': 'admin',
      });
      final json = original.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.email, original.email);
      expect(restored.avatarUrl, original.avatarUrl);
      expect(restored.role, original.role);
    });
  });
}
