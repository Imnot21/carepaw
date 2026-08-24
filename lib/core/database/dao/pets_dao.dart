import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/tables.dart';

part 'pets_dao.g.dart';

@DriftAccessor(tables: [Pets])
class PetsDao extends DatabaseAccessor<CarePawDatabase> with _$PetsDaoMixin {
  PetsDao(super.db);

  // ============ Queries ============

  /// Get pet by ID
  Future<Pet?> getById(int id) {
    return (select(pets)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// Get all pets for an owner
  Future<List<Pet>> getByOwner(int ownerId) {
    return (select(pets)
          ..where((p) => p.ownerId.equals(ownerId) & p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .get();
  }

  /// Get active pets for owner
  Stream<List<Pet>> watchByOwner(int ownerId) {
    return (select(pets)
          ..where((p) => p.ownerId.equals(ownerId) & p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .watch();
  }

  /// Search pets by name
  Future<List<Pet>> searchByName(int ownerId, String query) {
    return (select(pets)
          ..where((p) =>
              p.ownerId.equals(ownerId) &
              p.isActive.equals(true) &
              p.name.like('%$query%')))
        .get();
  }

  /// Get pet with owner info
  Future<Pet?> getWithOwner(int petId) {
    return (select(pets)..where((p) => p.id.equals(petId))).getSingleOrNull();
  }

  // ============ Mutations ============

  /// Create a new pet
  Future<int> createPet(PetsCompanion pet) {
    return into(pets).insert(pet);
  }

  /// Update pet
  Future<bool> updatePet(PetsCompanion pet) {
    return update(pets).replace(pet);
  }

  /// Soft delete pet
  Future<int> softDelete(int id) {
    return (update(pets)..where((p) => p.id.equals(id)))
        .write(PetsCompanion(isActive: const Value(false)));
  }

  /// Update pet weight
  Future<int> updateWeight(int id, double weightKg) {
    return (update(pets)..where((p) => p.id.equals(id)))
        .write(PetsCompanion(weightKg: Value(weightKg), updatedAt: Value(DateTime.now())));
  }

  /// Search all pets by name (for staff/admin)
  Future<List<Pet>> searchAllByName(String query) {
    return (select(pets)
          ..where((p) =>
              p.isActive.equals(true) &
              p.name.like('%$query%')))
        .get();
  }

  /// Watch pet by ID
  Stream<Pet?> watchById(int id) {
    return (select(pets)..where((p) => p.id.equals(id))).watchSingleOrNull();
  }

  /// Watch all active pets
  Stream<List<Pet>> watchAll() {
    return (select(pets)..where((p) => p.isActive.equals(true))).watch();
  }

  /// Restore soft-deleted pet
  Future<int> restore(int id) {
    return (update(pets)..where((p) => p.id.equals(id)))
        .write(PetsCompanion(isActive: const Value(true), updatedAt: Value(DateTime.now())));
  }

  /// Get all pets including soft-deleted
  Future<List<Pet>> getAllIncludingDeleted() {
    return (select(pets)..orderBy([(p) => OrderingTerm.desc(p.createdAt)])).get();
  }
}