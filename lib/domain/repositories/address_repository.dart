import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/address.dart';

abstract class AddressRepository {
  Future<Either<Failure, List<Address>>> getAddresses();
  Future<Either<Failure, void>> addAddress(Address address);
  Future<Either<Failure, void>> updateAddress(Address address);
  Future<Either<Failure, void>> seedDefaultAddresses();
}
