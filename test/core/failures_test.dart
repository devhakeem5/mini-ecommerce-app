import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/core/error/exceptions.dart';
import 'package:mini_commerce_app/core/error/failures.dart';

void main() {
  group('Failures', () {
    test('ServerFailure has default message', () {
      const failure = ServerFailure();
      expect(failure.message, 'Failed to load data from server');
      expect(failure.toString(), 'Failed to load data from server');
    });

    test('ServerFailure accepts custom message', () {
      const failure = ServerFailure('Custom error');
      expect(failure.message, 'Custom error');
      expect(failure.toString(), 'Custom error');
    });

    test('CacheFailure has default message', () {
      const failure = CacheFailure();
      expect(failure.message, 'Failed to load data from cache');
    });

    test('CacheFailure accepts custom message', () {
      const failure = CacheFailure('Cache corrupted');
      expect(failure.message, 'Cache corrupted');
    });

    test('NetworkFailure has default message', () {
      const failure = NetworkFailure();
      expect(failure.message, 'No Internet Connection');
    });

    test('NetworkFailure accepts custom message', () {
      const failure = NetworkFailure('Timeout');
      expect(failure.message, 'Timeout');
    });
  });

  group('Exceptions', () {
    test('ServerException stores message', () {
      final exception = ServerException('Server down');
      expect(exception.message, 'Server down');
    });

    test('ServerException message can be null', () {
      final exception = ServerException();
      expect(exception.message, isNull);
    });

    test('CacheException stores message', () {
      final exception = CacheException('Read failed');
      expect(exception.message, 'Read failed');
    });

    test('NetworkException stores message', () {
      final exception = NetworkException('No WiFi');
      expect(exception.message, 'No WiFi');
    });

    test('all exceptions implement Exception', () {
      expect(ServerException(), isA<Exception>());
      expect(CacheException(), isA<Exception>());
      expect(NetworkException(), isA<Exception>());
    });
  });
}
