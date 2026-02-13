import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../entities/address.dart';
import '../../repositories/address_repository.dart';

class GetAddressesUseCase {
  final AddressRepository repository;

  GetAddressesUseCase(this.repository);

  Future<Either<Failure, List<Address>>> call() {
    return repository.getAddresses();
  }
}
