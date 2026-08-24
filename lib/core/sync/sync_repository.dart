/// Sync operation types
enum SyncOperation {
  insert('INSERT'),
  update('UPDATE'),
  delete('DELETE');

  const SyncOperation(this.value);
  final String value;

  static SyncOperation fromString(String value) {
    return SyncOperation.values.firstWhere(
      (op) => op.value == value,
      orElse: () => SyncOperation.insert,
    );
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final List<String> errors;
  final DateTime timestamp;

  const SyncResult({
    required this.success,
    required this.syncedCount,
    required this.failedCount,
    required this.errors,
    required this.timestamp,
  });

  factory SyncResult.success(int count) => SyncResult(
        success: true,
        syncedCount: count,
        failedCount: 0,
        errors: [],
        timestamp: DateTime.now(),
      );

  factory SyncResult.failure(List<String> errors) => SyncResult(
        success: false,
        syncedCount: 0,
        failedCount: errors.length,
        errors: errors,
        timestamp: DateTime.now(),
      );

  factory SyncResult.partial({
    required int synced,
    required int failed,
    required List<String> errors,
  }) => SyncResult(
        success: failed == 0,
        syncedCount: synced,
        failedCount: failed,
        errors: errors,
        timestamp: DateTime.now(),
      );
}

/// Sync status for UI indicators
enum SyncStatus {
  synced,
  syncing,
  pending,
  offline,
  error,
  conflict,
}

/// Sync metadata entry for tracking pending operations
class SyncMetadataEntry {
  final String id;
  final String tableName;
  final int recordId;
  final SyncOperation operation;
  final Map<String, dynamic>? payload;
  final int version;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final int retryCount;
  final String? lastError;
  final String deviceId;

  const SyncMetadataEntry({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.operation,
    this.payload,
    required this.version,
    required this.createdAt,
    this.syncedAt,
    required this.retryCount,
    this.lastError,
    required this.deviceId,
  });

  bool get isSynced => syncedAt != null;
  bool get isPending => syncedAt == null;
  bool get hasFailed => retryCount >= 5 && syncedAt == null;
}

/// Device info for this installation
class DeviceInfoEntry {
  final String id;
  final String? fcmToken;
  final String? firebaseUid;
  final DateTime createdAt;
  final DateTime? lastSyncAt;
  final String platform;
  final String appVersion;

  const DeviceInfoEntry({
    required this.id,
    this.fcmToken,
    this.firebaseUid,
    required this.createdAt,
    this.lastSyncAt,
    required this.platform,
    required this.appVersion,
  });
}

/// Repository interface for sync operations
abstract class SyncRepository {
  /// Queue a database operation for synchronization with Firestore.
  ///
  /// Called after successful local database mutations.
  Future<void> queueForSync({
    required String tableName,
    required int recordId,
    required SyncOperation operation,
    Map<String, dynamic>? payload,
  });

  /// Get all pending sync operations (not yet synced).
  Future<List<SyncMetadataEntry>> getPendingOperations({int limit = 100});

  /// Get pending operations for a specific table.
  Future<List<SyncMetadataEntry>> getPendingOperationsForTable(
    String tableName, {
    int limit = 50,
  });

  /// Mark a sync operation as successfully synced.
  Future<void> markSynced(String syncId);

  /// Mark a sync operation as failed with error message.
  Future<void> markFailed(String syncId, String error);

  /// Get the timestamp of the last successful sync.
  Future<DateTime?> getLastSyncTime();

  /// Update the last successful sync timestamp.
  Future<void> updateLastSyncTime(DateTime time);

  /// Get or create a unique device ID for this installation.
  Future<String> getOrCreateDeviceId();

  /// Update the FCM token for push notifications.
  Future<void> updateFcmToken(String token);

  /// Update the Firebase UID if user links accounts.
  Future<void> updateFirebaseUid(String firebaseUid);

  /// Get current device info.
  Future<DeviceInfoEntry?> getDeviceInfo();

  /// Get sync status for UI.
  Future<SyncStatus> getSyncStatus();

  /// Clear all synced operations older than [maxAge].
  Future<int> cleanupOldSyncedOperations({Duration maxAge = const Duration(days: 30)});

  /// Get count of pending operations.
  Future<int> getPendingCount();
}