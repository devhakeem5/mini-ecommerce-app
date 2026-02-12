import '../../domain/repositories/search_history_repository.dart';
import '../datasources/local/search_history_local_data_source.dart';

class SearchHistoryRepositoryImpl implements SearchHistoryRepository {
  final SearchHistoryLocalDataSource localDataSource;

  SearchHistoryRepositoryImpl({required this.localDataSource});

  @override
  Future<List<String>> getSearchHistory() {
    return localDataSource.getSearchHistory();
  }

  @override
  Future<void> addToHistory(String query) {
    if (query.trim().isEmpty) return Future.value();
    return localDataSource.addToHistory(query.trim());
  }

  @override
  Future<void> deleteFromHistory(String query) {
    return localDataSource.deleteFromHistory(query);
  }
}
