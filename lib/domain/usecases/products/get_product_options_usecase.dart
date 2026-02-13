import '../../../data/models/product_option_config.dart';

class GetProductOptionsUseCase {
  ProductOptionConfig call(String category) {
    final c = category.toLowerCase();
    if (c == 'womens-dresses' || c == 'mens-shirts') {
      return ProductOptionConfig(label: 'Size', values: ['S', 'M', 'L', 'XL']);
    } else if (c == 'womens-shoes') {
      return ProductOptionConfig(label: 'Size', values: ['39', '40', '41', '42']);
    } else if (c == 'fragrances') {
      return ProductOptionConfig(label: 'Size', values: ['50ml', '100ml', '120ml']);
    } else if (c == 'furniture') {
      return ProductOptionConfig(label: 'Size', values: ['Small', 'Big']);
    } else if (c == 'laptops') {
      return ProductOptionConfig(
        label: 'RAM',
        values: ['16GB', '32GB', '64GB'],
        priceModifiers: [0.0, 0.05, 0.10],
      );
    } else if (c == 'smartphones' || c == 'tablets') {
      return ProductOptionConfig(
        label: 'Storage',
        values: ['32GB', '64GB', '128GB', '256GB'],
        priceModifiers: [0.0, 0.05, 0.10, 0.15],
      );
    } else {
      return ProductOptionConfig(label: 'Size', values: ['Small', 'Big']);
    }
  }
}
