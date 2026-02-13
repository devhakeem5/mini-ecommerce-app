import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/domain/repositories/search_history_repository.dart';
import 'package:mini_commerce_app/domain/usecases/search/add_to_search_history_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/search/delete_search_history_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/search/get_search_history_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockSearchHistoryRepository extends Mock implements SearchHistoryRepository {}

void main() {
  late MockSearchHistoryRepository mockRepository;

  setUp(() {
    mockRepository = MockSearchHistoryRepository();
  });

  group('GetSearchHistoryUseCase', () {
    late GetSearchHistoryUseCase useCase;

    setUp(() {
      useCase = GetSearchHistoryUseCase(mockRepository);
    });

    test('delegates to repository.getSearchHistory', () async {
      when(
        () => mockRepository.getSearchHistory(),
      ).thenAnswer((_) async => const Right(['query1', 'query2']));

      final result = await useCase();

      expect(result, const Right(['query1', 'query2']));
      verify(() => mockRepository.getSearchHistory()).called(1);
    });

    test('returns empty list when no history', () async {
      when(
        () => mockRepository.getSearchHistory(),
      ).thenAnswer((_) async => const Right(<String>[]));

      final result = await useCase();

      expect(result, const Right(<String>[]));
    });
  });

  group('AddToSearchHistoryUseCase', () {
    late AddToSearchHistoryUseCase useCase;

    setUp(() {
      useCase = AddToSearchHistoryUseCase(mockRepository);
    });

    test('delegates to repository.addToHistory', () async {
      when(() => mockRepository.addToHistory('test')).thenAnswer((_) async => const Right(null));

      final result = await useCase('test');

      expect(result, const Right(null));
      verify(() => mockRepository.addToHistory('test')).called(1);
    });
  });

  group('DeleteSearchHistoryUseCase', () {
    late DeleteSearchHistoryUseCase useCase;

    setUp(() {
      useCase = DeleteSearchHistoryUseCase(mockRepository);
    });

    test('delegates to repository.deleteFromHistory', () async {
      when(
        () => mockRepository.deleteFromHistory('test'),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase('test');

      expect(result, const Right(null));
      verify(() => mockRepository.deleteFromHistory('test')).called(1);
    });
  });
}
