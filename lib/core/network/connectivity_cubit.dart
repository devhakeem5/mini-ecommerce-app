import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_service.dart';
import 'connectivity_state.dart';
import 'offline_sync_service.dart';

/// Manages real-time connectivity state using [ConnectivityService].
///
/// On reconnection (offline → online), triggers [OfflineSyncService]
/// to sync any pending offline actions.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  final ConnectivityService _connectivityService;
  final OfflineSyncService _syncService;

  StreamSubscription<bool>? _subscription;
  bool _wasOffline = false;

  ConnectivityCubit({
    required ConnectivityService connectivityService,
    required OfflineSyncService syncService,
  }) : _connectivityService = connectivityService,
       _syncService = syncService,
       super(const ConnectivityInitial()) {
    _init();
  }

  Future<void> _init() async {
    // Check initial connectivity
    final connected = await _connectivityService.isConnected;
    _wasOffline = !connected;

    if (connected) {
      emit(const ConnectivityOnline(wasOffline: false));
    } else {
      emit(const ConnectivityOffline());
    }

    // Listen for changes
    _subscription = _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        final reconnected = _wasOffline;
        _wasOffline = false;
        emit(ConnectivityOnline(wasOffline: reconnected));

        // Trigger sync on reconnection
        if (reconnected) {
          _triggerSync();
        }
      } else {
        _wasOffline = true;
        emit(const ConnectivityOffline());
      }
    });
  }

  Future<void> _triggerSync() async {
    try {
      await _syncService.syncPendingActions();
    } catch (e) {
      debugPrint('[ConnectivityCubit] Sync failed: $e');
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
