import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_commerce_app/core/di/service_locator.dart';
import 'package:mini_commerce_app/core/util/responsive.dart';
import 'package:mini_commerce_app/presentation/cart/cubit/cart_cubit.dart';
import 'package:mini_commerce_app/presentation/common/visual_cart/visual_cart_controller.dart';
import 'package:mini_commerce_app/presentation/common/visual_cart/visual_cart_overlay.dart';
import 'package:mini_commerce_app/presentation/common/widgets/custom_error_widget.dart';
import 'package:mini_commerce_app/presentation/common/widgets/empty_widget.dart';
import 'package:mini_commerce_app/presentation/common/widgets/entrance_animation.dart';
import 'package:mini_commerce_app/presentation/products/cubit/product_list_cubit.dart';
import 'package:mini_commerce_app/presentation/products/cubit/product_list_state.dart';
import 'package:mini_commerce_app/presentation/products/widgets/product_card.dart';

import '/core/localization/app_localizations.dart';
import '../../../core/network/connectivity_cubit.dart';
import '../../../core/network/connectivity_state.dart';
import '../../common/widgets/offline_indicator.dart';
import '../../common/widgets/offline_widget.dart';
import '../../common/widgets/skeleton_loaders.dart';

class AllProductsPage extends StatefulWidget {
  final String? category;
  final String? title;

  const AllProductsPage({super.key, this.category, this.title});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  late final ProductListCubit _cubit;
  final ScrollController _scrollController = ScrollController();
  final VisualCartControllerState _visualCartController = VisualCartControllerState();

  @override
  void initState() {
    super.initState();
    _cubit = sl<ProductListCubit>()..loadInitial(category: widget.category);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    _visualCartController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final currentState = _cubit.state;
      if (currentState is ProductListLoaded && currentState.hasReachedMax) return;
      _cubit.loadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: VisualCartController(
        state: _visualCartController,
        child: Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: Text(widget.title ?? (widget.category ?? context.tr('all_products'))),
              ),
              body: MultiBlocListener(
                listeners: [
                  BlocListener<ProductListCubit, ProductListState>(
                    listener: (context, state) {
                      if (state is ProductListLoaded) {
                        context.read<CartCubit>().syncPrices(state.products);
                      }
                    },
                  ),
                  BlocListener<ConnectivityCubit, ConnectivityState>(
                    listenWhen: (previous, current) =>
                        previous is ConnectivityOffline && current is ConnectivityOnline,
                    listener: (context, connState) {
                      final listState = _cubit.state;
                      if (listState is ProductListLoaded && listState.loadMoreError != null) {
                        _cubit.loadMore();
                      }
                    },
                  ),
                ],
                child: Column(
                  children: [
                    BlocBuilder<ConnectivityCubit, ConnectivityState>(
                      builder: (context, connState) {
                        final listState = context.watch<ProductListCubit>().state;
                        final hasProducts =
                            listState is ProductListLoaded && listState.products.isNotEmpty;
                        if (connState is ConnectivityOffline && hasProducts) {
                          return const OfflineIndicator();
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: BlocBuilder<ProductListCubit, ProductListState>(
                            builder: (context, state) {
                              if (state is ProductListLoading) {
                                return ProductGridSkeleton(
                                  crossAxisCount: context.responsiveValue(
                                    mobile: 2,
                                    tablet: 3,
                                    desktop: 4,
                                  ),
                                );
                              }

                              if (state is ProductListError) {
                                final isOffline =
                                    context.read<ConnectivityCubit>().state is ConnectivityOffline;
                                if (isOffline || state.message.toLowerCase().contains('internet')) {
                                  return OfflineWidget(
                                    onRetry: () => _cubit.loadInitial(category: widget.category),
                                  );
                                }

                                return CustomErrorWidget(
                                  title: context.tr('retry'),
                                  message: context.tr(state.message),
                                  onRetry: () => _cubit.loadInitial(category: widget.category),
                                );
                              }

                              if (state is ProductListLoaded) {
                                if (state.products.isEmpty) {
                                  final isActuallyOffline =
                                      context.read<ConnectivityCubit>().state
                                          is ConnectivityOffline;
                                  if (isActuallyOffline) {
                                    return OfflineWidget(
                                      onRetry: () => _cubit.loadInitial(category: widget.category),
                                    );
                                  }

                                  // If we are online but products are empty AND it's from cache (isOffline: true),
                                  // it means we haven't received remote results yet. Keep showing loading/skeleton.
                                  if (state.isOffline) {
                                    return ProductGridSkeleton(
                                      crossAxisCount: context.responsiveValue(
                                        mobile: 2,
                                        tablet: 3,
                                        desktop: 4,
                                      ),
                                    );
                                  }
                                  return EmptyWidget(title: context.tr('all_products'));
                                }

                                return CustomScrollView(
                                  controller: _scrollController,
                                  slivers: [
                                    SliverPadding(
                                      padding: const EdgeInsets.all(16),
                                      sliver: SliverGrid(
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: context.responsiveValue(
                                            mobile: 2,
                                            tablet: 3,
                                            desktop: 4,
                                          ),
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8,
                                          childAspectRatio: context.responsiveValue(
                                            mobile: 0.65,
                                            tablet: 0.75,
                                            desktop: 0.8,
                                          ),
                                        ),
                                        delegate: SliverChildBuilderDelegate((context, index) {
                                          final product = state.products[index];
                                          return EntranceAnimation(
                                            index: index,
                                            child: ProductCard(
                                              product: product,
                                              heroTag: 'all_products_${product.id}',
                                            ),
                                          );
                                        }, childCount: state.products.length),
                                      ),
                                    ),
                                    if (state.loadMoreError != null)
                                      SliverToBoxAdapter(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Center(
                                            child: Column(
                                              children: [
                                                Text(
                                                  context.tr(state.loadMoreError!),
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.error,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextButton.icon(
                                                  onPressed: () => _cubit.loadMore(),
                                                  icon: const Icon(Icons.refresh, size: 18),
                                                  label: Text(context.tr('retry')),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    else if (state.hasReachedMax)
                                      SliverToBoxAdapter(
                                        child: state.wasPagingAttempted
                                            ? Padding(
                                                padding: const EdgeInsets.all(24.0),
                                                child: Center(
                                                  child: Text(
                                                    context.tr('reached_end'),
                                                    style: TextStyle(
                                                      color: Colors.grey.shade500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      )
                                    else
                                      const SliverToBoxAdapter(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VisualCartOverlay(controller: _visualCartController),
          ],
        ),
      ),
    );
  }
}
