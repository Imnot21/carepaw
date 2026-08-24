import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/tables.dart';

part 'prescriptions_dao.g.dart';

@DriftAccessor(tables: [Prescriptions, Pets, MedicalRecords])
class PrescriptionsDao extends DatabaseAccessor<CarePawDatabase> with _$PrescriptionsDaoMixin {
  PrescriptionsDao(super.db);

  // ============ Queries ============

  /// Get prescription by ID
  Future<Prescription?> getById(int id) {
    return (select(prescriptions)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// Get prescriptions for a pet
  Future<List<Prescription>> getByPet(int petId) {
    return (select(prescriptions)
          ..where((p) => p.petId.equals(petId))
          ..orderBy([(p) => OrderingTerm.desc(p.prescribedAt)]))
        .get();
  }

  /// Stream prescriptions for a pet
  Stream<List<Prescription>> watchByPet(int petId) {
    return (select(prescriptions)
          ..where((p) => p.petId.equals(petId))
          ..orderBy([(p) => OrderingTerm.desc(p.prescribedAt)]))
        .watch();
  }

  /// Get active prescriptions for a pet
  Future<List<Prescription>> getActiveForPet(int petId) {
    return (select(prescriptions)
          ..where((p) => p.petId.equals(petId) & p.status.equals('ACTIVE'))
          ..orderBy([(p) => OrderingTerm.desc(p.prescribedAt)]))
        .get();
  }

  /// Get prescriptions needing refill
  Future<List<Prescription>> getNeedingRefill() {
    return (select(prescriptions)
          ..where((p) =>
              p.status.equals('ACTIVE') &
              p.refillsRemaining.isNotNull() &
              p.refillsRemaining.isSmallerOrEqualValue(0)))
        .get();
  }

  /// Get expiring prescriptions
  Future<List<Prescription>> getExpiringSoon({int days = 7}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    return (select(prescriptions)
          ..where((p) =>
              p.status.equals('ACTIVE') &
              p.expiresAt.isNotNull() &
              p.expiresAt.isBiggerOrEqualValue(now) &
              p.expiresAt.isSmallerOrEqualValue(future))
          ..orderBy([(p) => OrderingTerm.asc(p.expiresAt)]))
        .get();
  }

  /// Get prescriptions for a medical record
  Future<List<Prescription>> getByMedicalRecord(int medicalRecordId) {
    return (select(prescriptions)
          ..where((p) => p.medicalRecordId.equals(medicalRecordId))
          ..orderBy([(p) => OrderingTerm.desc(p.prescribedAt)]))
        .get();
  }

  // ============ Mutations ============

  /// Create prescription
  Future<int> createPrescription(PrescriptionsCompanion prescription) {
    return into(prescriptions).insert(prescription);
  }

  /// Update prescription
  Future<bool> updatePrescription(PrescriptionsCompanion prescription) {
    return update(prescriptions).replace(prescription);
  }

  /// Update status
  Future<int> updateStatus(int id, String status) {
    return (update(prescriptions)..where((p) => p.id.equals(id)))
        .write(PrescriptionsCompanion(
          status: Value(status),
        ));
  }

  /// Use a refill
  Future<int> useRefill(int id) {
    return transaction(() async {
      final prescription = await getById(id);
      if (prescription == null || prescription.refillsRemaining <= 0) return 0;

      final newRefills = prescription.refillsRemaining - 1;
      final newStatus = newRefills <= 0 ? 'COMPLETED' : 'ACTIVE';

      return (update(prescriptions)..where((p) => p.id.equals(id)))
          .write(PrescriptionsCompanion(
            refillsRemaining: Value(newRefills),
            status: Value(newStatus),
          ));
    });
  }
}