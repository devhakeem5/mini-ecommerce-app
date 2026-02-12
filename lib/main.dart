import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '/core/di/service_locator.dart';
import '/core/localization/app_localizations.dart';
import '/presentation/cart/cubit/cart_cubit.dart';
import '/presentation/profile/cubit/locale_cubit.dart';
import '/presentation/profile/cubit/profile_cubit.dart';
import 'core/network/connectivity_cubit.dart';
import 'core/network/connectivity_state.dart';
import 'core/theme/app_theme.dart';
import 'domain/usecases/address/seed_default_addresses_usecase.dart';
import 'presentation/cart/cubit/address_cubit.dart';
import 'presentation/common/widgets/custom_toast.dart';
import 'presentation/products/products.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  await sl<SeedDefaultAddressesUseCase>()();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ProductsCubit>()..loadInitialProducts()),
        BlocProvider(create: (_) => sl<CategoriesCubit>()),
        BlocProvider(create: (_) => sl<CartCubit>()..loadCart()),
        BlocProvider(create: (_) => sl<ProfileCubit>()),
        BlocProvider(create: (_) => sl<ConnectivityCubit>()),
        BlocProvider(create: (_) => sl<AddressCubit>()..loadAddresses()),
        BlocProvider(create: (_) => sl<LocaleCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Mini Commerce',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: Locale(localeState.languageCode),
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: MultiBlocListener(
              listeners: [
                BlocListener<ConnectivityCubit, ConnectivityState>(
                  listener: (context, state) {
                    if (state is ConnectivityOffline) {
                      CustomToast.show(
                        context,
                        message: context.tr('offline_disconnected'),
                        type: ToastType.warning,
                      );
                    } else if (state is ConnectivityOnline && state.wasOffline) {
                      CustomToast.show(
                        context,
                        message: context.tr('connection_restored'),
                        type: ToastType.success,
                      );
                    }
                  },
                ),
                BlocListener<ProductsCubit, ProductsState>(
                  listener: (context, state) {
                    if (state is ProductsLoaded) {
                      context.read<CartCubit>().syncPrices(state.products);
                    }
                  },
                ),
              ],
              child: const HomePage(),
            ),
          );
        },
      ),
    );
  }
}
