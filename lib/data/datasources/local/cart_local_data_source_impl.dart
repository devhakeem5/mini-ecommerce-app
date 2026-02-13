import 'package:hive/hive.dart';
import 'package:mini_commerce_app/core/storage/hive_service.dart';

import 'cart_local_data_source.dart';

class CartLocalDataSourceImpl implements CartLocalDataSource {
  static const String _legacyCartKey = 'cart_items';

  @override
  Future<List<Map<String, dynamic>>> loadCart() async {
    final box = Hive.box(HiveService.cartBox);

    // Migration: Check for legacy list
    if (box.containsKey(_legacyCartKey)) {
      final legacyData = box.get(_legacyCartKey);
      if (legacyData is List) {
        final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
          legacyData.map((e) => Map<String, dynamic>.from(e)),
        );

        // Migrate to individual keys
        for (final item in items) {
          final productId = item['product']['id'];
          await box.put(productId, item);
        }

        // Delete legacy key
        await box.delete(_legacyCartKey);
      }
    }

    // Return all values from box (excluding legacy key if it somehow persists, but we deleted it)
    // We assume the box is dedicated to cart items where keys are product IDs (ints)
    final items = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      if (key == _legacyCartKey) continue;
      final value = box.get(key);
      if (value is Map) {
        items.add(Map<String, dynamic>.from(value));
      }
    }
    return items;
  }

  @override
  Future<void> saveCart(List<Map<String, dynamic>> items) async {
    // For bulk save if needed, but we prefer granular.
    // This might be used by queue if we want to overwrite everything,
    // but typically we should avoid this for O(1).
    // Let's implement it by clearing and putting all to be safe if called.
    final box = Hive.box(HiveService.cartBox);
    await box.clear();
    for (final item in items) {
      final productId = item['product']['id'];
      await box.put(productId, item);
    }
  }

  @override
  Future<void> saveCartItem(Map<String, dynamic> item) async {
    final box = Hive.box(HiveService.cartBox);
    final productId = item['product']['id'];
    await box.put(productId, item);
  }

  @override
  Future<void> removeCartItem(int productId) async {
    final box = Hive.box(HiveService.cartBox);
    await box.delete(productId);
  }

  @override
  Future<void> clearCart() async {
    final box = Hive.box(HiveService.cartBox);
    await box.clear();
  }
}
