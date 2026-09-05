import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart' show CarePawDatabase;
import 'package:carepaw/core/database/generated_types.dart' show DeviceInfoData, SyncMetadataData, DeviceInfoCompanion, SyncMetadataCompanion;
import 'package:carepaw/core/database/dao/sync_metadata_dao.dart';
import 'package:carepaw/core/database/dao/device_info_dao.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

/// Sync repository implementation using Drift database.
class SyncRepositoryImpl implements SyncRepository {
  final CarePawDatabase _database;
  final Uuid _uuid = const Uuid();

  SyncRepositoryImpl(this._database);

  // DAO getters (lazy to avoid circular dependency during init)
  SyncMetadataDao get _syncMetadataDao => SyncMetadataDao(_database);
  DeviceInfoDao get _deviceInfoDao => DeviceInfoDao(_database);

  @override
  Future<void> queueForSync({
    required String tableName,
    required int recordId,
    required SyncOperation operation,
    Map<String, dynamic>? payload,
  }) async {
    final deviceId = await getOrCreateDeviceId();
    final syncId = '$tableName:$recordId:${operation.value}:${DateTime.now().millisecondsSinceEpoch}';

    // For UPDATE operations, we might want to merge with existing pending operation
    if (operation == SyncOperation.update) {
      final existing = await _findPendingOperation(tableName, recordId);
      if (existing != null) {
        // Update existing pending operation with new payload
        await _updatePendingOperation(existing.id, payload);
        return;
      }
    }

    // For DELETE, remove any pending INSERT/UPDATE for same record
    if (operation == SyncOperation.delete) {
      await _removePendingOperations(tableName, recordId);
    }

    final companion = SyncMetadataCompanion(
      id: Value(syncId),
      tableNameCol: Value(tableName),
      recordId: Value(recordId),
      operation: Value(operation.value),
      payload: Value(payload != null ? jsonEncode(payload) : null),
      version: const Value(1),
      createdAt: Value(DateTime.now()),
      deviceId: Value(deviceId),
    );

    await _syncMetadataDao.insertSyncMetadata(companion);
  }

  @override
  Future<List<SyncMetadataEntry>> getPendingOperations({int limit = 100}) async {
    final results = await _syncMetadataDao.getUnsyncedOperations(limit: limit);
    return results.map(_toEntry).toList();
  }

  @override
  Future<List<SyncMetadataEntry>> getPendingOperationsForTable(
    String tableName, {
    int limit = 50,
  }) async {
    final results = await _syncMetadataDao.getUnsyncedOperationsForTable(tableName, limit: limit);
    return results.map(_toEntry).toList();
  }

  @override
  Future<void> markSynced(String syncId) async {
    await _syncMetadataDao.markSynced(syncId, DateTime.now());
  }

  @override
  Future<void> markFailed(String syncId, String error) async {
    await _syncMetadataDao.markFailed(syncId, error);
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    return _deviceInfoDao.getLastSyncTime();
  }

  @override
  Future<void> updateLastSyncTime(DateTime time) async {
    await _deviceInfoDao.updateLastSyncTime(time);
  }

  @override
  Future<String> getOrCreateDeviceId() async {
    final deviceInfo = await _deviceInfoDao.getDeviceInfo();
    if (deviceInfo != null) {
      return deviceInfo.id;
    }

    // Create new device info
    final deviceId = _uuid.v4();
    final companion = DeviceInfoCompanion(
      id: Value(deviceId),
      platform: Value(_getPlatform()),
      appVersion: Value('1.0.0'), // TODO: Get from package_info_plus
      createdAt: Value(DateTime.now()),
    );

    await _deviceInfoDao.insertDeviceInfo(companion);
    return deviceId;
  }

  @override
  Future<void> updateFcmToken(String token) async {
    final deviceId = await getOrCreateDeviceId();
    await _deviceInfoDao.updateFcmToken(deviceId, token);
  }

  @override
  Future<void> updateFirebaseUid(String firebaseUid) async {
    final deviceId = await getOrCreateDeviceId();
    await _deviceInfoDao.updateFirebaseUid(deviceId, firebaseUid);
  }

  @override
  Future<DeviceInfoEntry?> getDeviceInfo() async {
    final device = await _deviceInfoDao.getDeviceInfo();
    if (device == null) return null;
    return _toDeviceEntry(device);
  }

  @override
  Future<SyncStatus> getSyncStatus() async {
    final pendingCount = await getPendingCount();
    final deviceInfo = await getDeviceInfo();
    final lastSync = deviceInfo?.lastSyncAt;

    if (pendingCount == 0) {
      if (lastSync == null) return SyncStatus.pending;
      return SyncStatus.synced;
    }

    // Check if we have any failed operations
    final failedOps = await _syncMetadataDao.getFailedOperations();
    if (failedOps.isNotEmpty) return SyncStatus.error;

    return SyncStatus.pending;
  }

  @override
  Future<int> cleanupOldSyncedOperations({Duration maxAge = const Duration(days: 30)}) async {
    final cutoff = DateTime.now().subtract(maxAge);
    return _syncMetadataDao.deleteOldSyncedOperations(cutoff);
  }

  @override
  Future<int> getPendingCount() async {
    return _syncMetadataDao.getPendingCount();
  }

  // ============ Private Helpers ============

  Future<SyncMetadataData?> _findPendingOperation(String tableName, int recordId) async {
    return _syncMetadataDao.findPendingOperation(tableName, recordId);
  }

  Future<void> _updatePendingOperation(String syncId, Map<String, dynamic>? payload) async {
    await _syncMetadataDao.updatePayload(syncId, payload != null ? jsonEncode(payload) : null);
  }

  Future<void> _removePendingOperations(String tableName, int recordId) async {
    await _syncMetadataDao.deletePendingOperations(tableName, recordId);
  }

  SyncMetadataEntry _toEntry(SyncMetadataData data) {
    return SyncMetadataEntry(
      id: data.id,
      tableName: data.tableNameCol,
      recordId: data.recordId,
      operation: SyncOperation.fromString(data.operation),
      payload: data.payload != null ? jsonDecode(data.payload!) as Map<String, dynamic> : null,
      version: data.version,
      createdAt: data.createdAt,
      syncedAt: data.syncedAt,
      retryCount: data.retryCount,
      lastError: data.lastError,
      deviceId: data.deviceId,
    );
  }

  DeviceInfoEntry _toDeviceEntry(DeviceInfoData data) {
    return DeviceInfoEntry(
      id: data.id,
      fcmToken: data.fcmToken,
      firebaseUid: data.firebaseUid,
      createdAt: data.createdAt,
      lastSyncAt: data.lastSyncAt,
      platform: data.platform,
      appVersion: data.appVersion,
    );
  }

  String _getPlatform() {
    // This would ideally use Platform.operatingSystem but we avoid dart:io here
    // In practice, this is called from Flutter context where we can pass platform
    return 'android'; // Default, will be updated by platform-specific code
  }
}