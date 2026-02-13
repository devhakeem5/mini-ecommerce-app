import '../../entities/product.dart';

class FilterRecommendedProductsUseCase {
  List<Product> call(List<Product> products) {
    return products.skip(6).take(6).toList();
  }
}
