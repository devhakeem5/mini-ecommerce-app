/// Represents the current network connectivity state.
abstract class ConnectivityState {
  const ConnectivityState();
}

/// Initial state before connectivity check completes.
class ConnectivityInitial extends ConnectivityState {
  const ConnectivityInitial();
}

/// Device has an active internet connection.
/// [wasOffline] is `true` when transitioning from offline → online
/// (i.e. reconnection), `false` on initial check.
class ConnectivityOnline extends ConnectivityState {
  final bool wasOffline;
  const ConnectivityOnline({this.wasOffline = false});
}

/// Device has no internet connection.
class ConnectivityOffline extends ConnectivityState {
  const ConnectivityOffline();
}
