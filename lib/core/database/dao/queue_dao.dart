import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/tables.dart';

part 'queue_dao.g.dart';

@DriftAccessor(tables: [QueueEntries, Appointments, Pets, Users])
class QueueDao extends DatabaseAccessor<CarePawDatabase> with _$QueueDaoMixin {
  QueueDao(super.db);

  // ============ Queries ============

  /// Get queue entry by ID
  Future<QueueEntry?> getById(int id) {
    return (select(queueEntries)..where((q) => q.id.equals(id))).getSingleOrNull();
  }

  /// Get queue entry by appointment
  Future<QueueEntry?> getByAppointment(int appointmentId) {
    return (select(queueEntries)..where((q) => q.appointmentId.equals(appointmentId))).getSingleOrNull();
  }

  /// Get current queue (waiting/called/in-room)
  Future<List<QueueEntryWithDetails>> getCurrentQueue() {
    final query = select(queueEntries).join([
      innerJoin(appointments, appointments.id.equalsExp(queueEntries.appointmentId)),
      innerJoin(pets, pets.id.equalsExp(appointments.petId)),
      innerJoin(users, users.id.equalsExp(appointments.veterinarianId)),
    ])..where(queueEntries.status.isIn(['WAITING', 'CALLED', 'IN_ROOM']))
      ..orderBy([OrderingTerm.asc(queueEntries.position)]);

    return query.map((row) {
      return QueueEntryWithDetails(
        queueEntry: row.readTable(queueEntries),
        appointment: row.readTable(appointments),
        pet: row.readTable(pets),
        veterinarian: row.readTable(users),
      );
    }).get();
  }

  /// Stream current queue for real-time updates
  Stream<List<QueueEntryWithDetails>> watchCurrentQueue() {
    final query = select(queueEntries).join([
      innerJoin(appointments, appointments.id.equalsExp(queueEntries.appointmentId)),
      innerJoin(pets, pets.id.equalsExp(appointments.petId)),
      innerJoin(users, users.id.equalsExp(appointments.veterinarianId)),
    ])..where(queueEntries.status.isIn(['WAITING', 'CALLED', 'IN_ROOM']))
      ..orderBy([OrderingTerm.asc(queueEntries.position)]);

    return query.map((row) {
      return QueueEntryWithDetails(
        queueEntry: row.readTable(queueEntries),
        appointment: row.readTable(appointments),
        pet: row.readTable(pets),
        veterinarian: row.readTable(users),
      );
    }).watch();
  }

  /// Get next position in queue
  Future<int> getNextPosition() async {
    final query = select(queueEntries)
      ..where((q) => q.status.isIn(['WAITING', 'CALLED', 'IN_ROOM']))
      ..orderBy([(q) => OrderingTerm.desc(q.position)])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return (result?.position ?? 0) + 1;
  }

  // ============ Mutations ============

  /// Add to queue
  Future<int> addToQueue(QueueEntriesCompanion entry) {
    return into(queueEntries).insert(entry);
  }

  /// Update queue entry
  Future<bool> updateQueueEntry(QueueEntriesCompanion entry) {
    return update(queueEntries).replace(entry);
  }

  /// Call next patient
  Future<int> callNext() async {
    final nextEntry = await (select(queueEntries)
          ..where((q) => q.status.equals('WAITING'))
          ..orderBy([(q) => OrderingTerm.asc(q.position)]))
        .getSingleOrNull();

    if (nextEntry == null) return 0;

    return (update(queueEntries)..where((q) => q.id.equals(nextEntry.id)))
        .write(QueueEntriesCompanion(
          status: const Value('CALLED'),
          calledAt: Value(DateTime.now()),
        ));
  }

  /// Move patient to room
  Future<int> moveToRoom(int queueId) {
    return (update(queueEntries)..where((q) => q.id.equals(queueId)))
        .write(QueueEntriesCompanion(
          status: const Value('IN_ROOM'),
        ));
  }

  /// Complete queue entry
  Future<int> complete(int queueId) {
    return (update(queueEntries)..where((q) => q.id.equals(queueId)))
        .write(QueueEntriesCompanion(
          status: const Value('COMPLETED'),
        ));
  }

  /// Skip patient
  Future<int> skip(int queueId) {
    return (update(queueEntries)..where((q) => q.id.equals(queueId)))
        .write(QueueEntriesCompanion(
          status: const Value('SKIPPED'),
        ));
  }

  /// Reposition queue (after skip/complete)
  Future<void> repositionQueue() async {
    final entries = await (select(queueEntries)
          ..where((q) => q.status.isIn(['WAITING', 'CALLED', 'IN_ROOM']))
          ..orderBy([(q) => OrderingTerm.asc(q.position)]))
        .get();

    for (int i = 0; i < entries.length; i++) {
      if (entries[i].position != i + 1) {
        await (update(queueEntries)..where((q) => q.id.equals(entries[i].id)))
            .write(QueueEntriesCompanion(position: Value(i + 1)));
      }
    }
  }

  /// Watch queue entry by ID
  Stream<QueueEntry?> watchById(int id) {
    return (select(queueEntries)..where((q) => q.id.equals(id))).watchSingleOrNull();
  }

  /// Get queue entry with details by ID
  Future<QueueEntryWithDetails?> getWithDetails(int queueId) {
    final query = select(queueEntries).join([
      innerJoin(appointments, appointments.id.equalsExp(queueEntries.appointmentId)),
      innerJoin(pets, pets.id.equalsExp(appointments.petId)),
      innerJoin(users, users.id.equalsExp(appointments.veterinarianId)),
    ])..where(queueEntries.id.equals(queueId));

    return query.map((row) {
      return QueueEntryWithDetails(
        queueEntry: row.readTable(queueEntries),
        appointment: row.readTable(appointments),
        pet: row.readTable(pets),
        veterinarian: row.readTable(users),
      );
    }).getSingleOrNull();
  }
}

/// Queue entry with related data
class QueueEntryWithDetails {
  final QueueEntry queueEntry;
  final Appointment appointment;
  final Pet pet;
  final User veterinarian;

  QueueEntryWithDetails({
    required this.queueEntry,
    required this.appointment,
    required this.pet,
    required this.veterinarian,
  });
}