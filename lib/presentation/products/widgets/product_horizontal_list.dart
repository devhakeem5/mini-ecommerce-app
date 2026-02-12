import 'package:flutter/material.dart';

import '../../../domain/entities/product.dart';
import 'product_card.dart';

class ProductsHorizontalList extends StatelessWidget {
  final List<Product> products;
  final String heroTagPrefix;

  const ProductsHorizontalList({super.key, required this.products, this.heroTagPrefix = 'product'});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final heroTag = '${heroTagPrefix}_${product.id}';

          return SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ProductCard(product: product, heroTag: heroTag),
            ),
          );
        },
      ),
    );
  }
}
