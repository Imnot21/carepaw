import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/medical_records/domain/entities/medical_record.dart';

/// Medical record repository interface - domain layer contract
/// Note: Medical records are append-only (immutable), so no update/delete operations
abstract class MedicalRecordRepository
    implements
        StreamRepository<MedicalRecord, int>,
        PaginatedRepository<MedicalRecord, int>,
        BaseRepository<MedicalRecord, int> {
  /// Sync-aware operations
  @override
  Future<MedicalRecord> createWithSync(MedicalRecord entity, String tableName);

  /// Find all medical records for a pet (chronological)
  Future<List<MedicalRecord>> findByPet(int petId);

  /// Watch medical records for a pet (real-time)
  Stream<List<MedicalRecord>> watchByPet(int petId);

  /// Find medical records by type for a pet
  Future<List<MedicalRecord>> findByType(
    int petId,
    MedicalRecordType recordType,
  );

  /// Find medical records for an appointment
  Future<List<MedicalRecord>> findByAppointment(int appointmentId);

  /// Find medical record with details
  Future<MedicalRecordWithDetails?> findWithDetails(int recordId);

  /// Get recent records across all pets (for vet dashboard)
  Future<List<MedicalRecordWithDetails>> getRecent({int limit = 20});

  /// Create medical record (append-only)
  Future<MedicalRecord> create(MedicalRecord record);

  /// Create visit record from appointment
  Future<MedicalRecord> createVisitRecord({
    required int petId,
    required int veterinarianId,
    required int appointmentId,
    required String title,
    String? description,
    String? diagnosis,
    String? treatment,
    String? medications,
    String? attachments,
  });

  /// Create vaccination record
  Future<MedicalRecord> createVaccinationRecord({
    required int petId,
    required int veterinarianId,
    int? appointmentId,
    required String title,
    String? description,
    String? medications,
  });

  /// Create allergy record (append-only, never deleted)
  Future<MedicalRecord> createAllergyRecord({
    required int petId,
    required int veterinarianId,
    required String title,
    required String description,
  });

  /// Create lab result record
  Future<MedicalRecord> createLabResultRecord({
    required int petId,
    required int veterinarianId,
    int? appointmentId,
    required String title,
    required String description,
  });
}
