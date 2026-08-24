import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network status for sync decisions
enum NetworkStatus {
  wifi,
  cellular,
  offline,
  unknown,
}

/// Network monitor for detecting connectivity changes.
///
/// Uses connectivity_plus to monitor network state.
/// Only triggers sync on WiFi (configurable).
class NetworkMonitor {
  final Connectivity _connectivity;
  NetworkStatus _currentStatus = NetworkStatus.unknown;
  final List<VoidCallback> _listeners = [];

  NetworkMonitor(this._connectivity) {
    _init();
  }

  /// Current network status
  NetworkStatus get currentStatus => _currentStatus;

  /// Whether sync should proceed (WiFi only by default)
  bool get shouldSync => _currentStatus == NetworkStatus.wifi;

  /// Stream of network status changes
  Stream<NetworkStatus> get statusStream async* {
    yield _currentStatus;
    await for (final results in _connectivity.onConnectivityChanged) {
      final status = _mapConnectivityResults(results);
      if (status != _currentStatus) {
        _currentStatus = status;
        yield status;
        _notifyListeners();
      }
    }
  }

  /// Add a listener for network changes
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _init() {
    // Get initial status
    _checkInitialStatus();
    // Listen for changes
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  Future<void> _checkInitialStatus() async {
    final results = await _connectivity.checkConnectivity();
    // checkConnectivity returns List<ConnectivityResult> in newer versions
    _currentStatus = _mapConnectivityResults(results);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final status = _mapConnectivityResults(results);
    if (status != _currentStatus) {
      _currentStatus = status;
      _notifyListeners();
    }
  }

  NetworkStatus _mapConnectivityResults(List<ConnectivityResult> results) {
    // Prioritize WiFi over other connections
    if (results.contains(ConnectivityResult.wifi)) {
      return NetworkStatus.wifi;
    }
    if (results.contains(ConnectivityResult.ethernet)) {
      return NetworkStatus.wifi; // Treat ethernet as WiFi for sync
    }
    if (results.contains(ConnectivityResult.vpn)) {
      return NetworkStatus.wifi; // Treat VPN as WiFi for sync
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return NetworkStatus.cellular;
    }
    if (results.contains(ConnectivityResult.bluetooth)) {
      return NetworkStatus.offline;
    }
    if (results.contains(ConnectivityResult.satellite)) {
      return NetworkStatus.cellular; // Treat satellite as cellular
    }
    if (results.contains(ConnectivityResult.other)) {
      return NetworkStatus.offline;
    }
    // Default to offline if none or empty
    return NetworkStatus.offline;
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        if (kDebugMode) {
          print('NetworkMonitor listener error: $e');
        }
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _listeners.clear();
  }
}

/// Global network monitor instance
late final NetworkMonitor networkMonitor;

/// Initialize the global network monitor
Future<void> initNetworkMonitor() async {
  networkMonitor = NetworkMonitor(Connectivity());
  // Wait for initial status
  await Future.delayed(const Duration(milliseconds: 100));
}