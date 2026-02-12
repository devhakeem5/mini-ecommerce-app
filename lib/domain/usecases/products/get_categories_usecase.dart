import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../entities/category.dart';
import '../../repositories/category_repository.dart';

class GetCategoriesUseCase {
  final CategoryRepository repository;

  GetCategoriesUseCase(this.repository);

  Stream<Either<Failure, List<Category>>> call() {
    return repository.getCategories();
  }
}
