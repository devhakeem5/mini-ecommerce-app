import '../../repositories/search_history_repository.dart';

class GetSearchHistoryUseCase {
  final SearchHistoryRepository repository;

  GetSearchHistoryUseCase(this.repository);

  Future<List<String>> call() {
    return repository.getSearchHistory();
  }
}
