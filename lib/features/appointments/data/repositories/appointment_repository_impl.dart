import 'package:drift/drift.dart' show Value;
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/dao/appointments_dao.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart' as domain;
import 'package:carepaw/features/pets/domain/entities/pet.dart' as pet_domain;
import 'package:carepaw/features/authentication/domain/entities/user.dart' as user_domain;
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/core/database/entities.dart';

/// Mapper for Pet entity
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

/// Appointment repository implementation - data layer
/// Converts between Drift entities and domain entities
class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentsDao _dao;
  final SyncRepository _syncRepo;

  AppointmentRepositoryImpl(CarePawDatabase database, {required SyncRepository syncRepo})
      : _dao = AppointmentsDao(database),
        _syncRepo = syncRepo;

  @override
  Future<domain.Appointment?> findById(int id) async {
    final entity = await _dao.getById(id);
    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<List<domain.Appointment>> findAll() async {
    // Get all active appointments (not cancelled/no-show)
    final entities = await _dao.getAllActive();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<domain.Appointment> save(domain.Appointment entity) async {
    final companion = _toCompanion(entity);
    if (entity.id == null) {
      final id = await _dao.createAppointment(companion);
      return entity.copyWith(id: id);
    } else {
      await _dao.updateAppointment(companion);
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
    // For appointments, restore means changing status from CANCELLED/NO_SHOW back to REQUESTED
    await _dao.updateStatus(id, 'REQUESTED', cancelledAt: null, cancellationReason: null);
  }

  @override
  Future<List<domain.Appointment>> findAllIncludingDeleted() async {
    return findAll();
  }

  @override
  Stream<domain.Appointment?> watchById(int id) {
    return _dao.watchById(id).map((entity) => entity != null ? _toDomain(entity) : null);
  }

  @override
  Stream<List<domain.Appointment>> watchAll() {
    return _dao.watchAll().map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<List<domain.Appointment>> findByPet(int petId) async {
    final entities = await _dao.getByPet(petId);
    return entities.map(_toDomain).toList();
  }

  @override
  Stream<List<domain.Appointment>> watchByPet(int petId) {
    return _dao.watchByPet(petId).map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<List<domain.Appointment>> findByVeterinarian(int veterinarianId) async {
    final entities = await _dao.getByVeterinarian(veterinarianId);
    return entities.map(_toDomain).toList();
  }

  Future<List<domain.Appointment>> findByDateRange(DateTime start, DateTime end) async {
    // Using getByVeterinarian and filtering - would need proper DAO method
    final all = await findAll();
    return all.where((a) => a.scheduledAt.isAfter(start) && a.scheduledAt.isBefore(end)).toList();
  }

  @override
  Future<List<domain.Appointment>> findByStatus(domain.AppointmentStatus status) async {
    final entities = await _dao.getByStatus(status.value);
    return entities.map(_toDomain).toList();
  }

  Future<List<domain.Appointment>> findByPetAndStatus(int petId, domain.AppointmentStatus status) async {
    final entities = await _dao.getByPet(petId);
    return entities
        .where((e) => e.status == status.value)
        .map(_toDomain)
        .toList();
  }

  @override
  Future<domain.Appointment> updateStatus(int id, domain.AppointmentStatus status, {
    DateTime? checkInAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) async {
    final entity = await _dao.getById(id);
    if (entity == null) {
      throw Exception('Appointment not found');
    }
    final appointment = _toDomain(entity);

    String statusStr = status.value;
    await _dao.updateStatus(
      id,
      statusStr,
      checkInAt: checkInAt,
      startedAt: startedAt,
      completedAt: completedAt,
      cancelledAt: cancelledAt,
      cancellationReason: cancellationReason,
    );

    final updated = appointment.copyWith(
      status: status,
      checkInAt: checkInAt ?? appointment.checkInAt,
      startedAt: startedAt ?? appointment.startedAt,
      completedAt: completedAt ?? appointment.completedAt,
      cancelledAt: cancelledAt ?? appointment.cancelledAt,
      cancellationReason: cancellationReason ?? appointment.cancellationReason,
      updatedAt: DateTime.now(),
    );
    return updated;
  }

  @override
  Future<domain.Appointment> checkIn(int id) async {
    final entity = await _dao.getById(id);
    if (entity == null) {
      throw Exception('Appointment not found');
    }
    final appointment = _toDomain(entity);
    if (!appointment.canCheckIn) {
      throw Exception('Appointment cannot be checked in');
    }
    await _dao.checkIn(id);
    final updated = appointment.copyWith(
      status: domain.AppointmentStatus.checkedIn,
      checkInAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return updated;
  }

  @override
  Future<domain.Appointment> start(int id) async {
    final entity = await _dao.getById(id);
    if (entity == null) {
      throw Exception('Appointment not found');
    }
    final appointment = _toDomain(entity);
    if (!appointment.canStart) {
      throw Exception('Appointment cannot be started');
    }
    await _dao.start(id);
    final updated = appointment.copyWith(
      status: domain.AppointmentStatus.inProgress,
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return updated;
  }

  @override
  Future<domain.Appointment> complete(int id) async {
    final entity = await _dao.getById(id);
    if (entity == null) {
      throw Exception('Appointment not found');
    }
    final appointment = _toDomain(entity);
    if (!appointment.canComplete) {
      throw Exception('Appointment cannot be completed');
    }
    await _dao.complete(id);
    final updated = appointment.copyWith(
      status: domain.AppointmentStatus.completed,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return updated;
  }

  @override
  Future<domain.Appointment> cancel(int id, String reason) async {
    final entity = await _dao.getById(id);
    if (entity == null) {
      throw Exception('Appointment not found');
    }
    final appointment = _toDomain(entity);
    if (!appointment.canCancel) {
      throw Exception('Appointment cannot be cancelled');
    }
    await _dao.cancel(id, reason);
    final updated = appointment.copyWith(
      status: domain.AppointmentStatus.cancelled,
      cancelledAt: DateTime.now(),
      cancellationReason: reason,
      updatedAt: DateTime.now(),
    );
    return updated;
  }

  @override
  Future<domain.Appointment> reschedule(int id, DateTime newTime) async {
    final entity = await _dao.getById(id);
    if (entity == null) {
      throw Exception('Appointment not found');
    }
    final appointment = _toDomain(entity);
    final updated = appointment.copyWith(
      scheduledAt: newTime,
      status: domain.AppointmentStatus.requested,
      updatedAt: DateTime.now(),
    );
    return save(updated);
  }

  Future<domain.Appointment> assignVeterinarian(int appointmentId, int veterinarianId) async {
    final entity = await _dao.getById(appointmentId);
    if (entity == null) {
      throw Exception('Appointment not found');
    }
    final appointment = _toDomain(entity);
    final updated = appointment.copyWith(
      veterinarianId: veterinarianId,
      updatedAt: DateTime.now(),
    );
    return save(updated);
  }

  Future<domain.Appointment> updateNotes(int appointmentId, String notes) async {
    final entity = await _dao.getById(appointmentId);
    if (entity == null) {
      throw Exception('Appointment not found');
    }
    final appointment = _toDomain(entity);
    final updated = appointment.copyWith(
      notes: notes,
      updatedAt: DateTime.now(),
    );
    return save(updated);
  }

  @override
  Future<domain.AppointmentWithDetails?> findWithDetails(int appointmentId) async {
    final entity = await _dao.getWithDetails(appointmentId);
    if (entity == null) return null;

    // Map the pet and veterinarian entities
    final pet = entity.pet;
    final vet = entity.veterinarian;

    // We need to create domain entities
    // This is a simplified version - in practice you'd use mappers
    final domainPet = pet_domain.Pet(
      id: pet.id,
      ownerId: pet.ownerId,
      name: pet.name,
      species: pet_domain.PetSpecies.fromString(pet.species),
      breed: pet.breed,
      birthDate: pet.birthDate,
      weightKg: pet.weightKg,
      color: pet.color,
      microchipId: pet.microchipId,
      avatarUrl: pet.avatarUrl,
      isActive: pet.isActive,
      createdAt: pet.createdAt,
      updatedAt: pet.updatedAt,
    );

    final domainVet = user_domain.User(
      id: vet.id,
      email: vet.email,
      fullName: vet.fullName,
      phone: vet.phone,
      role: user_domain.UserRole.fromString(vet.role),
      avatarUrl: vet.avatarUrl,
      isActive: vet.isActive,
      createdAt: vet.createdAt,
      updatedAt: vet.updatedAt,
    );

    return domain.AppointmentWithDetails(
      appointment: _toDomain(entity.appointment),
      pet: domainPet,
      veterinarian: domainVet,
    );
  }

  @override
  Future<List<domain.Appointment>> findUpcomingForPet(int petId) async {
    final entities = await _dao.getUpcomingForPet(petId);
    return entities.map(_toDomain).toList();
  }

  @override
  Future<List<domain.Appointment>> findByOwner(int ownerId) async {
    final entities = await _dao.getByOwner(ownerId);
    return entities.map((e) => _toDomain(e.appointment)).toList();
  }

  @override
  Future<List<domain.Appointment>> findUpcomingForOwner(int ownerId) async {
    final entities = await _dao.getUpcomingForOwner(ownerId);
    return entities.map((e) => _toDomain(e.appointment)).toList();
  }

  @override
  Future<List<domain.AppointmentWithPetDetails>> findWithPetDetailsByOwner(int ownerId) async {
    final entities = await _dao.getWithPetDetailsByOwner(ownerId);
    return entities.map((e) => domain.AppointmentWithPetDetails(
      appointment: _toDomain(e.appointment),
      pet: _petToDomain(e.pet),
    )).toList();
  }

  @override
  Future<List<domain.AppointmentWithPetDetails>> findUpcomingWithPetDetailsForOwner(int ownerId) async {
    final entities = await _dao.getUpcomingWithPetDetailsForOwner(ownerId);
    return entities.map((e) => domain.AppointmentWithPetDetails(
      appointment: _toDomain(e.appointment),
      pet: _petToDomain(e.pet),
    )).toList();
  }

  @override
  Future<List<domain.Appointment>> findTodaysForVeterinarian(int veterinarianId) async {
    final entities = await _dao.getTodaysAppointments(veterinarianId);
    return entities.map(_toDomain).toList();
  }

  @override
  Future<int> countTodaysForVeterinarian(int veterinarianId) async {
    final entities = await _dao.getTodaysAppointments(veterinarianId);
    return entities.length;
  }

  @override
  Future<PaginatedResult<domain.Appointment>> findPaginated(PaginationParams params) async {
    final allAppointments = await findAll();
    final start = params.offset;
    final end = (start + params.pageSize).clamp(0, allAppointments.length);
    final items = allAppointments.sublist(start, end);
    return PaginatedResult(
      items: items,
      totalCount: allAppointments.length,
      page: params.page,
      pageSize: params.pageSize,
    );
  }

  @override
  Future<int> countByStatus(domain.AppointmentStatus status) async {
    final entities = await findByStatus(status);
    return entities.length;
  }

  Future<int> countByPet(int petId) async {
    final entities = await findByPet(petId);
    return entities.length;
  }

  Future<int> countUpcomingByPet(int petId) async {
    final entities = await _dao.getUpcomingForPet(petId);
    return entities.length;
  }

  // Private mapping methods

  domain.Appointment _toDomain(Appointment entity) {
    return domain.Appointment(
      id: entity.id,
      petId: entity.petId,
      veterinarianId: entity.veterinarianId,
      scheduledAt: entity.scheduledAt,
      durationMinutes: entity.durationMinutes,
      status: domain.AppointmentStatus.fromString(entity.status),
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

  AppointmentsCompanion _toCompanion(domain.Appointment entity) {
    return AppointmentsCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      petId: Value(entity.petId),
      veterinarianId: Value(entity.veterinarianId),
      scheduledAt: Value(entity.scheduledAt),
      durationMinutes: Value(entity.durationMinutes),
      status: Value(entity.status.value),
      reason: Value(entity.reason),
      notes: Value(entity.notes),
      checkInAt: Value(entity.checkInAt),
      startedAt: Value(entity.startedAt),
      completedAt: Value(entity.completedAt),
      cancelledAt: Value(entity.cancelledAt),
      cancellationReason: Value(entity.cancellationReason),
      createdAt: entity.id == null ? Value(entity.createdAt) : const Value.absent(),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  Future<domain.Appointment> createWithSync(domain.Appointment entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'petId': entity.petId,
        'veterinarianId': entity.veterinarianId,
        'scheduledAt': entity.scheduledAt.toIso8601String(),
        'durationMinutes': entity.durationMinutes,
        'status': entity.status.value,
        'reason': entity.reason,
        'notes': entity.notes,
        'checkInAt': entity.checkInAt?.toIso8601String(),
        'startedAt': entity.startedAt?.toIso8601String(),
        'completedAt': entity.completedAt?.toIso8601String(),
        'cancelledAt': entity.cancelledAt?.toIso8601String(),
        'cancellationReason': entity.cancellationReason,
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
  Future<domain.Appointment> updateWithSync(domain.Appointment entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'petId': entity.petId,
        'veterinarianId': entity.veterinarianId,
        'scheduledAt': entity.scheduledAt.toIso8601String(),
        'durationMinutes': entity.durationMinutes,
        'status': entity.status.value,
        'reason': entity.reason,
        'notes': entity.notes,
        'checkInAt': entity.checkInAt?.toIso8601String(),
        'startedAt': entity.startedAt?.toIso8601String(),
        'completedAt': entity.completedAt?.toIso8601String(),
        'cancelledAt': entity.cancelledAt?.toIso8601String(),
        'cancellationReason': entity.cancellationReason,
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
    await _dao.softDelete(id);
    await _syncRepo.queueForSync(
      tableName: tableName,
      recordId: id,
      operation: SyncOperation.delete,
    );
  }
}