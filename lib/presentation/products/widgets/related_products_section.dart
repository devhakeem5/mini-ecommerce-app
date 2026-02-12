import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_commerce_app/core/localization/app_localizations.dart';

import '../../../domain/entities/product.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';
import 'product_card.dart';

class RelatedProductsSection extends StatelessWidget {
  final Product product;

  const RelatedProductsSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        if (state is! ProductsLoaded) return const SizedBox.shrink();

        final allProducts = state.products;

        List<Product> related = [];
        if (product.brand.isNotEmpty && product.brand.toLowerCase() != 'no brand') {
          related = allProducts
              .where(
                (p) => p.id != product.id && p.brand.toLowerCase() == product.brand.toLowerCase(),
              )
              .toList();
        }

        if (related.isEmpty) {
          related = allProducts
              .where(
                (p) =>
                    p.id != product.id &&
                    p.category.toLowerCase() == product.category.toLowerCase(),
              )
              .toList();
        }

        if (related.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                context.tr('related_products'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: related.length > 10 ? 10 : related.length,
                itemBuilder: (context, i) {
                  final p = related[i];
                  return SizedBox(
                    width: 200,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ProductCard(product: p, heroTag: 'related_${p.id}'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
