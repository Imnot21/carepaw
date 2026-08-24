// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_dao.dart';

// ignore_for_file: type=lint
mixin _$QueueDaoMixin on DatabaseAccessor<CarePawDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $PetsTable get pets => attachedDatabase.pets;
  $AppointmentsTable get appointments => attachedDatabase.appointments;
  $QueueEntriesTable get queueEntries => attachedDatabase.queueEntries;
  QueueDaoManager get managers => QueueDaoManager(this);
}

class QueueDaoManager {
  final _$QueueDaoMixin _db;
  QueueDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$PetsTableTableManager get pets =>
      $$PetsTableTableManager(_db.attachedDatabase, _db.pets);
  $$AppointmentsTableTableManager get appointments =>
      $$AppointmentsTableTableManager(_db.attachedDatabase, _db.appointments);
  $$QueueEntriesTableTableManager get queueEntries =>
      $$QueueEntriesTableTableManager(_db.attachedDatabase, _db.queueEntries);
}
