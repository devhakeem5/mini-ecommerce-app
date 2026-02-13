import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/domain/repositories/locale_repository.dart';
import 'package:mini_commerce_app/domain/usecases/locale/get_locale_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/locale/set_locale_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockLocaleRepository extends Mock implements LocaleRepository {}

void main() {
  late MockLocaleRepository mockRepository;

  setUp(() {
    mockRepository = MockLocaleRepository();
  });

  group('GetLocaleUseCase', () {
    late GetLocaleUseCase useCase;

    setUp(() {
      useCase = GetLocaleUseCase(mockRepository);
    });

    test('delegates to repository.getLocale and returns language code', () {
      when(() => mockRepository.getLocale()).thenReturn('ar');

      final result = useCase();

      expect(result, 'ar');
      verify(() => mockRepository.getLocale()).called(1);
    });

    test('returns default locale', () {
      when(() => mockRepository.getLocale()).thenReturn('en');

      final result = useCase();

      expect(result, 'en');
    });
  });

  group('SetLocaleUseCase', () {
    late SetLocaleUseCase useCase;

    setUp(() {
      useCase = SetLocaleUseCase(mockRepository);
    });

    test('delegates to repository.setLocale', () async {
      when(() => mockRepository.setLocale('ar')).thenAnswer((_) async {});

      await useCase('ar');

      verify(() => mockRepository.setLocale('ar')).called(1);
    });
  });
}
