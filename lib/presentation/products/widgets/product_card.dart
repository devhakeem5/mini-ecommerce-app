import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_commerce_app/core/localization/app_localizations.dart';

import '../../../domain/entities/product.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../common/fly_to_cart/fly_to_cart_controller.dart';
import '../../common/visual_cart/visual_cart_controller.dart';
import '../../common/widgets/custom_cached_image.dart';
import '../../common/widgets/custom_toast.dart';
import '../pages/product_details_page.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final String? heroTag;

  const ProductCard({super.key, required this.product, this.onTap, this.heroTag});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isFavorite = false;
  final GlobalKey _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final product = widget.product;
    final isLimited = [7, 12, 15].contains(product.id);
    final heroTag = widget.heroTag ?? 'product_${product.id}';

    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsPage(product: product, heroTag: heroTag),
              ),
            );
          },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: heroTag,
                  child: Container(
                    key: _imageKey,
                    height: 180,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomCachedImage(imageUrl: product.thumbnail, fit: BoxFit.contain),
                    ),
                  ),
                ),
                if (isLimited)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.tr('limited_edition'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                    },
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.lightGreen : Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              margin: EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The Ordinary',
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w400),
                  ),
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product.price}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _onAddToCart(context, product),
                          child: Container(
                            height: 36,
                            width: 36,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? theme.primaryColor : Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              color: isDark ? Colors.black : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddToCart(BuildContext context, Product product) {
    if (product.availabilityStatus.toLowerCase() == 'out of stock') {
      CustomToast.show(context, message: context.tr('out_of_stock_msg'), type: ToastType.error);
      return;
    }

    context.read<CartCubit>().addToCart(product);

    final controllerState = FlyToCartController.maybeOf(context);
    if (controllerState != null) {
      final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        final center = position + Offset(renderBox.size.width / 2, renderBox.size.height / 2);

        controllerState.addFlyingItem(
          FlyingItem(
            imageUrl: product.thumbnail,
            startPosition: center,
            id: '${product.id}_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
      }
    }

    final visualCart = VisualCartController.maybeOf(context);
    if (visualCart != null) {
      final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        final center = position + Offset(renderBox.size.width / 2, renderBox.size.height / 2);
        visualCart.addProduct(product.thumbnail, center);
      }
    }
  }

  VoidCallback? get onTap => widget.onTap;
}
