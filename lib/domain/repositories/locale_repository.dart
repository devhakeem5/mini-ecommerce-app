abstract class LocaleRepository {
  String getLocale();
  Future<void> setLocale(String code);
}
