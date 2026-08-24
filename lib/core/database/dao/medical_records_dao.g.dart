// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_records_dao.dart';

// ignore_for_file: type=lint
mixin _$MedicalRecordsDaoMixin on DatabaseAccessor<CarePawDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $PetsTable get pets => attachedDatabase.pets;
  $AppointmentsTable get appointments => attachedDatabase.appointments;
  $MedicalRecordsTable get medicalRecords => attachedDatabase.medicalRecords;
  MedicalRecordsDaoManager get managers => MedicalRecordsDaoManager(this);
}

class MedicalRecordsDaoManager {
  final _$MedicalRecordsDaoMixin _db;
  MedicalRecordsDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$PetsTableTableManager get pets =>
      $$PetsTableTableManager(_db.attachedDatabase, _db.pets);
  $$AppointmentsTableTableManager get appointments =>
      $$AppointmentsTableTableManager(_db.attachedDatabase, _db.appointments);
  $$MedicalRecordsTableTableManager get medicalRecords =>
      $$MedicalRecordsTableTableManager(
        _db.attachedDatabase,
        _db.medicalRecords,
      );
}
