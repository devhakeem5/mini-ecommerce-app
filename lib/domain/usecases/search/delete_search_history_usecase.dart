import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../repositories/search_history_repository.dart';

class DeleteSearchHistoryUseCase {
  final SearchHistoryRepository repository;

  DeleteSearchHistoryUseCase(this.repository);

  Future<Either<Failure, void>> call(String query) {
    return repository.deleteFromHistory(query);
  }
}
