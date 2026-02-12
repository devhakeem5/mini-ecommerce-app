import '../../repositories/search_history_repository.dart';

class DeleteSearchHistoryUseCase {
  final SearchHistoryRepository repository;

  DeleteSearchHistoryUseCase(this.repository);

  Future<void> call(String query) {
    return repository.deleteFromHistory(query);
  }
}
