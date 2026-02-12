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
    try {
      final addresses = await getAddressesUseCase();
      final defaultAddr = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
      emit(AddressLoaded(addresses: addresses, selectedAddress: defaultAddr));
    } catch (e) {
      emit(AddressError('Failed to load addresses: $e'));
    }
  }

  void selectAddress(Address address) {
    if (state is AddressLoaded) {
      final loaded = state as AddressLoaded;
      emit(AddressLoaded(addresses: loaded.addresses, selectedAddress: address));
    }
  }

  Future<void> addAddress(Address address) async {
    try {
      await addAddressUseCase(address);
      await loadAddresses();
    } catch (e) {
      emit(AddressError('Failed to add address: $e'));
    }
  }

  Future<void> updateAddress(Address address) async {
    try {
      await updateAddressUseCase(address);
      await loadAddresses();
    } catch (e) {
      emit(AddressError('Failed to update address: $e'));
    }
  }
}
