// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointments_dao.dart';

// ignore_for_file: type=lint
mixin _$AppointmentsDaoMixin on DatabaseAccessor<CarePawDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $PetsTable get pets => attachedDatabase.pets;
  $AppointmentsTable get appointments => attachedDatabase.appointments;
  AppointmentsDaoManager get managers => AppointmentsDaoManager(this);
}

class AppointmentsDaoManager {
  final _$AppointmentsDaoMixin _db;
  AppointmentsDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$PetsTableTableManager get pets =>
      $$PetsTableTableManager(_db.attachedDatabase, _db.pets);
  $$AppointmentsTableTableManager get appointments =>
      $$AppointmentsTableTableManager(_db.attachedDatabase, _db.appointments);
}
