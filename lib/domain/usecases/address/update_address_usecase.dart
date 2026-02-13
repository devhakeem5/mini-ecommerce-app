import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../entities/address.dart';
import '../../repositories/address_repository.dart';

class UpdateAddressUseCase {
  final AddressRepository repository;

  UpdateAddressUseCase(this.repository);

  Future<Either<Failure, void>> call(Address address) {
    return repository.updateAddress(address);
  }
}
