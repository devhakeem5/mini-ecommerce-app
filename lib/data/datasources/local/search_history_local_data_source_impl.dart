import 'package:hive/hive.dart';
import 'package:mini_commerce_app/core/storage/hive_service.dart';

import 'search_history_local_data_source.dart';

class SearchHistoryLocalDataSourceImpl implements SearchHistoryLocalDataSource {
  Box<String> _getBox() {
    return Hive.box<String>(HiveService.searchHistoryBox);
  }

  @override
  Future<List<String>> getSearchHistory() async {
    final box = _getBox();
    return box.values.toList().reversed.toList();
  }

  @override
  Future<void> addToHistory(String query) async {
    final box = _getBox();

    final existingIndex = box.values.toList().indexOf(query);
    if (existingIndex != -1) {
      await box.deleteAt(existingIndex);
    }

    await box.add(query);

    if (box.length > 10) {
      await box.deleteAt(0);
    }
  }

  @override
  Future<void> deleteFromHistory(String query) async {
    final box = _getBox();
    final items = box.values.toList();
    final index = items.indexOf(query);
    if (index != -1) {
      await box.deleteAt(index);
    }
  }
}
