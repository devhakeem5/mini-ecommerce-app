import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_commerce_app/core/util/responsive.dart';
import 'package:mini_commerce_app/presentation/products/widgets/blogs_list.dart';
import 'package:mini_commerce_app/presentation/products/widgets/brands_list.dart';
import 'package:mini_commerce_app/presentation/products/widgets/category_list.dart';
import 'package:mini_commerce_app/presentation/products/widgets/recomended_section.dart';

import '../../../core/network/connectivity_cubit.dart';
import '../../../core/network/connectivity_state.dart';
import '../../common/fly_to_cart/fly_to_cart_controller.dart';
import '../../common/fly_to_cart/fly_to_cart_overlay.dart';
import '../../common/widgets/main_bottom_nav.dart';
import '../../common/widgets/offline_indicator.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';
import '../cubit/promotions_cubit.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/new_arrivals_section.dart';
import '../widgets/promotions_slider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlyToCartControllerState _flyController = FlyToCartControllerState();

  @override
  void dispose() {
    _flyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlyToCartController(state: _flyController, child: const _HomeView());
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final controller = FlyToCartController.of(context);

    return MultiBlocListener(
      listeners: [
       
        BlocListener<ConnectivityCubit, ConnectivityState>(
          listenWhen: (previous, current) =>
              previous is ConnectivityOffline && current is ConnectivityOnline,
          listener: (context, connState) {
            // Trigger silent refresh for products and promotions
            context.read<ProductsCubit>().refresh();
            context.read<PromotionsCubit>().refresh();

            final productsState = context.read<ProductsCubit>().state;
            if (productsState is ProductsLoaded && productsState.loadMoreError != null) {
              context.read<ProductsCubit>().loadMoreProducts();
            }
          },
        ),
      ],
      child: Stack(
        children: [
          Scaffold(
            bottomNavigationBar: const MainBottomNav(),
            body: SafeArea(
              child: Column(
                children: [
                  const HomeAppBar(),
                  BlocBuilder<ConnectivityCubit, ConnectivityState>(
                    builder: (context, state) {
                      if (state is ConnectivityOffline) {
                        return const OfflineIndicator();
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Responsive(
                              mobile: const _HomeContent(),
                              tablet: const _HomeContent(crossAxisCount: 2),
                              desktop: const _HomeContent(crossAxisCount: 3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FlyToCartOverlay(controller: controller),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final int crossAxisCount;
  const _HomeContent({this.crossAxisCount = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PromotionsSlider(),
        const SizedBox(height: 32),
        const CategoryList(),
        const SizedBox(height: 32),
        const NewArrivalsSection(),
        const SizedBox(height: 32),
        const BrandsList(),
        const SizedBox(height: 32),
        const RecomendedSection(),
        const SizedBox(height: 32),
        const BlogsList(),
      ],
    );
  }
}
