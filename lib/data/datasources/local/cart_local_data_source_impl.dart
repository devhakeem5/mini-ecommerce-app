import 'package:hive/hive.dart';
import 'package:mini_commerce_app/core/storage/hive_service.dart';

import 'cart_local_data_source.dart';

class CartLocalDataSourceImpl implements CartLocalDataSource {
  static const String _cartKey = 'cart_items';

  @override
  Future<List<Map<String, dynamic>>> loadCart() async {
    final box = Hive.box(HiveService.cartBox);
    final data = box.get(_cartKey);

    if (data == null) return [];

    return List<Map<String, dynamic>>.from((data as List).map((e) => Map<String, dynamic>.from(e)));
  }

  @override
  Future<void> saveCart(List<Map<String, dynamic>> items) async {
    final box = Hive.box(HiveService.cartBox);
    await box.put(_cartKey, items);
  }

  @override
  Future<void> clearCart() async {
    final box = Hive.box(HiveService.cartBox);
    await box.delete(_cartKey);
  }
}
