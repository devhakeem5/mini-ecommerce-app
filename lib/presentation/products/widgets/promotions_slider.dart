import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_commerce_app/core/localization/app_localizations.dart';
import 'package:mini_commerce_app/presentation/common/widgets/offline_section_widget.dart';

import '/presentation/common/widgets/custom_cached_image.dart';
import '/presentation/products/cubit/promotions_cubit.dart';
import '/presentation/products/cubit/promotions_state.dart';
import '/presentation/products/pages/product_details_page.dart';
import '../../common/widgets/skeleton_loaders.dart';

class PromotionsSlider extends StatelessWidget {
  const PromotionsSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PromotionsCubit, PromotionsState>(
      builder: (context, state) {
        if (state is PromotionsLoading) {
          return _buildLoading();
        }

        if (state is PromotionsLoaded) {
          final products = state.products;

          if (products.isEmpty) {
            if (state.isOffline) {
              return const OfflineSectionWidget(title: 'Promotions');
            }
            return const SizedBox.shrink();
          }

          return SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final discount = product.discountPercentage > 0
                    ? product.discountPercentage.round()
                    : 5;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailsPage(product: product, heroTag: 'promo_${product.id}'),
                      ),
                    );
                  },
                  child: Container(
                    width: 340,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product.brand.isNotEmpty &&
                                      product.brand.toLowerCase() != 'no brand')
                                    Text(
                                      product.brand.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    product.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      minimumSize: const Size(0, 36),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailsPage(
                                            product: product,
                                            heroTag: 'promo_btn_${product.id}',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      '$discount% OFF | ${context.tr('buy_now')}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: Hero(
                                tag: 'promo_${product.id}',
                                child: Container(
                                  height: 120,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: CustomCachedImage(
                                    imageUrl: product.thumbnail,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }

        if (state is PromotionsError) {
          if (state.message == 'no_internet_no_data') {
            return OfflineSectionWidget(title: 'Promotions');
          }
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoading() {
    return const PromotionSkeleton();
  }
}
