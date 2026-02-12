import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_commerce_app/core/localization/app_localizations.dart';
import 'package:mini_commerce_app/presentation/common/widgets/custom_error_widget.dart';
import 'package:mini_commerce_app/presentation/common/widgets/empty_widget.dart';
import 'package:mini_commerce_app/presentation/common/widgets/offline_banner.dart';
import 'package:mini_commerce_app/presentation/products/widgets/product_horizontal_list.dart';

import '../../common/widgets/section_title.dart';
import '../../products/cubit/products_cubit.dart';
import '../../products/cubit/products_state.dart';
import 'product_horizontal_loader.dart';

class NewArrivalsSection extends StatelessWidget {
  const NewArrivalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.tr('new_arrivals');

    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        if (state is ProductsLoading) {
          return LoadingHorizontalList(title: title);
        }

        if (state is ProductsLoaded) {
          if (state.products.isEmpty) {
            return EmptyWidget(title: title);
          }

          final products = state.products.take(6).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: title),
              if (state.isOffline) const OfflineBanner(),
              const SizedBox(height: 16),
              ProductsHorizontalList(products: products, heroTagPrefix: 'new_arrivals'),
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
