import 'package:hive/hive.dart';

import '../../../core/storage/hive_service.dart';
import 'locale_local_data_source.dart';

class LocaleLocalDataSourceImpl implements LocaleLocalDataSource {
  @override
  String getLocale() {
    final box = Hive.box(HiveService.settingsBox);
    return box.get('locale', defaultValue: 'en') as String;
  }

  @override
  Future<void> saveLocale(String code) async {
    final box = Hive.box(HiveService.settingsBox);
    await box.put('locale', code);
  }
}
