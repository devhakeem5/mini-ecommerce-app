import 'package:hive/hive.dart';
import 'package:mini_commerce_app/core/storage/hive_service.dart';
import 'package:mini_commerce_app/data/datasources/local/products_local_data_source.dart';

class ProductsLocalDataSourceImpl implements ProductsLocalDataSource {
  @override
  Future<List<Map<String, dynamic>>?> getCachedProducts({required String cacheKey}) async {
    final box = Hive.box(HiveService.productsBox);
    final data = box.get(cacheKey);

    if (data == null) return null;

    return List<Map<String, dynamic>>.from((data as List).map((e) => Map<String, dynamic>.from(e)));
  }

  @override
  Future<void> cacheProducts({
    required String cacheKey,
    required List<Map<String, dynamic>> products,
  }) async {
    final box = Hive.box(HiveService.productsBox);
    await box.put(cacheKey, products);
  }

  @override
  Future<List<Map<String, dynamic>>> searchLocalProducts(String query) async {
    final box = Hive.box(HiveService.productsBox);
    final lowerQuery = query.toLowerCase();
    final seenIds = <int>{};
    final results = <Map<String, dynamic>>[];

    for (final key in box.keys) {
      final keyStr = key.toString();

      if (!keyStr.startsWith('products_') && !keyStr.startsWith('category_')) {
        continue;
      }

      final data = box.get(key);
      if (data == null || data is! List) continue;

      for (final item in data) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = map['id'] as int? ?? 0;

        if (seenIds.contains(id)) continue;

        final title = (map['title'] as String? ?? '').toLowerCase();
        final description = (map['description'] as String? ?? '').toLowerCase();

        if (title.contains(lowerQuery) || description.contains(lowerQuery)) {
          seenIds.add(id);
          results.add(map);
        }
      }
    }

    return results;
  }

  @override
  Future<void> clearCache() async {
    final box = Hive.box(HiveService.productsBox);
    await box.clear();
  }

  @override
  Future<List<String>?> getCachedCategories() async {
    final box = Hive.box(HiveService.productsBox);
    final List<dynamic>? cached = box.get('categories_list');
    if (cached != null) {
      return cached.cast<String>();
    }
    return null;
  }

  @override
  Future<void> cacheCategories(List<String> categories) async {
    final box = Hive.box(HiveService.productsBox);
    await box.put('categories_list', categories);
  }
}
