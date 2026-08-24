// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_info_dao.dart';

// ignore_for_file: type=lint
mixin _$DeviceInfoDaoMixin on DatabaseAccessor<CarePawDatabase> {
  $DeviceInfoTable get deviceInfo => attachedDatabase.deviceInfo;
  DeviceInfoDaoManager get managers => DeviceInfoDaoManager(this);
}

class DeviceInfoDaoManager {
  final _$DeviceInfoDaoMixin _db;
  DeviceInfoDaoManager(this._db);
  $$DeviceInfoTableTableManager get deviceInfo =>
      $$DeviceInfoTableTableManager(_db.attachedDatabase, _db.deviceInfo);
}
