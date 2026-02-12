import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/local/address_local_data_source.dart';
import '../models/address_model.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressLocalDataSource localDataSource;

  AddressRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Address>> getAddresses() async {
    final rawList = await localDataSource.getAddresses();
    return rawList.map((map) => AddressModel.fromJson(map).toEntity()).toList();
  }

  @override
  Future<void> addAddress(Address address) async {
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
  }

  @override
  Future<void> updateAddress(Address address) async {
    final rawList = await localDataSource.getAddresses();
    final models = rawList.map((m) => AddressModel.fromJson(m)).toList();

    final index = models.indexWhere((m) => m.id == address.id);
    if (index == -1) return;

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
  }

  @override
  Future<void> seedDefaultAddresses() => localDataSource.seedDefaultAddresses();
}
