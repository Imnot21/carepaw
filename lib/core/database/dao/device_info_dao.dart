import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/tables.dart';

part 'device_info_dao.g.dart';

@DriftAccessor(tables: [DeviceInfo])
class DeviceInfoDao extends DatabaseAccessor<CarePawDatabase> with _$DeviceInfoDaoMixin {
  DeviceInfoDao(super.db);

  // ============ Queries ============

  /// Get device info (single row per device)
  Future<DeviceInfoData?> getDeviceInfo() {
    return select(deviceInfo).getSingleOrNull();
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() {
    return select(deviceInfo)
        .map((d) => d.lastSyncAt)
        .getSingleOrNull();
  }

  // ============ Mutations ============

  /// Insert new device info
  Future<int> insertDeviceInfo(DeviceInfoCompanion entry) {
    return into(deviceInfo).insert(entry);
  }

  /// Update last sync time
  Future<int> updateLastSyncTime(DateTime time) {
    return (update(deviceInfo))
        .write(DeviceInfoCompanion(lastSyncAt: Value(time)));
  }

  /// Update FCM token
  Future<int> updateFcmToken(String deviceId, String token) {
    return (update(deviceInfo)..where((d) => d.id.equals(deviceId)))
        .write(DeviceInfoCompanion(fcmToken: Value(token)));
  }

  /// Update Firebase UID
  Future<int> updateFirebaseUid(String deviceId, String firebaseUid) {
    return (update(deviceInfo)..where((d) => d.id.equals(deviceId)))
        .write(DeviceInfoCompanion(firebaseUid: Value(firebaseUid)));
  }
}