import '../../entities/product.dart';

class FilterRelatedProductsUseCase {
  List<Product> call(Product product, List<Product> allProducts) {
    List<Product> related = [];
    if (product.brand.isNotEmpty && product.brand.toLowerCase() != 'no brand') {
      related = allProducts
          .where((p) => p.id != product.id && p.brand.toLowerCase() == product.brand.toLowerCase())
          .toList();
    }

    if (related.isEmpty) {
      related = allProducts
          .where(
            (p) => p.id != product.id && p.category.toLowerCase() == product.category.toLowerCase(),
          )
          .toList();
    }
    return related;
  }
}
