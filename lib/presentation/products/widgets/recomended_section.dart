import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/localization/app_localizations.dart';
import '/presentation/common/widgets/custom_error_widget.dart';
import '/presentation/common/widgets/empty_widget.dart';
import '/presentation/common/widgets/offline_banner.dart';
import '/presentation/products/widgets/product_horizontal_list.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/usecases/products/filter_recommended_products_usecase.dart';
import '../../common/widgets/section_title.dart';
import '../../products/cubit/products_cubit.dart';
import '../../products/cubit/products_state.dart';
import '../pages/all_products_page.dart';
import 'product_horizontal_loader.dart';

class RecomendedSection extends StatelessWidget {
  const RecomendedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.tr('recommended');

    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        if (state is ProductsLoading && (state is! ProductsLoaded)) {
          return LoadingHorizontalList(title: title);
        }

        if (state is ProductsLoaded) {
          if (state.products.isEmpty) {
            return EmptyWidget(title: title);
          }

          final products = sl<FilterRecommendedProductsUseCase>()(state.products);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  context.tr('welcome_back'),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              SectionTitle(
                title: title,
                action: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AllProductsPage(title: title)),
                    );
                  },
                  child: Text(context.tr('see_more')),
                ),
              ),

              if (state.isOffline) const OfflineBanner(),

              const SizedBox(height: 16),
              ProductsHorizontalList(products: products, heroTagPrefix: 'recommended'),
            ],
          );
        }

        if (state is ProductsError) {
          return CustomErrorWidget(
            title: title,
            message: state.message,
            onRetry: () {
              context.read<ProductsCubit>().loadInitialProducts();
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
