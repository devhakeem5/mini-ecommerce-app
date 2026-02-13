import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_commerce_app/core/localization/app_localizations.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../domain/usecases/products/get_product_options_usecase.dart';
import '../../../data/models/product_option_config.dart';
import '../../../domain/entities/product.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/pages/cart_page.dart';
import '../../common/visual_cart/visual_cart_controller.dart';
import '../../common/visual_cart/visual_cart_overlay.dart';
import '../widgets/details_image_gallery.dart';
import '../widgets/product_action_tile.dart';
import '../widgets/product_bottom_bar.dart';
import '../widgets/product_info_row.dart';
import '../widgets/product_options_widget.dart';
import '../widgets/related_products_section.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final String? heroTag;

  const ProductDetailsPage({super.key, required this.product, this.heroTag});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  int _selectedOptionIndex = 0;
  late final ProductOptionConfig _optionConfig;
  late double _currentPrice;
  bool _isFavorite = false;
  late final AnimationController _fadeController;
  final VisualCartControllerState _visualCartController = VisualCartControllerState();
  final GlobalKey _productImageKey = GlobalKey();
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _optionConfig = sl<GetProductOptionsUseCase>()(widget.product.category);
    _currentPrice = widget.product.price;
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _visualCartController.dispose();
    super.dispose();
  }

  void _onOptionSelected(int index) {
    setState(() {
      _selectedOptionIndex = index;
      if (_optionConfig.priceModifiers.isNotEmpty && index < _optionConfig.priceModifiers.length) {
        _currentPrice = widget.product.price * (1 + _optionConfig.priceModifiers[index]);
      } else {
        _currentPrice = widget.product.price;
      }
    });
  }

  bool get _canAddToCart => widget.product.availabilityStatus.toLowerCase() != 'out of stock';

  Color get _statusColor {
    final status = widget.product.availabilityStatus;
    if (status == 'In Stock') return Colors.green;
    if (status == 'Low Stock') return Colors.orange;
    return Colors.red;
  }

  int get _reviewCount {
    final rng = Random(widget.product.id);
    return 50 + rng.nextInt(450);
  }

  double get _originalPrice {
    final dp = widget.product.discountPercentage;
    if (dp <= 0) return _currentPrice;
    return _currentPrice / (1 - dp / 100);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    return VisualCartController(
      state: _visualCartController,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: Text(
                product.title,
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.shopping_bag_outlined, color: textColor),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: FadeTransition(opacity: _fadeAnimation, child: _buildBody(product, theme)),
            bottomNavigationBar: ProductBottomBar(
              isFavorite: _isFavorite,
              canAddToCart: _canAddToCart,
              onFavoriteToggle: () => setState(() => _isFavorite = !_isFavorite),
              onAddToCart: () {
                context.read<CartCubit>().addToCart(widget.product);
                final renderBox = _productImageKey.currentContext?.findRenderObject() as RenderBox?;
                if (renderBox != null && renderBox.hasSize) {
                  final position = renderBox.localToGlobal(Offset.zero);
                  final center =
                      position + Offset(renderBox.size.width / 2, renderBox.size.height / 2);
                  _visualCartController.addProduct(widget.product.thumbnail, center);
                }
              },
            ),
          ),
          VisualCartOverlay(controller: _visualCartController),
        ],
      ),
    );
  }

  Widget _buildBody(Product product, ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            key: _productImageKey,
            child: DetailsImageGallery(
              images: product.images.isNotEmpty ? product.images : [product.thumbnail],
              heroTag: widget.heroTag,
              currentIndex: _currentImageIndex,
              onPageChanged: (i) => setState(() => _currentImageIndex = i),
              primaryColor: theme.primaryColor,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.brand.isNotEmpty && product.brand.toLowerCase() != 'no brand')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      product.brand.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                Text(
                  product.title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                    const SizedBox(width: 4),
                    Text(
                      '(${product.rating})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($_reviewCount ${context.tr('reviews')})',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildPriceRow(product),
                const SizedBox(height: 24),

                ProductOptionsWidget(
                  config: _optionConfig,
                  selectedIndex: _selectedOptionIndex,
                  onOptionSelected: _onOptionSelected,
                ),
                const SizedBox(height: 24),

                ProductInfoRow(
                  icon: _canAddToCart ? Icons.check_circle_outline : Icons.cancel_outlined,
                  text: product.availabilityStatus,
                  color: _statusColor,
                ),
                const SizedBox(height: 8),
                ProductInfoRow(
                  icon: Icons.local_shipping_outlined,
                  text: context.tr('free_delivery'),
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey,
                ),
                const SizedBox(height: 8),
                ProductInfoRow(
                  icon: Icons.store_outlined,
                  text: context.tr('nearest_store'),
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey,
                ),
                const SizedBox(height: 24),

                Text(
                  context.tr('description'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                ProductActionTile(
                  title: context.tr('description'),
                  theme: theme,
                  onTap: () => _showDescriptionSheet(product, theme),
                ),
                const SizedBox(height: 12),
                ProductActionTile(title: context.tr('ingredients'), theme: theme),
                const SizedBox(height: 12),
                ProductActionTile(title: context.tr('how_to_use'), theme: theme),

                const SizedBox(height: 16),
              ],
            ),
          ),

          RelatedProductsSection(product: product),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showDescriptionSheet(Product product, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('description'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: theme.textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                          height: 1.7,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPriceRow(Product product) {
    final hasDiscount = product.discountPercentage > 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '\$${_currentPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 10),
          Text(
            '\$${_originalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade400,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(100),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '-${product.discountPercentage.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green),
            ),
          ),
        ],
      ],
    );
  }
}
