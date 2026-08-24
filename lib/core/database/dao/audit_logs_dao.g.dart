// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_logs_dao.dart';

// ignore_for_file: type=lint
mixin _$AuditLogsDaoMixin on DatabaseAccessor<CarePawDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $AuditLogsTable get auditLogs => attachedDatabase.auditLogs;
  AuditLogsDaoManager get managers => AuditLogsDaoManager(this);
}

class AuditLogsDaoManager {
  final _$AuditLogsDaoMixin _db;
  AuditLogsDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$AuditLogsTableTableManager get auditLogs =>
      $$AuditLogsTableTableManager(_db.attachedDatabase, _db.auditLogs);
}
