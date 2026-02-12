import 'package:mini_commerce_app/domain/entities/product.dart';

class ProductsResult {
  final List<Product> products;
  final bool isOffline;

  const ProductsResult({
    required this.products,
    required this.isOffline,
  });
}
