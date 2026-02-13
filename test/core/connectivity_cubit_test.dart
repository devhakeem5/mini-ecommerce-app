import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/core/network/connectivity_cubit.dart';
import 'package:mini_commerce_app/core/network/connectivity_service.dart';
import 'package:mini_commerce_app/core/network/connectivity_state.dart';
import 'package:mini_commerce_app/core/network/offline_sync_service.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

void main() {
  late MockConnectivityService mockConnectivityService;
  late MockOfflineSyncService mockSyncService;

  setUp(() {
    mockConnectivityService = MockConnectivityService();
    mockSyncService = MockOfflineSyncService();
  });

  group('ConnectivityCubit', () {
    test('initial state is ConnectivityInitial', () {
      when(
        () => mockConnectivityService.isConnected,
      ).thenAnswer((_) => Future.delayed(const Duration(seconds: 10), () => true));
      when(
        () => mockConnectivityService.onConnectivityChanged,
      ).thenAnswer((_) => const Stream<bool>.empty());

      final cubit = ConnectivityCubit(
        connectivityService: mockConnectivityService,
        syncService: mockSyncService,
      );

      expect(cubit.state, isA<ConnectivityInitial>());
      addTearDown(() => cubit.close());
    });

    blocTest<ConnectivityCubit, ConnectivityState>(
      'emits [ConnectivityOnline] when initially connected',
      build: () {
        when(() => mockConnectivityService.isConnected).thenAnswer((_) async => true);
        when(
          () => mockConnectivityService.onConnectivityChanged,
        ).thenAnswer((_) => const Stream<bool>.empty());
        return ConnectivityCubit(
          connectivityService: mockConnectivityService,
          syncService: mockSyncService,
        );
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [const ConnectivityOnline(wasOffline: false)],
    );

    blocTest<ConnectivityCubit, ConnectivityState>(
      'emits [ConnectivityOffline] when initially disconnected',
      build: () {
        when(() => mockConnectivityService.isConnected).thenAnswer((_) async => false);
        when(
          () => mockConnectivityService.onConnectivityChanged,
        ).thenAnswer((_) => const Stream<bool>.empty());
        return ConnectivityCubit(
          connectivityService: mockConnectivityService,
          syncService: mockSyncService,
        );
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [const ConnectivityOffline()],
    );

    blocTest<ConnectivityCubit, ConnectivityState>(
      'emits ConnectivityOffline when connectivity drops',
      build: () {
        when(() => mockConnectivityService.isConnected).thenAnswer((_) async => true);
        final controller = StreamController<bool>();
        when(
          () => mockConnectivityService.onConnectivityChanged,
        ).thenAnswer((_) => controller.stream);

        Future.delayed(const Duration(milliseconds: 50), () {
          controller.add(false);
        });

        return ConnectivityCubit(
          connectivityService: mockConnectivityService,
          syncService: mockSyncService,
        );
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [const ConnectivityOnline(wasOffline: false), const ConnectivityOffline()],
    );

    blocTest<ConnectivityCubit, ConnectivityState>(
      'emits ConnectivityOnline(wasOffline: true) on reconnection and triggers sync',
      build: () {
        when(() => mockConnectivityService.isConnected).thenAnswer((_) async => false);
        when(() => mockSyncService.syncPendingActions()).thenAnswer((_) async {});

        final controller = StreamController<bool>();
        when(
          () => mockConnectivityService.onConnectivityChanged,
        ).thenAnswer((_) => controller.stream);

        Future.delayed(const Duration(milliseconds: 50), () {
          controller.add(true);
        });

        return ConnectivityCubit(
          connectivityService: mockConnectivityService,
          syncService: mockSyncService,
        );
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [const ConnectivityOffline(), const ConnectivityOnline(wasOffline: true)],
      verify: (_) {
        verify(() => mockSyncService.syncPendingActions()).called(1);
      },
    );
  });
}
