// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prescriptions_dao.dart';

// ignore_for_file: type=lint
mixin _$PrescriptionsDaoMixin on DatabaseAccessor<CarePawDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $PetsTable get pets => attachedDatabase.pets;
  $AppointmentsTable get appointments => attachedDatabase.appointments;
  $MedicalRecordsTable get medicalRecords => attachedDatabase.medicalRecords;
  $PrescriptionsTable get prescriptions => attachedDatabase.prescriptions;
  PrescriptionsDaoManager get managers => PrescriptionsDaoManager(this);
}

class PrescriptionsDaoManager {
  final _$PrescriptionsDaoMixin _db;
  PrescriptionsDaoManager(this._db);
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
  $$PrescriptionsTableTableManager get prescriptions =>
      $$PrescriptionsTableTableManager(_db.attachedDatabase, _db.prescriptions);
}
