import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../domain/repositories/search_history_repository.dart';
import '../datasources/local/search_history_local_data_source.dart';

class SearchHistoryRepositoryImpl implements SearchHistoryRepository {
  final SearchHistoryLocalDataSource localDataSource;

  SearchHistoryRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<String>>> getSearchHistory() async {
    try {
      final history = await localDataSource.getSearchHistory();
      return Right(history);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addToHistory(String query) async {
    if (query.trim().isEmpty) return const Right(null);
    try {
      await localDataSource.addToHistory(query.trim());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFromHistory(String query) async {
    try {
      await localDataSource.deleteFromHistory(query);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
