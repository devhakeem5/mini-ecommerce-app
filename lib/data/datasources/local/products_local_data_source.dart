abstract class ProductsLocalDataSource {
  Future<List<Map<String, dynamic>>?> getCachedProducts({required String cacheKey});

  Future<void> cacheProducts({
    required String cacheKey,
    required List<Map<String, dynamic>> products,
  });

  Future<List<Map<String, dynamic>>> searchLocalProducts(String query);

  Future<void> clearCache();

  Future<List<String>?> getCachedCategories();

  Future<void> cacheCategories(List<String> categories);
}
