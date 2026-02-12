import 'package:mini_commerce_app/domain/repositories/locale_repository.dart';

class GetLocaleUseCase {
  final LocaleRepository repository;

  GetLocaleUseCase(this.repository);

  String call() => repository.getLocale();
}
