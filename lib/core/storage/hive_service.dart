import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String productsBox = 'products_box';
  static const String cartBox = 'cart_box';
  static const String searchHistoryBox = 'search_history';
  static const String addressesBox = 'addresses_box';
  static const String settingsBox = 'settings_box';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(productsBox);
    await Hive.openBox(cartBox);
    await Hive.openBox<String>(searchHistoryBox);
    await Hive.openBox(addressesBox);
    await Hive.openBox(settingsBox);
  }
}
