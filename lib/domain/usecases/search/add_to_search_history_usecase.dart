import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../repositories/search_history_repository.dart';

class AddToSearchHistoryUseCase {
  final SearchHistoryRepository repository;

  AddToSearchHistoryUseCase(this.repository);

  Future<Either<Failure, void>> call(String query) {
    return repository.addToHistory(query);
  }
}
