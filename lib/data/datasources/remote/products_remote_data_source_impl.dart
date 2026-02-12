import 'package:dio/dio.dart';

import '../../models/product_model.dart';
import 'products_remote_data_source.dart';

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  final Dio dio;

  ProductsRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ProductModel>> getProducts({
    required int limit,
    required int skip,
    String? sortBy,
    String? order,
  }) async {
    final Map<String, dynamic> params = {'limit': limit, 'skip': skip};
    if (sortBy != null) params['sortBy'] = sortBy;
    if (order != null) params['order'] = order;

    final response = await dio.get('https://dummyjson.com/products', queryParameters: params);

    final List products = response.data['products'];

    return products.map((json) => ProductModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  @override
  Future<List<ProductModel>> getProductsByCategory({
    required String category,
    required int limit,
    required int skip,
  }) async {
    final response = await dio.get(
      'https://dummyjson.com/products/category/$category',
      queryParameters: {'limit': limit, 'skip': skip},
    );

    final List products = response.data['products'];

    return products.map((json) => ProductModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final response = await dio.get('https://dummyjson.com/products/category-list');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => e.toString()).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  @override
  Future<List<ProductModel>> searchProducts({
    required String query,
    required int limit,
    required int skip,
  }) async {
    final response = await dio.get(
      'https://dummyjson.com/products/search',
      queryParameters: {'q': query, 'limit': limit, 'skip': skip},
    );

    final List products = response.data['products'];

    return products.map((json) => ProductModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }
}
