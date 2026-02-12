import '../../entities/address.dart';
import '../../repositories/address_repository.dart';

class AddAddressUseCase {
  final AddressRepository repository;

  AddAddressUseCase(this.repository);

  Future<void> call(Address address) {
    return repository.addAddress(address);
  }
}
