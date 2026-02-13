import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/data/datasources/local/search_history_local_data_source.dart';
import 'package:mini_commerce_app/data/repositories/search_history_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockSearchHistoryLocalDataSource extends Mock implements SearchHistoryLocalDataSource {}

void main() {
  late SearchHistoryRepositoryImpl repository;
  late MockSearchHistoryLocalDataSource mockLocal;

  setUp(() {
    mockLocal = MockSearchHistoryLocalDataSource();
    repository = SearchHistoryRepositoryImpl(localDataSource: mockLocal);
  });

  group('getSearchHistory', () {
    test('delegates to local data source', () async {
      when(() => mockLocal.getSearchHistory()).thenAnswer((_) async => ['apple', 'banana']);

      final result = await repository.getSearchHistory();

      expect(result, ['apple', 'banana']);
      verify(() => mockLocal.getSearchHistory()).called(1);
    });
  });

  group('addToHistory', () {
    test('delegates to local data source', () async {
      when(() => mockLocal.addToHistory('test')).thenAnswer((_) async {});

      await repository.addToHistory('test');

      verify(() => mockLocal.addToHistory('test')).called(1);
    });

    test('trims whitespace before adding', () async {
      when(() => mockLocal.addToHistory('test')).thenAnswer((_) async {});

      await repository.addToHistory('  test  ');

      verify(() => mockLocal.addToHistory('test')).called(1);
    });

    test('does not add empty query', () async {
      await repository.addToHistory('');

      verifyNever(() => mockLocal.addToHistory(any()));
    });

    test('does not add whitespace-only query', () async {
      await repository.addToHistory('   ');

      verifyNever(() => mockLocal.addToHistory(any()));
    });
  });

  group('deleteFromHistory', () {
    test('delegates to local data source', () async {
      when(() => mockLocal.deleteFromHistory('test')).thenAnswer((_) async {});

      await repository.deleteFromHistory('test');

      verify(() => mockLocal.deleteFromHistory('test')).called(1);
    });
  });
}
