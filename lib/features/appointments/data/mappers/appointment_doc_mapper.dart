import 'package:carepaw/core/firebase/date_field_codec.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';

/// Maps between Firestore `appointments/{id}` documents and the domain [Appointment].
///
/// Field names mirror the Drift table via [FirestoreSchema]. The document ID
/// is the string form of `Appointment.id`.
class AppointmentDocMapper {
  AppointmentDocMapper._();

  /// Build a domain [Appointment] from Firestore document data.
  static Appointment fromData(Map<String, dynamic> data) {
    return Appointment(
      id: data[FirestoreSchema.id] as int?,
      petId: (data[FirestoreSchema.petId] as num?)?.toInt() ?? 0,
      veterinarianId: (data[FirestoreSchema.veterinarianId] as num?)?.toInt() ?? 0,
      scheduledAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.scheduledAt]) ?? DateTime.now(),
      durationMinutes: (data[FirestoreSchema.durationMinutes] as num?)?.toInt() ?? 30,
      status: AppointmentStatus.fromString((data[FirestoreSchema.status] as String?) ?? ''),
      reason: data[FirestoreSchema.reason] as String?,
      notes: data[FirestoreSchema.notes] as String?,
      checkInAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.checkInAt]),
      startedAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.startedAt]),
      completedAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.completedAt]),
      cancelledAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.cancelledAt]),
      cancellationReason: data[FirestoreSchema.cancellationReason] as String?,
      createdAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.createdAt]) ?? DateTime.now(),
      updatedAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.updatedAt]) ?? DateTime.now(),
    );
  }

  /// Serialize a domain [Appointment] to a Firestore document map.
  static Map<String, dynamic> toData(Appointment appointment) {
    return {
      FirestoreSchema.id: appointment.id,
      FirestoreSchema.petId: appointment.petId,
      FirestoreSchema.veterinarianId: appointment.veterinarianId,
      FirestoreSchema.scheduledAt: DateFieldCodec.toFirestoreDate(appointment.scheduledAt),
      FirestoreSchema.durationMinutes: appointment.durationMinutes,
      FirestoreSchema.status: appointment.status.value,
      FirestoreSchema.reason: appointment.reason,
      FirestoreSchema.notes: appointment.notes,
      FirestoreSchema.checkInAt: DateFieldCodec.toFirestoreDate(appointment.checkInAt),
      FirestoreSchema.startedAt: DateFieldCodec.toFirestoreDate(appointment.startedAt),
      FirestoreSchema.completedAt: DateFieldCodec.toFirestoreDate(appointment.completedAt),
      FirestoreSchema.cancelledAt: DateFieldCodec.toFirestoreDate(appointment.cancelledAt),
      FirestoreSchema.cancellationReason: appointment.cancellationReason,
      FirestoreSchema.createdAt: DateFieldCodec.toFirestoreDate(appointment.createdAt),
      FirestoreSchema.updatedAt: DateFieldCodec.toFirestoreDate(appointment.updatedAt),
    };
  }
}