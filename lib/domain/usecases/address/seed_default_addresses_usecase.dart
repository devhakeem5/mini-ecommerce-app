import 'package:dartz/dartz.dart';
import 'package:mini_commerce_app/domain/repositories/address_repository.dart';

import '../../../core/error/failures.dart';

class SeedDefaultAddressesUseCase {
  final AddressRepository repository;

  SeedDefaultAddressesUseCase(this.repository);

  Future<Either<Failure, void>> call() => repository.seedDefaultAddresses();
}
