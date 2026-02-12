import 'package:mini_commerce_app/data/models/product_model.dart';
import 'package:mini_commerce_app/domain/entities/cart_item.dart';

class CartItemModel {
  final ProductModel product;
  final int quantity;

  const CartItemModel({required this.product, required this.quantity});

  CartItemModel copyWith({ProductModel? product, int? quantity}) {
    return CartItemModel(product: product ?? this.product, quantity: quantity ?? this.quantity);
  }

  CartItem toEntity() {
    return CartItem(product: product.toEntity(), quantity: quantity);
  }

  factory CartItemModel.fromEntity(CartItem entity) {
    return CartItemModel(
      product: ProductModel(
        id: entity.product.id,
        title: entity.product.title,
        description: entity.product.description,
        brand: entity.product.brand,
        category: entity.product.category,
        price: entity.product.price,
        discountPercentage: entity.product.discountPercentage,
        rating: entity.product.rating,
        thumbnail: entity.product.thumbnail,
        images: entity.product.images,
        availabilityStatus: entity.product.availabilityStatus,
      ),
      quantity: entity.quantity,
    );
  }
}
