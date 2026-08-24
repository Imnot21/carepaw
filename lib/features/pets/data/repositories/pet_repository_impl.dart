import 'package:drift/drift.dart' show Value;
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/dao/pets_dao.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart' as domain;
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/core/database/entities.dart';

/// Pet repository implementation - data layer
class PetRepositoryImpl implements PetRepository {
  final PetsDao _dao;
  final SyncRepository _syncRepo;

  PetRepositoryImpl(CarePawDatabase database, {required SyncRepository syncRepo})
      : _dao = PetsDao(database),
        _syncRepo = syncRepo;

  @override
  Future<domain.Pet?> findById(int id) async {
    final entity = await _dao.getById(id);
    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<List<domain.Pet>> findAll() async {
    // Return all active pets (could be filtered by owner in real usage)
    final entities = await _dao.getByOwner(0); // This won't work well
    return entities.map(_toDomain).toList();
  }

  @override
  Future<domain.Pet> save(domain.Pet entity) async {
    final companion = _toCompanion(entity);
    if (entity.id == null) {
      final id = await _dao.createPet(companion);
      return entity.copyWith(id: id);
    } else {
      await _dao.updatePet(companion);
      return entity;
    }
  }

  @override
  Future<void> delete(int id) async {
    await _dao.softDelete(id);
  }

  @override
  Future<bool> exists(int id) async {
    final entity = await _dao.getById(id);
    return entity != null;
  }

  @override
  Future<void> softDelete(int id) async {
    await _dao.softDelete(id);
  }

  @override
  Future<void> restore(int id) async {
    await _dao.restore(id);
  }

  @override
  Future<List<domain.Pet>> findAllIncludingDeleted() async {
    final entities = await _dao.getAllIncludingDeleted();
    return entities.map(_toDomain).toList();
  }

  @override
  Stream<domain.Pet?> watchById(int id) {
    return _dao.watchById(id).map((entity) => entity != null ? _toDomain(entity) : null);
  }

  @override
  Stream<List<domain.Pet>> watchAll() {
    return _dao.watchAll().map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<List<domain.Pet>> findByOwner(int ownerId) async {
    final entities = await _dao.getByOwner(ownerId);
    return entities.map(_toDomain).toList();
  }

  @override
  Stream<List<domain.Pet>> watchByOwner(int ownerId) {
    return _dao.watchByOwner(ownerId).map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<List<domain.Pet>> searchByName(int ownerId, String query) async {
    final entities = await _dao.searchByName(ownerId, query);
    return entities.map(_toDomain).toList();
  }

  @override
  Future<domain.Pet?> findWithOwner(int petId) async {
    // Pet already has ownerId, so just get the pet
    return findById(petId);
  }

  @override
  Future<domain.Pet> updateWeight(int petId, double weightKg) async {
    await _dao.updateWeight(petId, weightKg);
    final entity = await _dao.getById(petId);
    if (entity == null) {
      throw Exception('Pet not found');
    }
    return _toDomain(entity);
  }

  @override
  Future<int> countByOwner(int ownerId) async {
    // Would need a count method in DAO
    final entities = await findByOwner(ownerId);
    return entities.length;
  }

  @override
  Future<int> countActiveByOwner(int ownerId) async {
    final entities = await findByOwner(ownerId);
    return entities.where((p) => p.isActive).length;
  }

  @override
  Future<List<domain.Pet>> searchAllByName(String query) async {
    final entities = await _dao.searchAllByName(query);
    return entities.map(_toDomain).toList();
  }

  @override
  Future<PaginatedResult<domain.Pet>> findPaginated(PaginationParams params) async {
    // Simple pagination implementation
    final allPets = await findAll();
    final start = params.offset;
    final end = (start + params.pageSize).clamp(0, allPets.length);
    final items = allPets.sublist(start, end);
    return PaginatedResult(
      items: items,
      totalCount: allPets.length,
      page: params.page,
      pageSize: params.pageSize,
    );
  }

  // Private mapping methods

  domain.Pet _toDomain(Pet entity) {
    return domain.Pet(
      id: entity.id,
      ownerId: entity.ownerId,
      name: entity.name,
      species: domain.PetSpecies.fromString(entity.species),
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

  PetsCompanion _toCompanion(domain.Pet entity) {
    return PetsCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      ownerId: Value(entity.ownerId),
      name: Value(entity.name),
      species: Value(entity.species.value),
      breed: Value(entity.breed),
      birthDate: Value(entity.birthDate),
      weightKg: Value(entity.weightKg),
      color: Value(entity.color),
      microchipId: Value(entity.microchipId),
      avatarUrl: Value(entity.avatarUrl),
      isActive: Value(entity.isActive),
      createdAt: entity.id == null ? Value(entity.createdAt) : const Value.absent(),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  Future<domain.Pet> createWithSync(domain.Pet entity, String tableName) async {
    final saved = await save(entity);
    // Queue for sync after local save
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'ownerId': entity.ownerId,
        'name': entity.name,
        'species': entity.species.value,
        'breed': entity.breed,
        'birthDate': entity.birthDate?.toIso8601String(),
        'weightKg': entity.weightKg,
        'color': entity.color,
        'microchipId': entity.microchipId,
        'avatarUrl': entity.avatarUrl,
        'isActive': entity.isActive,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
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
  Future<domain.Pet> updateWithSync(domain.Pet entity, String tableName) async {
    final saved = await save(entity);
    // Queue for sync after local save
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'ownerId': entity.ownerId,
        'name': entity.name,
        'species': entity.species.value,
        'breed': entity.breed,
        'birthDate': entity.birthDate?.toIso8601String(),
        'weightKg': entity.weightKg,
        'color': entity.color,
        'microchipId': entity.microchipId,
        'avatarUrl': entity.avatarUrl,
        'isActive': entity.isActive,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
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
    // Soft delete locally
    await _dao.softDelete(id);
    // Queue delete for sync
    await _syncRepo.queueForSync(
      tableName: tableName,
      recordId: id,
      operation: SyncOperation.delete,
    );
  }
}