import '../../entities/address.dart';
import '../../repositories/address_repository.dart';

class GetAddressesUseCase {
  final AddressRepository repository;

  GetAddressesUseCase(this.repository);

  Future<List<Address>> call() {
    return repository.getAddresses();
  }
}
