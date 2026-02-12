import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/products/get_categories_usecase.dart';
import 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  final GetCategoriesUseCase getCategoriesUseCase;

  CategoriesCubit({required this.getCategoriesUseCase}) : super(CategoriesInitial());

  Future<void> loadCategories() async {
    emit(CategoriesLoading());
    try {
      final stream = getCategoriesUseCase();

      await stream.forEach((result) {
        if (isClosed) return;
        result.fold(
          (failure) => emit(CategoriesError(failure.message)),
          (categories) => emit(CategoriesLoaded(categories)),
        );
      });
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }
}
