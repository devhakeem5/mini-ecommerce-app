abstract class SearchHistoryLocalDataSource {
  Future<List<String>> getSearchHistory();
  Future<void> addToHistory(String query);
  Future<void> deleteFromHistory(String query);
}
