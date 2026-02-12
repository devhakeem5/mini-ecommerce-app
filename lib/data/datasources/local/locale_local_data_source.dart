abstract class LocaleLocalDataSource {
  String getLocale();
  Future<void> saveLocale(String code);
}
