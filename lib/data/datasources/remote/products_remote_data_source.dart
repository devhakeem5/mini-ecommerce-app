import '../../models/product_model.dart';

abstract class ProductsRemoteDataSource {
  Future<List<ProductModel>> getProducts({
    required int limit,
    required int skip,
    String? sortBy,
    String? order,
  });

  Future<List<ProductModel>> getProductsByCategory({
    required String category,
    required int limit,
    required int skip,
  });

  Future<List<String>> getCategories();

  Future<List<ProductModel>> searchProducts({
    required String query,
    required int limit,
    required int skip,
  });
}
