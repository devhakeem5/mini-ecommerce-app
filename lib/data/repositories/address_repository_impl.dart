import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/local/address_local_data_source.dart';
import '../models/address_model.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressLocalDataSource localDataSource;

  AddressRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Address>>> getAddresses() async {
    try {
      final rawList = await localDataSource.getAddresses();
      final addresses = rawList.map((map) => AddressModel.fromJson(map).toEntity()).toList();
      return Right(addresses);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addAddress(Address address) async {
    try {
      final rawList = await localDataSource.getAddresses();
      final models = rawList.map((m) => AddressModel.fromJson(m)).toList();

      if (address.isDefault) {
        for (int i = 0; i < models.length; i++) {
          models[i] = AddressModel(
            id: models[i].id,
            label: models[i].label,
            city: models[i].city,
            street: models[i].street,
            details: models[i].details,
            isDefault: false,
          );
        }
      }

      models.add(AddressModel.fromEntity(address));
      await localDataSource.saveAddresses(models.map((m) => m.toJson()).toList());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAddress(Address address) async {
    try {
      final rawList = await localDataSource.getAddresses();
      final models = rawList.map((m) => AddressModel.fromJson(m)).toList();

      final index = models.indexWhere((m) => m.id == address.id);
      if (index == -1) {
        return const Left(CacheFailure('Address not found'));
      }

      if (address.isDefault) {
        for (int i = 0; i < models.length; i++) {
          if (i != index) {
            models[i] = AddressModel(
              id: models[i].id,
              label: models[i].label,
              city: models[i].city,
              street: models[i].street,
              details: models[i].details,
              isDefault: false,
            );
          }
        }
      }

      models[index] = AddressModel.fromEntity(address);
      await localDataSource.saveAddresses(models.map((m) => m.toJson()).toList());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> seedDefaultAddresses() async {
    try {
      await localDataSource.seedDefaultAddresses();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
