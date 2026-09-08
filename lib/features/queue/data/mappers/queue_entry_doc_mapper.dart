import 'package:carepaw/core/firebase/date_field_codec.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';

/// Maps between Firestore `queueEntries/{id}` documents and the domain [QueueEntry].
///
/// Field names mirror the Drift table via [FirestoreSchema]. The document ID
/// is the string form of `QueueEntry.id`.
class QueueEntryDocMapper {
  QueueEntryDocMapper._();

  /// Build a domain [QueueEntry] from Firestore document data.
  static QueueEntry fromData(Map<String, dynamic> data) {
    return QueueEntry(
      id: data[FirestoreSchema.id] as int?,
      appointmentId: (data[FirestoreSchema.appointmentId] as num?)?.toInt() ?? 0,
      position: (data[FirestoreSchema.position] as num?)?.toInt() ?? 0,
      status: QueueStatus.fromString((data[FirestoreSchema.statusQueue] as String?) ?? ''),
      checkedInAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.checkedInAt]) ?? DateTime.now(),
      calledAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.calledAt]),
      roomEnteredAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.roomEnteredAt]),
      completedAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.completedAtQueue]),
      room: data[FirestoreSchema.room] as String?,
      estimatedWaitMinutes: (data[FirestoreSchema.estimatedWaitMinutes] as num?)?.toInt(),
      notes: data[FirestoreSchema.notesQueue] as String?,
      createdAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.createdAt]) ?? DateTime.now(),
      updatedAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.updatedAt]),
    );
  }

  /// Serialize a domain [QueueEntry] to a Firestore document map.
  static Map<String, dynamic> toData(QueueEntry entry) {
    return {
      FirestoreSchema.id: entry.id,
      FirestoreSchema.appointmentId: entry.appointmentId,
      FirestoreSchema.position: entry.position,
      FirestoreSchema.statusQueue: entry.status.value,
      FirestoreSchema.checkedInAt: DateFieldCodec.toFirestoreDate(entry.checkedInAt),
      FirestoreSchema.calledAt: DateFieldCodec.toFirestoreDate(entry.calledAt),
      FirestoreSchema.roomEnteredAt: DateFieldCodec.toFirestoreDate(entry.roomEnteredAt),
      FirestoreSchema.completedAtQueue: DateFieldCodec.toFirestoreDate(entry.completedAt),
      FirestoreSchema.room: entry.room,
      FirestoreSchema.estimatedWaitMinutes: entry.estimatedWaitMinutes,
      FirestoreSchema.notesQueue: entry.notes,
      FirestoreSchema.createdAt: DateFieldCodec.toFirestoreDate(entry.createdAt),
      FirestoreSchema.updatedAt: DateFieldCodec.toFirestoreDate(entry.updatedAt),
    };
  }
}