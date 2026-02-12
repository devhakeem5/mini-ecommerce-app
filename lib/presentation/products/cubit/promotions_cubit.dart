import 'package:flutter_bloc/flutter_bloc.dart';

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
          (failure) => emit(PromotionsError(failure.message)),
          (productsResult) => emit(
            PromotionsLoaded(
              products: productsResult.products,
              isOffline: productsResult.isOffline,
            ),
          ),
        );
      });
    } catch (e) {
      emit(PromotionsError(e.toString()));
    }
  }
}
