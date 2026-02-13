import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/address.dart';
import '../../../domain/usecases/address/add_address_usecase.dart';
import '../../../domain/usecases/address/get_addresses_usecase.dart';
import '../../../domain/usecases/address/update_address_usecase.dart';
import 'address_state.dart';

class AddressCubit extends Cubit<AddressState> {
  final GetAddressesUseCase getAddressesUseCase;
  final AddAddressUseCase addAddressUseCase;
  final UpdateAddressUseCase updateAddressUseCase;

  AddressCubit({
    required this.getAddressesUseCase,
    required this.addAddressUseCase,
    required this.updateAddressUseCase,
  }) : super(const AddressInitial());

  Future<void> loadAddresses() async {
    emit(const AddressLoading());
    final result = await getAddressesUseCase();
    result.fold((failure) => emit(AddressError(failure.message)), (addresses) {
      if (addresses.isEmpty) {
        emit(const AddressLoaded(addresses: []));
      } else {
        final defaultAddr = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
        emit(AddressLoaded(addresses: addresses, selectedAddress: defaultAddr));
      }
    });
  }

  void selectAddress(Address address) {
    if (state is AddressLoaded) {
      final loaded = state as AddressLoaded;
      emit(AddressLoaded(addresses: loaded.addresses, selectedAddress: address));
    }
  }

  Future<void> addAddress(Address address) async {
    final result = await addAddressUseCase(address);
    result.fold((failure) => emit(AddressError(failure.message)), (_) => loadAddresses());
  }

  Future<void> updateAddress(Address address) async {
    final result = await updateAddressUseCase(address);
    result.fold((failure) => emit(AddressError(failure.message)), (_) => loadAddresses());
  }
}
