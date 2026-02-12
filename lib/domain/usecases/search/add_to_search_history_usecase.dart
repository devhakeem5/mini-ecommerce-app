import '../../repositories/search_history_repository.dart';

class AddToSearchHistoryUseCase {
  final SearchHistoryRepository repository;

  AddToSearchHistoryUseCase(this.repository);

  Future<void> call(String query) {
    return repository.addToHistory(query);
  }
}
