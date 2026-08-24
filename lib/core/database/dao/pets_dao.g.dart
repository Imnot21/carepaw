// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pets_dao.dart';

// ignore_for_file: type=lint
mixin _$PetsDaoMixin on DatabaseAccessor<CarePawDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $PetsTable get pets => attachedDatabase.pets;
  PetsDaoManager get managers => PetsDaoManager(this);
}

class PetsDaoManager {
  final _$PetsDaoMixin _db;
  PetsDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$PetsTableTableManager get pets =>
      $$PetsTableTableManager(_db.attachedDatabase, _db.pets);
}
