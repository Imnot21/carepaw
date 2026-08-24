import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/tables.dart';

part 'medical_records_dao.g.dart';

@DriftAccessor(tables: [MedicalRecords, Pets, Users, Appointments])
class MedicalRecordsDao extends DatabaseAccessor<CarePawDatabase> with _$MedicalRecordsDaoMixin {
  MedicalRecordsDao(super.db);

  // ============ Queries ============

  /// Get medical record by ID
  Future<MedicalRecord?> getById(int id) {
    return (select(medicalRecords)..where((m) => m.id.equals(id))).getSingleOrNull();
  }

  /// Get all medical records for a pet (chronological)
  Future<List<MedicalRecord>> getByPet(int petId) {
    return (select(medicalRecords)
          ..where((m) => m.petId.equals(petId))
          ..orderBy([(m) => OrderingTerm.desc(m.recordedAt)]))
        .get();
  }

  /// Stream medical records for a pet (real-time)
  Stream<List<MedicalRecord>> watchByPet(int petId) {
    return (select(medicalRecords)
          ..where((m) => m.petId.equals(petId))
          ..orderBy([(m) => OrderingTerm.desc(m.recordedAt)]))
        .watch();
  }

  /// Stream all medical records (real-time)
  Stream<List<MedicalRecord>> watchAll() {
    return (select(medicalRecords)
          ..orderBy([(m) => OrderingTerm.desc(m.recordedAt)]))
        .watch();
  }

  /// Get medical records by type
  Future<List<MedicalRecord>> getByType(int petId, String recordType) {
    return (select(medicalRecords)
          ..where((m) => m.petId.equals(petId) & m.recordType.equals(recordType))
          ..orderBy([(m) => OrderingTerm.desc(m.recordedAt)]))
        .get();
  }

  /// Get medical records for an appointment
  Future<List<MedicalRecord>> getByAppointment(int appointmentId) {
    return (select(medicalRecords)
          ..where((m) => m.appointmentId.equals(appointmentId))
          ..orderBy([(m) => OrderingTerm.desc(m.recordedAt)]))
        .get();
  }

  /// Get medical record with details
  Future<MedicalRecordWithDetails?> getWithDetails(int recordId) {
    final query = select(medicalRecords).join([
      innerJoin(pets, pets.id.equalsExp(medicalRecords.petId)),
      innerJoin(users, users.id.equalsExp(medicalRecords.veterinarianId)),
      leftOuterJoin(appointments, appointments.id.equalsExp(medicalRecords.appointmentId)),
    ])..where(medicalRecords.id.equals(recordId));

    return query.map((row) {
      return MedicalRecordWithDetails(
        record: row.readTable(medicalRecords),
        pet: row.readTable(pets),
        veterinarian: row.readTable(users),
        appointment: row.readTableOrNull(appointments),
      );
    }).getSingleOrNull();
  }

  /// Get recent records across all pets (for vet dashboard)
  Future<List<MedicalRecordWithDetails>> getRecent({int limit = 20}) {
    final query = select(medicalRecords).join([
      innerJoin(pets, pets.id.equalsExp(medicalRecords.petId)),
      innerJoin(users, users.id.equalsExp(medicalRecords.veterinarianId)),
      leftOuterJoin(appointments, appointments.id.equalsExp(medicalRecords.appointmentId)),
    ])..orderBy([OrderingTerm.desc(medicalRecords.recordedAt)])..limit(limit);

    return query.map((row) {
      return MedicalRecordWithDetails(
        record: row.readTable(medicalRecords),
        pet: row.readTable(pets),
        veterinarian: row.readTable(users),
        appointment: row.readTableOrNull(appointments),
      );
    }).get();
  }

  // ============ Mutations ============

  /// Create medical record (append-only - no update/delete allowed)
  Future<int> createRecord(MedicalRecordsCompanion record) {
    return into(medicalRecords).insert(record);
  }

  /// Create visit record from appointment
  Future<int> createVisitRecord({
    required int petId,
    required int veterinarianId,
    required int appointmentId,
    required String title,
    String? description,
    String? diagnosis,
    String? treatment,
    String? medications,
    String? attachments,
  }) {
    return createRecord(MedicalRecordsCompanion(
      petId: Value(petId),
      veterinarianId: Value(veterinarianId),
      appointmentId: Value(appointmentId),
      recordType: const Value('VISIT'),
      title: Value(title),
      description: Value(description),
      diagnosis: Value(diagnosis),
      treatment: Value(treatment),
      medications: Value(medications),
      attachments: Value(attachments),
      recordedAt: Value(DateTime.now()),
    ));
  }

  /// Create vaccination record
  Future<int> createVaccinationRecord({
    required int petId,
    required int veterinarianId,
    int? appointmentId,
    required String title,
    String? description,
    String? medications,
  }) {
    return createRecord(MedicalRecordsCompanion(
      petId: Value(petId),
      veterinarianId: Value(veterinarianId),
      appointmentId: appointmentId != null ? Value(appointmentId) : const Value.absent(),
      recordType: const Value('VACCINATION'),
      title: Value(title),
      description: Value(description),
      medications: Value(medications),
      recordedAt: Value(DateTime.now()),
    ));
  }

  /// Create allergy record (append-only, never deleted)
  Future<int> createAllergyRecord({
    required int petId,
    required int veterinarianId,
    required String title,
    required String description,
  }) {
    return createRecord(MedicalRecordsCompanion(
      petId: Value(petId),
      veterinarianId: Value(veterinarianId),
      recordType: const Value('ALLERGY'),
      title: Value(title),
      description: Value(description),
      recordedAt: Value(DateTime.now()),
    ));
  }

  /// Create lab result record
  Future<int> createLabResultRecord({
    required int petId,
    required int veterinarianId,
    int? appointmentId,
    required String title,
    required String description,
  }) {
    return createRecord(MedicalRecordsCompanion(
      petId: Value(petId),
      veterinarianId: Value(veterinarianId),
      appointmentId: appointmentId != null ? Value(appointmentId) : const Value.absent(),
      recordType: const Value('LAB_RESULT'),
      title: Value(title),
      description: Value(description),
      recordedAt: Value(DateTime.now()),
    ));
  }
}

/// Medical record with related data
class MedicalRecordWithDetails {
  final MedicalRecord record;
  final Pet pet;
  final User veterinarian;
  final Appointment? appointment;

  MedicalRecordWithDetails({
    required this.record,
    required this.pet,
    required this.veterinarian,
    this.appointment,
  });
}