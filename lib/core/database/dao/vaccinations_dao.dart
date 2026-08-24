import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/tables.dart';

part 'vaccinations_dao.g.dart';

@DriftAccessor(tables: [Vaccinations, Pets, Users])
class VaccinationsDao extends DatabaseAccessor<CarePawDatabase> with _$VaccinationsDaoMixin {
  VaccinationsDao(super.db);

  // ============ Queries ============

  /// Get vaccination by ID
  Future<Vaccination?> getById(int id) {
    return (select(vaccinations)..where((v) => v.id.equals(id))).getSingleOrNull();
  }

  /// Get all vaccinations
  Future<List<Vaccination>> getAll() {
    return (select(vaccinations)
          ..orderBy([(v) => OrderingTerm.desc(v.administeredAt)]))
        .get();
  }

  /// Stream a single vaccination by ID
  Stream<Vaccination?> watchById(int id) {
    return (select(vaccinations)..where((v) => v.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Stream all vaccinations
  Stream<List<Vaccination>> watchAll() {
    return (select(vaccinations)
          ..orderBy([(v) => OrderingTerm.desc(v.administeredAt)]))
        .watch();
  }

  /// Get vaccinations with pet and veterinarian details
  Future<List<VaccinationWithDetails>> getWithDetailsByPet(int petId) {
    final query = select(vaccinations).join([
      innerJoin(pets, pets.id.equalsExp(vaccinations.petId)),
      innerJoin(users, users.id.equalsExp(vaccinations.veterinarianId)),
    ])..where(vaccinations.petId.equals(petId));

    return query.map((row) {
      return VaccinationWithDetails(
        vaccination: row.readTable(vaccinations),
        pet: row.readTable(pets),
        veterinarian: row.readTable(users),
      );
    }).get();
  }

  /// Get all vaccinations for a pet
  Future<List<Vaccination>> getByPet(int petId) {
    return (select(vaccinations)
          ..where((v) => v.petId.equals(petId))
          ..orderBy([(v) => OrderingTerm.desc(v.administeredAt)]))
        .get();
  }

  /// Stream vaccinations for a pet
  Stream<List<Vaccination>> watchByPet(int petId) {
    return (select(vaccinations)
          ..where((v) => v.petId.equals(petId))
          ..orderBy([(v) => OrderingTerm.desc(v.administeredAt)]))
        .watch();
  }

  /// Get upcoming due vaccinations
  Future<List<Vaccination>> getDueSoon({int days = 30}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    return (select(vaccinations)
          ..where((v) =>
              v.nextDueAt.isNotNull() &
              v.nextDueAt.isBiggerOrEqualValue(now) &
              v.nextDueAt.isSmallerOrEqualValue(future))
          ..orderBy([(v) => OrderingTerm.asc(v.nextDueAt)]))
        .get();
  }

  /// Get overdue vaccinations
  Future<List<Vaccination>> getOverdue() {
    final now = DateTime.now();
    return (select(vaccinations)
          ..where((v) =>
              v.nextDueAt.isNotNull() &
              v.nextDueAt.isSmallerThanValue(now))
          ..orderBy([(v) => OrderingTerm.asc(v.nextDueAt)]))
        .get();
  }

  // ============ Mutations ============

  /// Create vaccination record
  Future<int> createVaccination(VaccinationsCompanion vaccination) {
    return into(vaccinations).insert(vaccination);
  }

  /// Update vaccination
  Future<bool> updateVaccination(VaccinationsCompanion vaccination) {
    return update(vaccinations).replace(vaccination);
  }
}

/// Vaccination with related data
class VaccinationWithDetails {
  final Vaccination vaccination;
  final Pet pet;
  final User veterinarian;

  VaccinationWithDetails({
    required this.vaccination,
    required this.pet,
    required this.veterinarian,
  });
}