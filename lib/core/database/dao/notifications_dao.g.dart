// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_dao.dart';

// ignore_for_file: type=lint
mixin _$NotificationsDaoMixin on DatabaseAccessor<CarePawDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $NotificationsTable get notifications => attachedDatabase.notifications;
  $NotificationPreferencesTable get notificationPreferences =>
      attachedDatabase.notificationPreferences;
  NotificationsDaoManager get managers => NotificationsDaoManager(this);
}

class NotificationsDaoManager {
  final _$NotificationsDaoMixin _db;
  NotificationsDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$NotificationsTableTableManager get notifications =>
      $$NotificationsTableTableManager(_db.attachedDatabase, _db.notifications);
  $$NotificationPreferencesTableTableManager get notificationPreferences =>
      $$NotificationPreferencesTableTableManager(
        _db.attachedDatabase,
        _db.notificationPreferences,
      );
}
