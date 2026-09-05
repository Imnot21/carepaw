import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/dao/vaccinations_dao.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/features/medical_records/domain/repositories/vaccination_repository.dart';
import 'package:carepaw/features/medical_records/domain/entities/vaccination.dart' as domain;
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart' as pet_domain;
import 'package:carepaw/features/authentication/domain/entities/user.dart' as user_domain;

/// Vaccination repository implementation - data layer
/// Converts between Drift entities and domain entities
class VaccinationRepositoryImpl implements VaccinationRepository {
  final VaccinationsDao _dao;
  final SyncRepository _syncRepo;

  VaccinationRepositoryImpl(CarePawDatabase database, {required this._syncRepo})
      : _dao = VaccinationsDao(database);

  @override
  Future<domain.Vaccination?> findById(int id) async {
    final entity = await _dao.getById(id);
    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<List<domain.Vaccination>> findAll() async {
    final entities = await _dao.getAll();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<domain.Vaccination> save(domain.Vaccination entity) async {
    final companion = _toCompanion(entity);
    if (entity.id == null) {
      final id = await _dao.createVaccination(companion);
      return entity.copyWith(id: id);
    } else {
      await _dao.updateVaccination(companion);
      return entity;
    }
  }

  @override
  Future<void> delete(int id) async {
    throw UnsupportedError('Vaccination records cannot be deleted');
  }

  @override
  Future<bool> exists(int id) async {
    final entity = await _dao.getById(id);
    return entity != null;
  }

  Future<void> softDelete(int id) async {
    throw UnsupportedError('Vaccination records cannot be soft deleted');
  }

  Future<void> restore(int id) async {
    throw UnsupportedError('Vaccination records cannot be restored');
  }

  Future<List<domain.Vaccination>> findAllIncludingDeleted() async {
    return findAll();
  }

  @override
  Stream<domain.Vaccination?> watchById(int id) {
    return _dao.watchById(id).map((entity) => entity != null ? _toDomain(entity) : null);
  }

  @override
  Stream<List<domain.Vaccination>> watchAll() {
    return _dao.watchAll().map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<List<domain.Vaccination>> findByPet(int petId) async {
    final entities = await _dao.getByPet(petId);
    return entities.map(_toDomain).toList();
  }

  @override
  Stream<List<domain.Vaccination>> watchByPet(int petId) {
    return _dao.watchByPet(petId).map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<List<domain.Vaccination>> findDueSoon({int days = 30}) async {
    final entities = await _dao.getDueSoon(days: days);
    return entities.map(_toDomain).toList();
  }

  @override
  Future<List<domain.Vaccination>> findOverdue() async {
    final entities = await _dao.getOverdue();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<List<domain.VaccinationWithDetails>> findWithDetailsByPet(int petId) async {
    final entities = await _dao.getWithDetailsByPet(petId);
    return entities.map((e) => domain.VaccinationWithDetails(
      vaccination: _toDomain(e.vaccination),
      pet: _petToDomain(e.pet),
      veterinarian: _vetToDomain(e.veterinarian),
    )).toList();
  }

  @override
  Future<domain.Vaccination> create(domain.Vaccination vaccination) async {
    final companion = _toCompanion(vaccination);
    final id = await _dao.createVaccination(companion);
    return vaccination.copyWith(id: id);
  }

  @override
  Future<domain.Vaccination> update(domain.Vaccination vaccination) async {
    final companion = _toCompanion(vaccination);
    await _dao.updateVaccination(companion);
    return vaccination;
  }

  @override
  Future<int> countDueSoon(int petId, {int days = 30}) async {
    final entities = await findByPet(petId);
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    return entities.where((v) => v.nextDueAt != null && v.nextDueAt!.isAfter(now) && v.nextDueAt!.isBefore(future)).length;
  }

  @override
  Future<int> countOverdue(int petId) async {
    final entities = await findByPet(petId);
    final now = DateTime.now();
    return entities.where((v) => v.nextDueAt != null && v.nextDueAt!.isBefore(now)).length;
  }

  @override
  Future<PaginatedResult<domain.Vaccination>> findPaginated(PaginationParams params) async {
    // Simple implementation - would need proper DAO support
    final all = await findAll();
    final start = params.offset;
    final end = (start + params.pageSize).clamp(0, all.length);
    final items = all.sublist(start, end);
    return PaginatedResult(
      items: items,
      totalCount: all.length,
      page: params.page,
      pageSize: params.pageSize,
    );
  }

  // Private mapping methods

  domain.Vaccination _toDomain(Vaccination entity) {
    return domain.Vaccination(
      id: entity.id,
      petId: entity.petId,
      veterinarianId: entity.veterinarianId,
      vaccineName: entity.vaccineName,
      manufacturer: entity.manufacturer,
      batchNumber: entity.batchNumber,
      administeredAt: entity.administeredAt,
      nextDueAt: entity.nextDueAt,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  VaccinationsCompanion _toCompanion(domain.Vaccination entity) {
    return VaccinationsCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      petId: Value(entity.petId),
      veterinarianId: Value(entity.veterinarianId),
      vaccineName: Value(entity.vaccineName),
      manufacturer: Value(entity.manufacturer),
      batchNumber: Value(entity.batchNumber),
      administeredAt: Value(entity.administeredAt),
      nextDueAt: entity.nextDueAt != null ? Value(entity.nextDueAt!) : const Value.absent(),
      notes: Value(entity.notes),
      createdAt: entity.id == null ? Value(entity.createdAt) : const Value.absent(),
    );
  }

  pet_domain.Pet _petToDomain(Pet entity) {
    return pet_domain.Pet(
      id: entity.id,
      ownerId: entity.ownerId,
      name: entity.name,
      species: pet_domain.PetSpecies.fromString(entity.species),
      breed: entity.breed,
      birthDate: entity.birthDate,
      weightKg: entity.weightKg,
      color: entity.color,
      microchipId: entity.microchipId,
      avatarUrl: entity.avatarUrl,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  user_domain.User _vetToDomain(User entity) {
    return user_domain.User(
      id: entity.id,
      email: entity.email,
      fullName: entity.fullName,
      phone: entity.phone,
      role: user_domain.UserRole.fromString(entity.role),
      avatarUrl: entity.avatarUrl,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  @override
  Future<domain.Vaccination> createWithSync(domain.Vaccination entity, String tableName) async {
    final saved = await create(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'petId': entity.petId,
        'veterinarianId': entity.veterinarianId,
        'vaccineName': entity.vaccineName,
        'manufacturer': entity.manufacturer,
        'batchNumber': entity.batchNumber,
        'administeredAt': entity.administeredAt.toIso8601String(),
        'nextDueAt': entity.nextDueAt?.toIso8601String(),
        'notes': entity.notes,
        'createdAt': entity.createdAt.toIso8601String(),
      };
      await _syncRepo.queueForSync(
        tableName: tableName,
        recordId: saved.id!,
        operation: SyncOperation.insert,
        payload: payload,
      );
    }
    return saved;
  }

  @override
  Future<domain.Vaccination> updateWithSync(domain.Vaccination entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'petId': entity.petId,
        'veterinarianId': entity.veterinarianId,
        'vaccineName': entity.vaccineName,
        'manufacturer': entity.manufacturer,
        'batchNumber': entity.batchNumber,
        'administeredAt': entity.administeredAt.toIso8601String(),
        'nextDueAt': entity.nextDueAt?.toIso8601String(),
        'notes': entity.notes,
        'createdAt': entity.createdAt.toIso8601String(),
      };
      await _syncRepo.queueForSync(
        tableName: tableName,
        recordId: saved.id!,
        operation: SyncOperation.update,
        payload: payload,
      );
    }
    return saved;
  }

  @override
  Future<void> deleteWithSync(int id, String tableName) async {
    // Vaccinations cannot be deleted - this is a no-op for local but we queue for sync
    await _syncRepo.queueForSync(
      tableName: tableName,
      recordId: id,
      operation: SyncOperation.delete,
    );
  }
}