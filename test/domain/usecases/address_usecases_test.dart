import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/domain/entities/address.dart';
import 'package:mini_commerce_app/domain/repositories/address_repository.dart';
import 'package:mini_commerce_app/domain/usecases/address/add_address_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/address/get_addresses_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/address/seed_default_addresses_usecase.dart';
import 'package:mini_commerce_app/domain/usecases/address/update_address_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAddressRepository extends Mock implements AddressRepository {}

void main() {
  late MockAddressRepository mockRepository;

  setUp(() {
    mockRepository = MockAddressRepository();
  });

  const tAddress = Address(id: '1', label: 'Home', city: 'Riyadh', street: 'Main St');

  setUpAll(() {
    registerFallbackValue(tAddress);
  });

  group('AddAddressUseCase', () {
    late AddAddressUseCase useCase;

    setUp(() {
      useCase = AddAddressUseCase(mockRepository);
    });

    test('delegates to repository.addAddress', () async {
      when(() => mockRepository.addAddress(tAddress)).thenAnswer((_) async {});

      await useCase(tAddress);

      verify(() => mockRepository.addAddress(tAddress)).called(1);
    });
  });

  group('GetAddressesUseCase', () {
    late GetAddressesUseCase useCase;

    setUp(() {
      useCase = GetAddressesUseCase(mockRepository);
    });

    test('delegates to repository.getAddresses', () async {
      when(() => mockRepository.getAddresses()).thenAnswer((_) async => [tAddress]);

      final result = await useCase();

      expect(result, [tAddress]);
      verify(() => mockRepository.getAddresses()).called(1);
    });

    test('returns empty list when no addresses', () async {
      when(() => mockRepository.getAddresses()).thenAnswer((_) async => []);

      final result = await useCase();

      expect(result, isEmpty);
    });
  });

  group('UpdateAddressUseCase', () {
    late UpdateAddressUseCase useCase;

    setUp(() {
      useCase = UpdateAddressUseCase(mockRepository);
    });

    test('delegates to repository.updateAddress', () async {
      when(() => mockRepository.updateAddress(tAddress)).thenAnswer((_) async {});

      await useCase(tAddress);

      verify(() => mockRepository.updateAddress(tAddress)).called(1);
    });
  });

  group('SeedDefaultAddressesUseCase', () {
    late SeedDefaultAddressesUseCase useCase;

    setUp(() {
      useCase = SeedDefaultAddressesUseCase(mockRepository);
    });

    test('delegates to repository.seedDefaultAddresses', () async {
      when(() => mockRepository.seedDefaultAddresses()).thenAnswer((_) async {});

      await useCase();

      verify(() => mockRepository.seedDefaultAddresses()).called(1);
    });
  });
}
