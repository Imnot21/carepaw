import 'package:carepaw/core/firebase/date_field_codec.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/features/medical_records/domain/entities/vaccination.dart';

/// Maps between Firestore `vaccinations/{id}` documents and the domain [Vaccination].
///
/// Field names mirror the Drift table via [FirestoreSchema]. The document ID
/// is the string form of `Vaccination.id`.
class VaccinationDocMapper {
  VaccinationDocMapper._();

  /// Build a domain [Vaccination] from Firestore document data.
  static Vaccination fromData(Map<String, dynamic> data) {
    return Vaccination(
      id: data[FirestoreSchema.id] as int?,
      petId: (data[FirestoreSchema.petId] as num?)?.toInt() ?? 0,
      veterinarianId:
          (data[FirestoreSchema.veterinarianId] as num?)?.toInt() ?? 0,
      vaccineName: (data[FirestoreSchema.vaccineName] as String?) ?? '',
      manufacturer: data[FirestoreSchema.manufacturer] as String?,
      batchNumber: data[FirestoreSchema.batchNumber] as String?,
      administeredAt:
          DateFieldCodec.fromFirestoreDate(
            data[FirestoreSchema.administeredAt],
          ) ??
          DateTime.now(),
      nextDueAt: DateFieldCodec.fromFirestoreDate(
        data[FirestoreSchema.nextDueAt],
      ),
      notes: data[FirestoreSchema.notes] as String?,
      createdAt:
          DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.createdAt]) ??
          DateTime.now(),
    );
  }

  /// Serialize a domain [Vaccination] to a Firestore document map.
  static Map<String, dynamic> toData(Vaccination vaccination) {
    return {
      FirestoreSchema.id: vaccination.id,
      FirestoreSchema.petId: vaccination.petId,
      FirestoreSchema.veterinarianId: vaccination.veterinarianId,
      FirestoreSchema.vaccineName: vaccination.vaccineName,
      FirestoreSchema.manufacturer: vaccination.manufacturer,
      FirestoreSchema.batchNumber: vaccination.batchNumber,
      FirestoreSchema.administeredAt: DateFieldCodec.toFirestoreDate(
        vaccination.administeredAt,
      ),
      FirestoreSchema.nextDueAt: DateFieldCodec.toFirestoreDate(
        vaccination.nextDueAt,
      ),
      FirestoreSchema.notes: vaccination.notes,
      FirestoreSchema.createdAt: DateFieldCodec.toFirestoreDate(
        vaccination.createdAt,
      ),
    };
  }
}
