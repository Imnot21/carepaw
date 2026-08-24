// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vaccinations_dao.dart';

// ignore_for_file: type=lint
mixin _$VaccinationsDaoMixin on DatabaseAccessor<CarePawDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $PetsTable get pets => attachedDatabase.pets;
  $VaccinationsTable get vaccinations => attachedDatabase.vaccinations;
  VaccinationsDaoManager get managers => VaccinationsDaoManager(this);
}

class VaccinationsDaoManager {
  final _$VaccinationsDaoMixin _db;
  VaccinationsDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$PetsTableTableManager get pets =>
      $$PetsTableTableManager(_db.attachedDatabase, _db.pets);
  $$VaccinationsTableTableManager get vaccinations =>
      $$VaccinationsTableTableManager(_db.attachedDatabase, _db.vaccinations);
}
