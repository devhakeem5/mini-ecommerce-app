import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:mini_commerce_app/data/datasources/local/cart_local_data_source.dart';
import 'package:mini_commerce_app/data/datasources/local/cart_local_data_source_impl.dart';
import 'package:mini_commerce_app/data/repositories/cart_repository_impl.dart';
import 'package:mini_commerce_app/data/repositories/category_repository_impl.dart';
import 'package:mini_commerce_app/data/repositories/user_repository_impl.dart';
import 'package:mini_commerce_app/domain/repositories/cart_repository.dart';
import 'package:mini_commerce_app/domain/repositories/user_repository.dart';
import 'package:mini_commerce_app/presentation/cart/cubit/cart_cubit.dart';
import 'package:mini_commerce_app/presentation/profile/cubit/locale_cubit.dart';
import 'package:mini_commerce_app/presentation/profile/cubit/profile_cubit.dart';

import '../../core/network/connectivity_cubit.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/network/offline_sync_service.dart';
import '../../data/datasources/local/address_local_data_source.dart';
import '../../data/datasources/local/address_local_data_source_impl.dart';
import '../../data/datasources/local/locale_local_data_source.dart';
import '../../data/datasources/local/locale_local_data_source_impl.dart';
import '../../data/datasources/local/products_local_data_source.dart';
import '../../data/datasources/local/products_local_data_source_impl.dart';
import '../../data/datasources/local/search_history_local_data_source.dart';
import '../../data/datasources/local/search_history_local_data_source_impl.dart';
import '../../data/datasources/remote/products_remote_data_source.dart';
import '../../data/datasources/remote/products_remote_data_source_impl.dart';
import '../../data/repositories/address_repository_impl.dart';
import '../../data/repositories/locale_repository_impl.dart';
import '../../data/repositories/products_repository_impl.dart';
import '../../data/repositories/search_history_repository_impl.dart';
import '../../domain/repositories/address_repository.dart';
import '../../domain/repositories/locale_repository.dart';
import '../../domain/repositories/search_history_repository.dart';
import '../../domain/usecases/address/add_address_usecase.dart';
import '../../domain/usecases/address/get_addresses_usecase.dart';
import '../../domain/usecases/address/seed_default_addresses_usecase.dart';
import '../../domain/usecases/address/update_address_usecase.dart';
import '../../domain/usecases/cart/add_to_cart_usecase.dart';
import '../../domain/usecases/cart/clear_cart_usecase.dart';
import '../../domain/usecases/cart/load_cart_usecase.dart';
import '../../domain/usecases/cart/remove_from_cart_usecase.dart';
import '../../domain/usecases/cart/update_cart_prices_usecase.dart';
import '../../domain/usecases/cart/update_cart_quantity_usecase.dart';
import '../../domain/usecases/locale/get_locale_usecase.dart';
import '../../domain/usecases/locale/set_locale_usecase.dart';
import '../../domain/usecases/products/filter_recommended_products_usecase.dart';
import '../../domain/usecases/products/filter_related_products_usecase.dart';
import '../../domain/usecases/products/get_product_options_usecase.dart';
import '../../domain/usecases/search/add_to_search_history_usecase.dart';
import '../../domain/usecases/search/delete_search_history_usecase.dart';
import '../../domain/usecases/search/get_search_history_usecase.dart';
import '../../presentation/cart/cubit/address_cubit.dart';
import '../../presentation/products/products.dart';
import '../storage/hive_service.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  sl.registerLazySingleton<HiveService>(() => HiveService());

  await sl<HiveService>().init();

  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<OfflineSyncService>(() => OfflineSyncService());

  sl.registerLazySingleton<ProductsRemoteDataSource>(() => ProductsRemoteDataSourceImpl(dio: sl()));
  sl.registerLazySingleton<ProductsLocalDataSource>(() => ProductsLocalDataSourceImpl());
  sl.registerLazySingleton<CartLocalDataSource>(() => CartLocalDataSourceImpl());
  sl.registerLazySingleton<SearchHistoryLocalDataSource>(() => SearchHistoryLocalDataSourceImpl());
  sl.registerLazySingleton<AddressLocalDataSource>(() => AddressLocalDataSourceImpl());
  sl.registerLazySingleton<LocaleLocalDataSource>(() => LocaleLocalDataSourceImpl());

  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(remote: sl(), local: sl()),
  );
  sl.registerLazySingleton<ProductsRepository>(
    () => ProductsRepositoryImpl(remote: sl(), local: sl()),
  );
  sl.registerLazySingleton<CartRepository>(() => CartRepositoryImpl(localDataSource: sl()));
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl());
  sl.registerLazySingleton<SearchHistoryRepository>(
    () => SearchHistoryRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<AddressRepository>(() => AddressRepositoryImpl(localDataSource: sl()));
  sl.registerLazySingleton<LocaleRepository>(() => LocaleRepositoryImpl(localDataSource: sl()));

  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetProductsByCategoryUseCase(sl()));
  sl.registerLazySingleton(() => SearchProductsUseCase(sl()));
  sl.registerLazySingleton(() => SearchProductsUseCase(sl()));
  sl.registerLazySingleton(() => SearchProductsLocallyUseCase(sl()));

  sl.registerLazySingleton(() => GetProductOptionsUseCase());
  sl.registerLazySingleton(() => FilterRelatedProductsUseCase());
  sl.registerLazySingleton(() => FilterRecommendedProductsUseCase());

  sl.registerLazySingleton(() => LoadCartUseCase(sl()));
  sl.registerLazySingleton(() => AddToCartUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCartQuantityUseCase(sl()));
  sl.registerLazySingleton(() => RemoveFromCartUseCase(sl()));
  sl.registerLazySingleton(() => ClearCartUseCase(sl()));

  sl.registerLazySingleton(() => GetSearchHistoryUseCase(sl()));
  sl.registerLazySingleton(() => AddToSearchHistoryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSearchHistoryUseCase(sl()));

  sl.registerLazySingleton(() => GetAddressesUseCase(sl()));
  sl.registerLazySingleton(() => AddAddressUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAddressUseCase(sl()));
  sl.registerLazySingleton(() => SeedDefaultAddressesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCartPricesUseCase(sl()));

  sl.registerLazySingleton(() => GetLocaleUseCase(sl()));
  sl.registerLazySingleton(() => SetLocaleUseCase(sl()));

  sl.registerFactory(() => ProductsCubit(getProductsUseCase: sl()));
  sl.registerFactory(() => CategoriesCubit(getCategoriesUseCase: sl()));
  sl.registerFactory(
    () => ProductListCubit(getProductsUseCase: sl(), getProductsByCategoryUseCase: sl()),
  );
  sl.registerFactory(() => PromotionsCubit(getProductsUseCase: sl()));
  sl.registerFactory(
    () => CartCubit(
      loadCartUseCase: sl(),
      addToCartUseCase: sl(),
      updateCartQuantityUseCase: sl(),
      removeFromCartUseCase: sl(),
      clearCartUseCase: sl(),
      updateCartPricesUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => SearchCubit(
      searchProductsUseCase: sl(),
      searchProductsLocallyUseCase: sl(),
      getSearchHistoryUseCase: sl(),
      addToSearchHistoryUseCase: sl(),
      deleteSearchHistoryUseCase: sl(),
    ),
  );
  sl.registerFactory(() => ProfileCubit(sl()));
  sl.registerLazySingleton(() => LocaleCubit(getLocaleUseCase: sl(), setLocaleUseCase: sl()));
  sl.registerFactory(() => ConnectivityCubit(connectivityService: sl(), syncService: sl()));
  sl.registerFactory(
    () => AddressCubit(
      getAddressesUseCase: sl(),
      addAddressUseCase: sl(),
      updateAddressUseCase: sl(),
    ),
  );
}
