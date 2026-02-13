import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../entities/address.dart';
import '../../repositories/address_repository.dart';

class AddAddressUseCase {
  final AddressRepository repository;

  AddAddressUseCase(this.repository);

  Future<Either<Failure, void>> call(Address address) {
    return repository.addAddress(address);
  }
}
