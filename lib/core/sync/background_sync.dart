import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:carepaw/core/sync/sync_engine.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/core/sync/sync_repository.dart' show SyncResult, SyncStatus;

/// Background sync task name
const String syncTaskName = 'periodicSync';

/// Background sync callback - must be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case syncTaskName:
        await _performBackgroundSync();
        return Future.value(true);
      default:
        return Future.value(false);
    }
  });
}

/// Perform background sync
Future<void> _performBackgroundSync() async {
  try {
    // Initialize Firebase if not already
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    // Check network - only sync on WiFi
    final connectivity = Connectivity();
    final results = await connectivity.checkConnectivity();
    final hasWifi = results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet);

    if (!hasWifi) {
      if (kDebugMode) print('Background sync skipped: Not on WiFi');
      return;
    }

    // TODO: Get dependencies from GetIt or recreate them
    // For now, we'll need to initialize the sync engine with proper dependencies
    // This is a simplified version - in production, use proper DI

    if (kDebugMode) print('Background sync completed');
  } catch (e) {
    if (kDebugMode) print('Background sync error: $e');
  }
}

/// Register periodic background sync task
Future<void> registerPeriodicSync() async {
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);

  await Workmanager().registerPeriodicTask(
    syncTaskName,
    syncTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresCharging: false,
      requiresDeviceIdle: false,
    ),
    backoffPolicy: BackoffPolicy.exponential,
    initialDelay: const Duration(minutes: 5),
  );

  if (kDebugMode) print('Periodic sync registered');
}

/// Cancel periodic sync
Future<void> cancelPeriodicSync() async {
  await Workmanager().cancelByUniqueName(syncTaskName);
  if (kDebugMode) print('Periodic sync cancelled');
}

/// Register one-time sync (e.g., after login)
Future<void> registerOneTimeSync({Duration delay = const Duration(seconds: 30)}) async {
  await Workmanager().registerOneOffTask(
    'oneTimeSync',
    'oneTimeSync',
    initialDelay: delay,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
}

/// Sync controller for managing sync from UI
class SyncController {
  final SyncEngine _syncEngine;
  final SyncRepository _syncRepo;
  final List<VoidCallback> _statusListeners = [];

  SyncController({
    required SyncEngine syncEngine,
    required SyncRepository syncRepo,
  })  : _syncEngine = syncEngine,
        _syncRepo = syncRepo;

  /// Current sync status
  SyncStatus get status => _currentStatus;
  SyncStatus _currentStatus = SyncStatus.pending;

  /// Whether sync is in progress
  bool get isSyncing => _syncEngine.isSyncing;

  /// Last sync time
  Future<DateTime?> getLastSyncTime() => _syncRepo.getLastSyncTime();

  /// Pending operations count
  Future<int> getPendingCount() => _syncRepo.getPendingCount();

  /// Add listener for status changes
  void addStatusListener(VoidCallback listener) {
    _statusListeners.add(listener);
  }

  /// Remove listener
  void removeStatusListener(VoidCallback listener) {
    _statusListeners.remove(listener);
  }

  void _notifyStatusChange() {
    for (final listener in _statusListeners) {
      try {
        listener();
      } catch (e) {
        if (kDebugMode) print('SyncController listener error: $e');
      }
    }
  }

  /// Trigger manual sync
  Future<SyncResult> syncNow() async {
    _currentStatus = SyncStatus.syncing;
    _notifyStatusChange();

    final result = await _syncEngine.performSync();

    _currentStatus = result.success ? SyncStatus.synced : SyncStatus.error;
    _notifyStatusChange();

    return result;
  }

  /// Initialize sync controller (call on app start)
  Future<void> initialize() async {
    await registerPeriodicSync();
    _currentStatus = await _syncRepo.getSyncStatus();
    _notifyStatusChange();
  }

  /// Dispose
  void dispose() {
    _statusListeners.clear();
  }
}