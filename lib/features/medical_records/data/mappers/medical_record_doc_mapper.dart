import 'package:carepaw/core/firebase/date_field_codec.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/features/medical_records/domain/entities/medical_record.dart';

/// Maps between Firestore `medicalRecords/{id}` documents and the domain [MedicalRecord].
///
/// Field names mirror the Drift table via [FirestoreSchema]. The document ID
/// is the string form of `MedicalRecord.id`.
class MedicalRecordDocMapper {
  MedicalRecordDocMapper._();

  /// Build a domain [MedicalRecord] from Firestore document data.
  static MedicalRecord fromData(Map<String, dynamic> data) {
    return MedicalRecord(
      id: data[FirestoreSchema.id] as int?,
      petId: (data[FirestoreSchema.petId] as num?)?.toInt() ?? 0,
      veterinarianId:
          (data[FirestoreSchema.veterinarianId] as num?)?.toInt() ?? 0,
      appointmentId: (data[FirestoreSchema.appointmentId] as num?)?.toInt(),
      recordType: MedicalRecordType.fromString(
        (data[FirestoreSchema.recordType] as String?) ?? '',
      ),
      title: (data[FirestoreSchema.title] as String?) ?? '',
      description: data[FirestoreSchema.description] as String?,
      diagnosis: data[FirestoreSchema.diagnosis] as String?,
      treatment: data[FirestoreSchema.treatment] as String?,
      medications: data[FirestoreSchema.medications] as String?,
      attachments: data[FirestoreSchema.attachments] as String?,
      recordedAt:
          DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.recordedAt]) ??
          DateTime.now(),
      createdAt:
          DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.createdAt]) ??
          DateTime.now(),
    );
  }

  /// Serialize a domain [MedicalRecord] to a Firestore document map.
  static Map<String, dynamic> toData(MedicalRecord record) {
    return {
      FirestoreSchema.id: record.id,
      FirestoreSchema.petId: record.petId,
      FirestoreSchema.veterinarianId: record.veterinarianId,
      FirestoreSchema.appointmentId: record.appointmentId,
      FirestoreSchema.recordType: record.recordType.value,
      FirestoreSchema.title: record.title,
      FirestoreSchema.description: record.description,
      FirestoreSchema.diagnosis: record.diagnosis,
      FirestoreSchema.treatment: record.treatment,
      FirestoreSchema.medications: record.medications,
      FirestoreSchema.attachments: record.attachments,
      FirestoreSchema.recordedAt: DateFieldCodec.toFirestoreDate(
        record.recordedAt,
      ),
      FirestoreSchema.createdAt: DateFieldCodec.toFirestoreDate(
        record.createdAt,
      ),
    };
  }
}
