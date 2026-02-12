import 'package:mini_commerce_app/domain/repositories/locale_repository.dart';

class SetLocaleUseCase {
  final LocaleRepository repository;

  SetLocaleUseCase(this.repository);

  Future<void> call(String code) => repository.setLocale(code);
}
