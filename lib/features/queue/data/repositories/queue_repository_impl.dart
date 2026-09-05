import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/dao/queue_dao.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/features/queue/domain/repositories/queue_repository.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart' as domain;
import 'package:carepaw/features/appointments/domain/entities/appointment.dart' as domain_appointment;
import 'package:carepaw/features/pets/domain/entities/pet.dart' as domain_pet;
import 'package:carepaw/features/authentication/domain/entities/user.dart' as domain_user;
import 'package:carepaw/core/repositories/base_repository.dart';
/// Queue repository implementation - data layer
/// Converts between Drift entities and domain entities
class QueueRepositoryImpl implements QueueRepository {
  final QueueDao _dao;
  final SyncRepository syncRepo;

  QueueRepositoryImpl(CarePawDatabase database, {required this.syncRepo})
      : _dao = QueueDao(database);

  @override
  Future<domain.QueueEntry?> findById(int id) async {
    final entity = await _dao.getById(id);
    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<List<domain.QueueEntry>> findAll() async {
    final entities = await _dao.getCurrentQueue();
    return entities.map(_toDomainSimple).toList();
  }

  @override
  Future<domain.QueueEntry> save(domain.QueueEntry entity) async {
    final companion = _toCompanion(entity);
    if (entity.id == null) {
      final id = await _dao.addToQueue(companion);
      return entity.copyWith(id: id);
    } else {
      await _dao.updateQueueEntry(companion);
      return entity;
    }
  }

  @override
  Future<void> delete(int id) async {
    // Soft delete by marking as skipped
    await _dao.skip(id);
  }

  @override
  Future<bool> exists(int id) async {
    final entity = await _dao.getById(id);
    return entity != null;
  }

  @override
  Future<void> softDelete(int id) async {
    await delete(id);
  }

  @override
  Future<void> restore(int id) async {
    // Restore skipped queue entry back to waiting
    final entity = await _dao.getById(id);
    if (entity != null && entity.status == 'SKIPPED') {
      await _dao.updateQueueEntry(QueueEntriesCompanion(
        id: Value(id),
        status: const Value('WAITING'),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  @override
  Future<List<domain.QueueEntry>> findAllIncludingDeleted() async {
    return findAll();
  }

  @override
  Stream<domain.QueueEntry?> watchById(int id) {
    return _dao.watchById(id).map((entity) => entity != null ? _toDomain(entity) : null);
  }

  @override
  Stream<List<domain.QueueEntry>> watchAll() {
    return _dao.watchCurrentQueue().map((entities) => entities.map(_toDomainSimple).toList());
  }

  @override
  Future<domain.QueueEntry?> findByAppointment(int appointmentId) async {
    final entity = await _dao.getByAppointment(appointmentId);
    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<List<domain.QueueEntryWithDetails>> getCurrentQueue() async {
    final entities = await _dao.getCurrentQueue();
    return entities.map(_toDomainWithDetails).toList();
  }

  @override
  Stream<List<domain.QueueEntryWithDetails>> watchCurrentQueue() {
    return _dao.watchCurrentQueue().map((entities) => entities.map(_toDomainWithDetails).toList());
  }

  @override
  Future<int> getNextPosition() async {
    return await _dao.getNextPosition();
  }

  @override
  Future<domain.QueueEntry?> callNext() async {
    final queueId = await _dao.callNext();
    if (queueId == 0) return null;
    final entity = await _dao.getById(queueId);
    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<domain.QueueEntry> moveToRoom(int queueId) async {
    await _dao.moveToRoom(queueId);
    final entity = await _dao.getById(queueId);
    if (entity == null) {
      throw Exception('Queue entry not found');
    }
    return _toDomain(entity);
  }

  @override
  Future<domain.QueueEntry> complete(int queueId) async {
    await _dao.complete(queueId);
    final entity = await _dao.getById(queueId);
    if (entity == null) {
      throw Exception('Queue entry not found');
    }
    return _toDomain(entity);
  }

  @override
  Future<domain.QueueEntry> skip(int queueId) async {
    await _dao.skip(queueId);
    final entity = await _dao.getById(queueId);
    if (entity == null) {
      throw Exception('Queue entry not found');
    }
    return _toDomain(entity);
  }

  @override
  Future<void> repositionQueue() async {
    await _dao.repositionQueue();
  }

  @override
  Future<domain.QueueEntryWithDetails?> findWithDetails(int queueId) async {
    final entity = await _dao.getWithDetails(queueId);
    if (entity == null) return null;
    return _toDomainWithDetails(entity);
  }

  @override
  Future<PaginatedResult<domain.QueueEntry>> findPaginated(PaginationParams params) async {
    final allEntries = await findAll();
    final start = params.offset;
    final end = (start + params.pageSize).clamp(0, allEntries.length);
    final items = allEntries.sublist(start, end);
    return PaginatedResult(
      items: items,
      totalCount: allEntries.length,
      page: params.page,
      pageSize: params.pageSize,
    );
  }

  // Private mapping methods

  domain.QueueEntry _toDomain(QueueEntry entity) {
    return domain.QueueEntry(
      id: entity.id,
      appointmentId: entity.appointmentId,
      position: entity.position,
      status: domain.QueueStatus.fromString(entity.status),
      checkedInAt: entity.checkedInAt,
      calledAt: entity.calledAt,
      roomEnteredAt: entity.roomEnteredAt,
      completedAt: entity.completedAt,
      room: entity.room,
      estimatedWaitMinutes: entity.estimatedWaitMinutes,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  domain.QueueEntry _toDomainSimple(QueueEntryWithDetails entity) {
    return _toDomain(entity.queueEntry);
  }

  domain.QueueEntryWithDetails _toDomainWithDetails(QueueEntryWithDetails entity) {
    return domain.QueueEntryWithDetails(
      queueEntry: _toDomain(entity.queueEntry),
      appointment: _toDomainAppointment(entity.appointment),
      pet: _toDomainPet(entity.pet),
      veterinarian: _toDomainUser(entity.veterinarian),
    );
  }

  domain_appointment.Appointment _toDomainAppointment(Appointment entity) {
    return domain_appointment.Appointment(
      id: entity.id,
      petId: entity.petId,
      veterinarianId: entity.veterinarianId,
      scheduledAt: entity.scheduledAt,
      durationMinutes: entity.durationMinutes,
      status: domain_appointment.AppointmentStatus.fromString(entity.status),
      reason: entity.reason,
      notes: entity.notes,
      checkInAt: entity.checkInAt,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      cancelledAt: entity.cancelledAt,
      cancellationReason: entity.cancellationReason,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  domain_pet.Pet _toDomainPet(Pet entity) {
    return domain_pet.Pet(
      id: entity.id,
      ownerId: entity.ownerId,
      name: entity.name,
      species: domain_pet.PetSpecies.fromString(entity.species),
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

  domain_user.User _toDomainUser(User entity) {
    return domain_user.User(
      id: entity.id,
      email: entity.email,
      fullName: entity.fullName,
      phone: entity.phone,
      role: domain_user.UserRole.fromString(entity.role),
      avatarUrl: entity.avatarUrl,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  QueueEntriesCompanion _toCompanion(domain.QueueEntry entity) {
    return QueueEntriesCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      appointmentId: Value(entity.appointmentId),
      position: Value(entity.position),
      status: Value(entity.status.value),
      checkedInAt: Value(entity.checkedInAt),
      calledAt: Value(entity.calledAt),
      roomEnteredAt: Value(entity.roomEnteredAt),
      completedAt: Value(entity.completedAt),
      room: Value(entity.room),
      estimatedWaitMinutes: Value(entity.estimatedWaitMinutes),
      notes: Value(entity.notes),
      createdAt: entity.id == null ? Value(entity.createdAt) : const Value.absent(),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  Future<domain.QueueEntry> createWithSync(domain.QueueEntry entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'appointmentId': entity.appointmentId,
        'position': entity.position,
        'status': entity.status.value,
        'checkedInAt': entity.checkedInAt.toIso8601String(),
        'calledAt': entity.calledAt?.toIso8601String(),
        'roomEnteredAt': entity.roomEnteredAt?.toIso8601String(),
        'completedAt': entity.completedAt?.toIso8601String(),
        'room': entity.room,
        'estimatedWaitMinutes': entity.estimatedWaitMinutes,
        'notes': entity.notes,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt?.toIso8601String(),
      };
      await syncRepo.queueForSync(
        tableName: tableName,
        recordId: saved.id!,
        operation: SyncOperation.insert,
        payload: payload,
      );
    }
    return saved;
  }

  @override
  Future<domain.QueueEntry> updateWithSync(domain.QueueEntry entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'appointmentId': entity.appointmentId,
        'position': entity.position,
        'status': entity.status.value,
        'checkedInAt': entity.checkedInAt.toIso8601String(),
        'calledAt': entity.calledAt?.toIso8601String(),
        'roomEnteredAt': entity.roomEnteredAt?.toIso8601String(),
        'completedAt': entity.completedAt?.toIso8601String(),
        'room': entity.room,
        'estimatedWaitMinutes': entity.estimatedWaitMinutes,
        'notes': entity.notes,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt?.toIso8601String(),
      };
      await syncRepo.queueForSync(
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
    await _dao.skip(id); // Mark as skipped
    await syncRepo.queueForSync(
      tableName: tableName,
      recordId: id,
      operation: SyncOperation.delete,
    );
  }
}