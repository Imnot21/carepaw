import 'package:carepaw/core/firebase/date_field_codec.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';

/// Maps between Firestore `pets/{id}` documents and the domain [Pet].
///
/// Field names mirror the Drift table via [FirestoreSchema]. The document ID
/// is the string form of `Pet.id`.
class PetDocMapper {
  PetDocMapper._();

  /// Build a domain [Pet] from Firestore document data.
  static Pet fromData(Map<String, dynamic> data) {
    return Pet(
      id: data[FirestoreSchema.id] as int?,
      ownerId: (data[FirestoreSchema.ownerId] as num?)?.toInt() ?? 0,
      name: (data[FirestoreSchema.name] as String?) ?? '',
      species: PetSpecies.fromString(
        (data[FirestoreSchema.species] as String?) ?? '',
      ),
      breed: data[FirestoreSchema.breed] as String?,
      birthDate: DateFieldCodec.fromFirestoreDate(
        data[FirestoreSchema.birthDate],
      ),
      weightKg: (data[FirestoreSchema.weightKg] as num?)?.toDouble(),
      color: data[FirestoreSchema.color] as String?,
      microchipId: data[FirestoreSchema.microchipId] as String?,
      avatarUrl: data[FirestoreSchema.avatarUrl] as String?,
      isActive: (data[FirestoreSchema.isActive] as bool?) ?? true,
      createdAt:
          DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.createdAt]) ??
          DateTime.now(),
      updatedAt:
          DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.updatedAt]) ??
          DateTime.now(),
    );
  }

  /// Serialize a domain [Pet] to a Firestore document map.
  static Map<String, dynamic> toData(Pet pet) {
    return {
      FirestoreSchema.id: pet.id,
      FirestoreSchema.ownerId: pet.ownerId,
      FirestoreSchema.name: pet.name,
      FirestoreSchema.species: pet.species.value,
      FirestoreSchema.breed: pet.breed,
      FirestoreSchema.birthDate: DateFieldCodec.toFirestoreDate(pet.birthDate),
      FirestoreSchema.weightKg: pet.weightKg,
      FirestoreSchema.color: pet.color,
      FirestoreSchema.microchipId: pet.microchipId,
      FirestoreSchema.avatarUrl: pet.avatarUrl,
      FirestoreSchema.isActive: pet.isActive,
      FirestoreSchema.createdAt: DateFieldCodec.toFirestoreDate(pet.createdAt),
      FirestoreSchema.updatedAt: DateFieldCodec.toFirestoreDate(pet.updatedAt),
    };
  }
}
