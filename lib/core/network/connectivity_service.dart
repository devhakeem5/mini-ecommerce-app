import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps [Connectivity] to provide a clean boolean stream
/// indicating network availability.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Emits `true` when connected, `false` when disconnected.
  /// Uses `distinct()` to avoid duplicate events.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.any((r) => r != ConnectivityResult.none);
    }).distinct();
  }

  /// Checks the current connectivity status immediately.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
