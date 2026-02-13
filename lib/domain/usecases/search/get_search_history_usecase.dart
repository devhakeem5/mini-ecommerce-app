import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../repositories/search_history_repository.dart';

class GetSearchHistoryUseCase {
  final SearchHistoryRepository repository;

  GetSearchHistoryUseCase(this.repository);

  Future<Either<Failure, List<String>>> call() {
    return repository.getSearchHistory();
  }
}
