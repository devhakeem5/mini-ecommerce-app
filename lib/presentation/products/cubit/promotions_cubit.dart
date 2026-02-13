import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_commerce_app/core/error/failures.dart';

import '../../../../domain/usecases/products/get_products_usecase.dart';
import 'promotions_state.dart';

class PromotionsCubit extends Cubit<PromotionsState> {
  final GetProductsUseCase getProductsUseCase;

  PromotionsCubit({required this.getProductsUseCase}) : super(PromotionsInitial());

  Future<void> loadPromotions() async {
    emit(PromotionsLoading());
    try {
      final stream = getProductsUseCase(
        limit: 5,
        skip: 0,
        sortBy: 'discountPercentage',
        order: 'desc',
      );

      await stream.forEach((result) {
        if (isClosed) return;
        result.fold(
          (failure) {
            // If we already have data, don't overwrite with error
            if (state is PromotionsLoaded) return;

            if (failure is NetworkFailure) {
              emit(const PromotionsError('no_internet_no_data'));
            } else {
              emit(PromotionsError(failure.message));
            }
          },
          (productsResult) {
            final newProducts = productsResult.products;
            if (productsResult.products.isEmpty && productsResult.isOffline) {
              // Only emit empty offline error if we don't have data
              if (state is! PromotionsLoaded) {
                emit(const PromotionsError('no_internet_no_data'));
              }
            } else {
              // Check for diff before emitting
              if (state is PromotionsLoaded) {
                final currentProducts = (state as PromotionsLoaded).products;
                if (_areProductListsEqual(currentProducts, newProducts)) {
                  // Data is same, but we might need to update isOffline status
                  if ((state as PromotionsLoaded).isOffline != productsResult.isOffline) {
                    emit(
                      PromotionsLoaded(products: newProducts, isOffline: productsResult.isOffline),
                    );
                  }
                  return;
                }
              }

              emit(
                PromotionsLoaded(
                  products: productsResult.products,
                  isOffline: productsResult.isOffline,
                ),
              );
            }
          },
        );
      });
    } catch (e) {
      emit(PromotionsError(e.toString()));
    }
  }

  Future<void> refresh() async {
    try {
      final stream = getProductsUseCase(
        limit: 5,
        skip: 0,
        sortBy: 'discountPercentage',
        order: 'desc',
      );

      await stream.forEach((result) {
        if (isClosed) return;
        result.fold((failure) {}, (productsResult) {
          final newProducts = productsResult.products;
          if (state is PromotionsLoaded) {
            final currentProducts = (state as PromotionsLoaded).products;
            if (!_areProductListsEqual(currentProducts, newProducts)) {
              emit(PromotionsLoaded(products: newProducts, isOffline: productsResult.isOffline));
            }
          } else {
            if (newProducts.isNotEmpty) {
              emit(PromotionsLoaded(products: newProducts, isOffline: productsResult.isOffline));
            }
          }
        });
      });
    } catch (_) {}
  }

  bool _areProductListsEqual(List<dynamic> list1, List<dynamic> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }
}
