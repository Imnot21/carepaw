import 'package:drift/drift.dart' show Value, OrderingTerm;
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/dao/medical_records_dao.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/features/medical_records/domain/repositories/medical_record_repository.dart';
import 'package:carepaw/features/medical_records/domain/entities/medical_record.dart' as domain;
import 'package:carepaw/features/pets/domain/entities/pet.dart' as pet_domain;
import 'package:carepaw/features/authentication/domain/entities/user.dart' as user_domain;
import 'package:carepaw/features/appointments/domain/entities/appointment.dart' as appointment_domain;
import 'package:carepaw/core/repositories/base_repository.dart';

/// Medical record repository implementation - data layer
/// Converts between Drift entities and domain entities
/// Medical records are append-only
class MedicalRecordRepositoryImpl implements MedicalRecordRepository, BaseRepository<domain.MedicalRecord, int> {
  final MedicalRecordsDao _dao;
  final SyncRepository _syncRepo;

  MedicalRecordRepositoryImpl(CarePawDatabase database, {required SyncRepository syncRepo})
      : _dao = MedicalRecordsDao(database),
        _syncRepo = syncRepo;

  @override
  Future<domain.MedicalRecord?> findById(int id) async {
    final entity = await _dao.getById(id);
    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<List<domain.MedicalRecord>> findByPet(int petId) async {
    final entities = await _dao.getByPet(petId);
    return entities.map(_toDomain).toList();
  }

  @override
  Stream<List<domain.MedicalRecord>> watchByPet(int petId) {
    return _dao.watchByPet(petId).map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<List<domain.MedicalRecord>> findByType(int petId, domain.MedicalRecordType recordType) async {
    final entities = await _dao.getByType(petId, recordType.value);
    return entities.map(_toDomain).toList();
  }

  @override
  Future<List<domain.MedicalRecord>> findByAppointment(int appointmentId) async {
    final entities = await _dao.getByAppointment(appointmentId);
    return entities.map(_toDomain).toList();
  }

  @override
  Future<domain.MedicalRecordWithDetails?> findWithDetails(int recordId) async {
    final entity = await _dao.getWithDetails(recordId);
    if (entity == null) return null;
    return _toDomainWithDetails(entity);
  }

  @override
  Future<List<domain.MedicalRecordWithDetails>> getRecent({int limit = 20}) async {
    final entities = await _dao.getRecent(limit: limit);
    return entities.map(_toDomainWithDetails).toList();
  }

  @override
  Future<domain.MedicalRecord> create(domain.MedicalRecord record) async {
    final companion = _toCompanion(record);
    final id = await _dao.createRecord(companion);
    return record.copyWith(id: id);
  }

  @override
  Future<domain.MedicalRecord> createVisitRecord({
    required int petId,
    required int veterinarianId,
    required int appointmentId,
    required String title,
    String? description,
    String? diagnosis,
    String? treatment,
    String? medications,
    String? attachments,
  }) async {
    final id = await _dao.createVisitRecord(
      petId: petId,
      veterinarianId: veterinarianId,
      appointmentId: appointmentId,
      title: title,
      description: description,
      diagnosis: diagnosis,
      treatment: treatment,
      medications: medications,
      attachments: attachments,
    );
    return domain.MedicalRecord(
      id: id,
      petId: petId,
      veterinarianId: veterinarianId,
      appointmentId: appointmentId,
      recordType: domain.MedicalRecordType.visit,
      title: title,
      description: description,
      diagnosis: diagnosis,
      treatment: treatment,
      medications: medications,
      attachments: attachments,
      recordedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<domain.MedicalRecord> createVaccinationRecord({
    required int petId,
    required int veterinarianId,
    int? appointmentId,
    required String title,
    String? description,
    String? medications,
  }) async {
    final id = await _dao.createVaccinationRecord(
      petId: petId,
      veterinarianId: veterinarianId,
      appointmentId: appointmentId,
      title: title,
      description: description,
      medications: medications,
    );
    return domain.MedicalRecord(
      id: id,
      petId: petId,
      veterinarianId: veterinarianId,
      appointmentId: appointmentId,
      recordType: domain.MedicalRecordType.vaccination,
      title: title,
      description: description,
      medications: medications,
      recordedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<domain.MedicalRecord> createAllergyRecord({
    required int petId,
    required int veterinarianId,
    required String title,
    required String description,
  }) async {
    final id = await _dao.createAllergyRecord(
      petId: petId,
      veterinarianId: veterinarianId,
      title: title,
      description: description,
    );
    return domain.MedicalRecord(
      id: id,
      petId: petId,
      veterinarianId: veterinarianId,
      recordType: domain.MedicalRecordType.allergy,
      title: title,
      description: description,
      recordedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<domain.MedicalRecord> createLabResultRecord({
    required int petId,
    required int veterinarianId,
    int? appointmentId,
    required String title,
    required String description,
  }) async {
    final id = await _dao.createLabResultRecord(
      petId: petId,
      veterinarianId: veterinarianId,
      appointmentId: appointmentId,
      title: title,
      description: description,
    );
    return domain.MedicalRecord(
      id: id,
      petId: petId,
      veterinarianId: veterinarianId,
      appointmentId: appointmentId,
      recordType: domain.MedicalRecordType.labResult,
      title: title,
      description: description,
      recordedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<PaginatedResult<domain.MedicalRecord>> findPaginated(PaginationParams params) async {
    // Use getRecent as a fallback for pagination
    final allRecords = await _dao.getRecent(limit: 1000);
    final items = allRecords.map((e) => _toDomain(e.record)).toList();
    final start = params.offset;
    final end = (start + params.pageSize).clamp(0, items.length);
    final paginatedItems = items.sublist(start, end);
    return PaginatedResult(
      items: paginatedItems,
      totalCount: items.length,
      page: params.page,
      pageSize: params.pageSize,
    );
  }

  // BaseRepository methods (append-only - some are no-ops or throw)
  @override
  Future<List<domain.MedicalRecord>> findAll() async {
    final allRecords = await _dao.getRecent(limit: 1000);
    return allRecords.map((e) => _toDomain(e.record)).toList();
  }

  @override
  Future<domain.MedicalRecord> save(domain.MedicalRecord entity) async {
    return create(entity);
  }

  @override
  Future<void> delete(int id) async {
    throw UnsupportedError('Medical records cannot be deleted (append-only)');
  }

  @override
  Future<bool> exists(int id) async {
    final entity = await _dao.getById(id);
    return entity != null;
  }

  Future<void> softDelete(int id) async {
    throw UnsupportedError('Medical records cannot be soft deleted (append-only)');
  }

  Future<void> restore(int id) async {
    throw UnsupportedError('Medical records cannot be restored (append-only)');
  }

  Future<List<domain.MedicalRecord>> findAllIncludingDeleted() async {
    return findAll();
  }

  @override
  Stream<domain.MedicalRecord?> watchById(int id) {
    return (_dao.select(_dao.medicalRecords)..where((m) => m.id.equals(id)))
        .watchSingleOrNull()
        .map((entity) => entity != null ? _toDomain(entity) : null);
  }

  @override
  Stream<List<domain.MedicalRecord>> watchAll() {
    // Use the DAO's select method to watch all medical records
    return _dao.watchAll().map((entities) => entities.map(_toDomain).toList());
  }

  // Helper method to convert MedicalRecordWithDetails to domain
  domain.MedicalRecordWithDetails _toDomainWithDetails(MedicalRecordWithDetails entity) {
    final record = _toDomain(entity.record);
    final pet = pet_domain.Pet(
      id: entity.pet.id,
      ownerId: entity.pet.ownerId,
      name: entity.pet.name,
      species: pet_domain.PetSpecies.fromString(entity.pet.species),
      breed: entity.pet.breed,
      birthDate: entity.pet.birthDate,
      weightKg: entity.pet.weightKg,
      color: entity.pet.color,
      microchipId: entity.pet.microchipId,
      avatarUrl: entity.pet.avatarUrl,
      isActive: entity.pet.isActive,
      createdAt: entity.pet.createdAt,
      updatedAt: entity.pet.updatedAt,
    );
    final vet = user_domain.User(
      id: entity.veterinarian.id,
      email: entity.veterinarian.email,
      fullName: entity.veterinarian.fullName,
      phone: entity.veterinarian.phone,
      role: user_domain.UserRole.fromString(entity.veterinarian.role),
      avatarUrl: entity.veterinarian.avatarUrl,
      isActive: entity.veterinarian.isActive,
      createdAt: entity.veterinarian.createdAt,
      updatedAt: entity.veterinarian.updatedAt,
    );
    final appointment = entity.appointment != null
        ? appointment_domain.Appointment(
            id: entity.appointment!.id,
            petId: entity.appointment!.petId,
            veterinarianId: entity.appointment!.veterinarianId,
            scheduledAt: entity.appointment!.scheduledAt,
            durationMinutes: entity.appointment!.durationMinutes,
            status: appointment_domain.AppointmentStatus.fromString(entity.appointment!.status),
            reason: entity.appointment!.reason,
            notes: entity.appointment!.notes,
            checkInAt: entity.appointment!.checkInAt,
            startedAt: entity.appointment!.startedAt,
            completedAt: entity.appointment!.completedAt,
            cancelledAt: entity.appointment!.cancelledAt,
            cancellationReason: entity.appointment!.cancellationReason,
            createdAt: entity.appointment!.createdAt,
            updatedAt: entity.appointment!.updatedAt,
          )
        : null;

    return domain.MedicalRecordWithDetails(
      record: record,
      pet: pet,
      veterinarian: vet,
      appointment: appointment,
    );
  }

  // Private mapping methods

  domain.MedicalRecord _toDomain(MedicalRecord entity) {
    return domain.MedicalRecord(
      id: entity.id,
      petId: entity.petId,
      veterinarianId: entity.veterinarianId,
      appointmentId: entity.appointmentId,
      recordType: domain.MedicalRecordType.fromString(entity.recordType),
      title: entity.title,
      description: entity.description,
      diagnosis: entity.diagnosis,
      treatment: entity.treatment,
      medications: entity.medications,
      attachments: entity.attachments,
      recordedAt: entity.recordedAt,
      createdAt: entity.createdAt,
    );
  }

  MedicalRecordsCompanion _toCompanion(domain.MedicalRecord entity) {
    return MedicalRecordsCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      petId: Value(entity.petId),
      veterinarianId: Value(entity.veterinarianId),
      appointmentId: Value(entity.appointmentId),
      recordType: Value(entity.recordType.value),
      title: Value(entity.title),
      description: Value(entity.description),
      diagnosis: Value(entity.diagnosis),
      treatment: Value(entity.treatment),
      medications: Value(entity.medications),
      attachments: Value(entity.attachments),
      recordedAt: Value(entity.recordedAt),
      createdAt: entity.id == null ? Value(entity.createdAt) : const Value.absent(),
    );
  }

  @override
  Future<domain.MedicalRecord> createWithSync(domain.MedicalRecord entity, String tableName) async {
    final saved = await create(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'petId': entity.petId,
        'veterinarianId': entity.veterinarianId,
        'appointmentId': entity.appointmentId,
        'recordType': entity.recordType.value,
        'title': entity.title,
        'description': entity.description,
        'diagnosis': entity.diagnosis,
        'treatment': entity.treatment,
        'medications': entity.medications,
        'attachments': entity.attachments,
        'recordedAt': entity.recordedAt.toIso8601String(),
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
  Future<domain.MedicalRecord> updateWithSync(domain.MedicalRecord entity, String tableName) async {
    // Medical records are append-only, but we can update certain fields
    final saved = await save(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'petId': entity.petId,
        'veterinarianId': entity.veterinarianId,
        'appointmentId': entity.appointmentId,
        'recordType': entity.recordType.value,
        'title': entity.title,
        'description': entity.description,
        'diagnosis': entity.diagnosis,
        'treatment': entity.treatment,
        'medications': entity.medications,
        'attachments': entity.attachments,
        'recordedAt': entity.recordedAt.toIso8601String(),
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
    // Medical records cannot be deleted - this is a no-op for local but we queue for sync
    await _syncRepo.queueForSync(
      tableName: tableName,
      recordId: id,
      operation: SyncOperation.delete,
    );
  }
}