import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/core/error/failures.dart';
import 'package:mini_commerce_app/domain/entities/products_result.dart';
import 'package:mini_commerce_app/domain/repositories/products_repository.dart';
import 'package:mini_commerce_app/domain/usecases/products/get_products_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}

void main() {
  late GetProductsUseCase useCase;
  late MockProductsRepository mockProductsRepository;

  setUp(() {
    mockProductsRepository = MockProductsRepository();
    useCase = GetProductsUseCase(mockProductsRepository);
  });

  const tLimit = 20;
  const tSkip = 0;
  final tProductsResult = ProductsResult(products: [], isOffline: false);

  test('should get products from the repository', () async {
    when(
      () => mockProductsRepository.getProducts(limit: tLimit, skip: tSkip),
    ).thenAnswer((_) => Stream.value(Right(tProductsResult)));

    final resultStream = useCase(limit: tLimit, skip: tSkip);

    expect(resultStream, emits(Right(tProductsResult)));
    verify(() => mockProductsRepository.getProducts(limit: tLimit, skip: tSkip)).called(1);
    verifyNoMoreInteractions(mockProductsRepository);
  });

  test('should emit failure when repository fails', () async {
    const tFailure = ServerFailure('Server Error');
    when(
      () => mockProductsRepository.getProducts(limit: tLimit, skip: tSkip),
    ).thenAnswer((_) => Stream.value(Left(tFailure)));

    final resultStream = useCase(limit: tLimit, skip: tSkip);

    expect(resultStream, emits(Left(tFailure)));
    verify(() => mockProductsRepository.getProducts(limit: tLimit, skip: tSkip)).called(1);
    verifyNoMoreInteractions(mockProductsRepository);
  });
}
