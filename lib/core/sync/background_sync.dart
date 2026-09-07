import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
// Set aside with the drift→Firebase auth push: only the disabled blocks below
// reference these. Restore them if the bridges are ever revived.
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
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
    // Set aside with the drift→Firebase auth push (auth/users now live in the
    // cloud); restore this line if the auth bridges are ever revived.
    // final usersDao = UsersDao(database);
    if (kDebugMode) print('[BackgroundSync] Database opened');

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

    // DISABLED (Firestore-first): the local drift DB is set aside for auth/users.
    // We must never push local drift users into Firebase Auth, or the old local
    // accounts would be resurrected as Firebase accounts during background sync.
    // Kept here (commented out) for reference; the cloud is the source of truth.
    // final authSyncService = AuthSyncService(
    //   usersDao: usersDao,
    //   firebaseAuth: FirebaseAuth.instance,
    //   firestore: FirebaseFirestore.instance,
    // );
    // final authSyncResult = await authSyncService.syncLocalUsersToFirebase();
    // if (kDebugMode) {
    //   print('[BackgroundSync] Auth sync result: $authSyncResult');
    // }

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
  // Kept for the set-aside drift→Firebase auth bridges (see the disabled
  // syncAuthNow/syncFirebaseUsersToLocal/ensureLocalUserExists below).
  // ignore: unused_field
  final UsersDao _usersDao;
  final List<VoidCallback> _statusListeners = [];

  SyncController({
    required SyncEngine syncEngine,
    required SyncRepository syncRepo,
    required UsersDao usersDao,
  }) : _syncEngine = syncEngine,
       _syncRepo = syncRepo,
       _usersDao = usersDao;

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

  /// Trigger immediate auth sync (local users → Firebase Auth).
  ///
  /// DISABLED (Firestore-first): the local drift DB is set aside for
  /// auth/users, so there is nothing left to push and old drift accounts must
  /// never be resurrected into Firebase Auth. Returns an empty success result.
  Future<AuthSyncResult> syncAuthNow() async {
    if (kDebugMode) print('[SyncController] syncAuthNow() disabled (Firestore-first)');
    return AuthSyncResult();
  }

  /// Trigger immediate auth sync (Firebase Auth users → local database).
  ///
  /// DISABLED (Firestore-first): the local drift DB is set aside for
  /// auth/users; the cloud is the source of truth and nothing pulls back.
  Future<AuthSyncResult> syncFirebaseUsersToLocal() async {
    if (kDebugMode) print('[SyncController] syncFirebaseUsersToLocal() disabled (Firestore-first)');
    return AuthSyncResult();
  }

  /// Ensure local user exists for email (sync from Firebase if needed).
  ///
  /// DISABLED (Firestore-first): there is no local user table to ensure; the
  /// Firestore `users/{uid}` doc is authoritative.
  Future<int?> ensureLocalUserExists(String email) async {
    if (kDebugMode) print('[SyncController] ensureLocalUserExists() disabled (Firestore-first)');
    return null;
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