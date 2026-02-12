import 'package:hive/hive.dart';
import 'package:mini_commerce_app/core/storage/hive_service.dart';

import 'address_local_data_source.dart';

class AddressLocalDataSourceImpl implements AddressLocalDataSource {
  static const String _addressesKey = 'addresses';

  @override
  Future<List<Map<String, dynamic>>> getAddresses() async {
    final box = Hive.box(HiveService.addressesBox);
    final data = box.get(_addressesKey);

    if (data == null) return [];

    return List<Map<String, dynamic>>.from((data as List).map((e) => Map<String, dynamic>.from(e)));
  }

  @override
  Future<void> saveAddresses(List<Map<String, dynamic>> addresses) async {
    final box = Hive.box(HiveService.addressesBox);
    await box.put(_addressesKey, addresses);
  }

  @override
  Future<void> seedDefaultAddresses() async {
    final box = Hive.box(HiveService.addressesBox);
    if (box.get(_addressesKey) != null) return;

    final defaultAddresses = [
      {
        'id': 'addr_home',
        'label': 'Home',
        'city': 'Marib',
        'street': 'General Street',
        'details': 'Building 12, Apt 3',
        'isDefault': true,
      },
      {
        'id': 'addr_work',
        'label': 'Work',
        'city': "Sana'a",
        'street': 'Business District, Al-Zubairi St',
        'details': 'Office Tower, Floor 5',
        'isDefault': false,
      },
    ];

    await box.put(_addressesKey, defaultAddresses);
  }
}
