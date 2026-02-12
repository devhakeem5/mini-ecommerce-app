import '../../entities/address.dart';
import '../../repositories/address_repository.dart';

class UpdateAddressUseCase {
  final AddressRepository repository;

  UpdateAddressUseCase(this.repository);

  Future<void> call(Address address) {
    return repository.updateAddress(address);
  }
}
