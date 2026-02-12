import 'package:mini_commerce_app/domain/repositories/address_repository.dart';

class SeedDefaultAddressesUseCase {
  final AddressRepository repository;

  SeedDefaultAddressesUseCase(this.repository);

  Future<void> call() => repository.seedDefaultAddresses();
}
