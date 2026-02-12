import '../../domain/repositories/locale_repository.dart';
import '../datasources/local/locale_local_data_source.dart';

class LocaleRepositoryImpl implements LocaleRepository {
  final LocaleLocalDataSource localDataSource;

  LocaleRepositoryImpl({required this.localDataSource});

  @override
  String getLocale() => localDataSource.getLocale();

  @override
  Future<void> setLocale(String code) => localDataSource.saveLocale(code);
}
