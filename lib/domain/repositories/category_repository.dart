import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/category.dart';

abstract class CategoryRepository {
  Stream<Either<Failure, List<Category>>> getCategories();
}
