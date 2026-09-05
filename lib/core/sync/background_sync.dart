import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:carepaw/core/sync/sync_engine.dart';
import 'package:carepaw/core/sync/sync_repository.dart' show SyncResult, SyncStatus, SyncRepository;
import 'package:carepaw/core/sync/auth_sync_service.dart';
import 'package:carepaw/core/database/database.dart' as db;
import 'package:carepaw/core/database/dao/users_dao.dart';
import 'package:carepaw/core/notifications/notification_checker.dart';
import 'package:carepaw/core/notifications/local_notification_service.dart';

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
    if (kDebugMode) print('[BackgroundSync] Starting background sync...');

    // Initialize Firebase if not already
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) print('[BackgroundSync] Initializing Firebase...');
      await Firebase.initializeApp();
    } else {
      if (kDebugMode) print('[BackgroundSync] Firebase already initialized');
    }

    // Initialize local notifications for background display
    await LocalNotificationService.initialize();

    // Check network - only sync on WiFi
    final connectivity = Connectivity();
    final results = await connectivity.checkConnectivity();
    final hasWifi = results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet);

    if (!hasWifi) {
      if (kDebugMode) print('[BackgroundSync] Skipped: Not on WiFi (results: $results)');
      return;
    }

    if (kDebugMode) print('[BackgroundSync] Network OK (WiFi/ethernet available)');

    // Initialize database
    if (kDebugMode) print('[BackgroundSync] Opening database...');
    final database = db.CarePawDatabase();
    final usersDao = UsersDao(database);
    if (kDebugMode) print('[BackgroundSync] Database opened, usersDao created');

    // Check and show new notifications for all users
    // In a real implementation, we'd iterate over known user IDs
    // For now, we check for any unread notifications
    final notificationChecker = NotificationChecker(database);

    // Get all users with unread notifications and show them
    final usersWithNotifications = await database.customSelect(
      'SELECT DISTINCT user_id FROM notifications WHERE is_read = 0',
      readsFrom: {database.notifications},
    ).get();

    if (kDebugMode) print('[BackgroundSync] Users with unread notifications: ${usersWithNotifications.length}');
    for (final userMap in usersWithNotifications) {
      final userId = userMap.data['user_id'] as int?;
      if (userId != null) {
        await notificationChecker.checkAndShowNewNotifications(userId);
        await notificationChecker.checkAndShowPriorityNotifications(userId);
      }
    }

    // Sync local auth to Firebase Auth
    if (kDebugMode) print('[BackgroundSync] Starting auth sync...');
    final authSyncService = AuthSyncService(
      usersDao: usersDao,
      firebaseAuth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );

    final authSyncResult = await authSyncService.syncLocalUsersToFirebase();
    if (kDebugMode) {
      print('[BackgroundSync] Auth sync result: $authSyncResult');
    }

    // TODO: Get dependencies from GetIt or recreate them
    // For now, we'll need to initialize the sync engine with proper dependencies
    // This is a simplified version - in production, use proper DI

    if (kDebugMode) print('[BackgroundSync] Background sync completed');
  } catch (e) {
    if (kDebugMode) print('[BackgroundSync] Background sync error: $e');
  }
}

/// Register periodic background sync task
Future<void> registerPeriodicSync() async {
  await Workmanager().initialize(callbackDispatcher);

  await Workmanager().registerPeriodicTask(
    syncTaskName,
    syncTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.unmetered, // Prefer WiFi/unmetered
      requiresCharging: false,
      requiresDeviceIdle: false,
    ),
    backoffPolicy: BackoffPolicy.exponential,
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
  final UsersDao _usersDao;
  final List<VoidCallback> _statusListeners = [];

  SyncController({
    required this._syncEngine,
    required this._syncRepo,
    required this._usersDao,
  });

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

  /// Trigger immediate auth sync (local users → Firebase Auth)
  Future<AuthSyncResult> syncAuthNow() async {
    try {
      if (kDebugMode) print('[SyncController] syncAuthNow() called');

      // Initialize Firebase if not already
      if (Firebase.apps.isEmpty) {
        if (kDebugMode) print('[SyncController] Initializing Firebase...');
        await Firebase.initializeApp();
      } else {
        if (kDebugMode) print('[SyncController] Firebase already initialized');
      }

      if (kDebugMode) print('[SyncController] Creating AuthSyncService with usersDao: $_usersDao');

      final authSyncService = AuthSyncService(
        usersDao: _usersDao,
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );

      if (kDebugMode) print('[SyncController] Calling syncLocalUsersToFirebase()...');
      final result = await authSyncService.syncLocalUsersToFirebase();
      if (kDebugMode) {
        print('[SyncController] Manual auth sync result: $result');
      }
      return result;
    } catch (e) {
      if (kDebugMode) print('[SyncController] Manual auth sync error: $e');
      final errorResult = AuthSyncResult()
        ..failed = 1
        ..errors.add(e.toString());
      return errorResult;
    }
  }

  /// Trigger immediate auth sync (Firebase Auth users → local database)
  Future<AuthSyncResult> syncFirebaseUsersToLocal() async {
    try {
      // Initialize Firebase if not already
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final authSyncService = AuthSyncService(
        usersDao: _usersDao,
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );

      final result = await authSyncService.syncFirebaseUsersToLocal();
      if (kDebugMode) {
        print('Manual Firebase→Local auth sync result: $result');
      }
      return result;
    } catch (e) {
      if (kDebugMode) print('Manual Firebase→Local auth sync error: $e');
      final errorResult = AuthSyncResult()
        ..failed = 1
        ..errors.add(e.toString());
      return errorResult;
    }
  }

  /// Ensure local user exists for email (sync from Firebase if needed)
  Future<int?> ensureLocalUserExists(String email) async {
    try {
      // Initialize Firebase if not already
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final authSyncService = AuthSyncService(
        usersDao: _usersDao,
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );

      final localUserId = await authSyncService.ensureLocalUserExists(email);
      if (kDebugMode) {
        print('Ensure local user for $email: ${localUserId ?? "not found"}');
      }
      return localUserId;
    } catch (e) {
      if (kDebugMode) print('Ensure local user error: $e');
      return null;
    }
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