import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_commerce_app/core/localization/app_localizations.dart';
import 'package:mini_commerce_app/core/util/responsive.dart';
import 'package:mini_commerce_app/presentation/cart/widgets/cart_empty.dart';
import 'package:mini_commerce_app/presentation/cart/widgets/cart_item_widget.dart';
import 'package:mini_commerce_app/presentation/profile/cubit/locale_cubit.dart';

import '../../../core/network/connectivity_cubit.dart';
import '../../../core/network/connectivity_state.dart';
import '../../common/widgets/custom_toast.dart';
import '../../common/widgets/offline_indicator.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import 'shipping_info_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('my_cart')),
        centerTitle: true,
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              if (state is CartLoaded && state.items.isNotEmpty) {
                return IconButton(
                  onPressed: () => _showClearDialog(context),
                  icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            BlocBuilder<ConnectivityCubit, ConnectivityState>(
              builder: (context, state) {
                if (state is ConnectivityOffline) {
                  return const OfflineIndicator();
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: BlocBuilder<CartCubit, CartState>(
                    builder: (context, state) {
                      if (state is CartLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is CartError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(state.message, style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        );
                      }

                      if (state is CartLoaded) {
                        if (state.items.isEmpty) {
                          return const CartEmptyWidget();
                        }
                        return context.responsiveValue(
                          mobile: _buildCartContent(context, state),
                          desktop: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildCartContent(context, state)),
                              const SizedBox(width: 40),
                              Expanded(
                                flex: 1,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: _buildDesktopSummary(context, state),
                                ),
                              ),
                            ],
                          ),
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
      bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is CartLoaded && state.items.isNotEmpty) {
            return context.isDesktop ? const SizedBox.shrink() : _buildBottomBar(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDesktopSummary(BuildContext context, CartLoaded state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('order_summary'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('subtotal')),
              Text('\$${state.totalPrice.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('discount'), style: const TextStyle(color: Colors.green)),
              Text(
                '-\$${state.totalSavings.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('total'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${state.totalDiscountedPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final connState = context.read<ConnectivityCubit>().state;
                if (connState is ConnectivityOffline) {
                  CustomToast.show(
                    context,
                    message: context.tr('checkout_offline'),
                    type: ToastType.warning,
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShippingInfoPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                context.tr('checkout'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, CartLoaded state) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      itemCount: state.items.length,
      separatorBuilder: (_, __) =>
          Divider(color: Theme.of(context).dividerColor.withOpacity(0.1), height: 1),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return CartItemWidget(item: item);
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, CartLoaded state) {
    final hasSavings = state.totalSavings > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.itemCount} ${context.tr(state.itemCount > 1 ? 'items' : 'item')}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                if (hasSavings)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${context.tr('you_save')} \$${state.totalSavings.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('total'),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    Text(
                      '\$${state.totalDiscountedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final connState = context.read<ConnectivityCubit>().state;
                      if (connState is ConnectivityOffline) {
                        CustomToast.show(
                          context,
                          message: context.tr('checkout_offline'),
                          type: ToastType.warning,
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShippingInfoPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      context.tr('checkout'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('clear_cart')),
        content: Text(context.tr('clear_cart_ask')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              context.read<CartCubit>().clearCart();
              Navigator.pop(context);
            },
            child: Text(context.tr('clear'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
