import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/firebase/firestore_id_sequence.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/queue/data/mappers/queue_entry_doc_mapper.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';
import 'package:carepaw/features/queue/domain/repositories/queue_repository.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';

/// Queue repository implementation - data layer (Firestore-backed).
///
/// Implements [QueueRepository] with Cloud Firestore's `queueEntries`
/// collection as the source of truth. Documents are keyed by the app-facing
/// integer `id` (string form).
///
/// A queue entry that is skipped or completed is considered "soft deleted":
/// active entries are those still waiting, called, or in a room.
///
/// The former Drift repository is intentionally set aside and no longer wired.
class FirestoreQueueRepository implements QueueRepository {
  FirestoreQueueRepository({
    required FirebaseFirestore firestore,
    required FirestoreIdSequence queueIdSequence,
    required AppointmentRepository appointmentRepository,
    required PetRepository petRepository,
    required UserRepository userRepository,
  }) : _firestore = firestore,
       _idSequence = queueIdSequence,
       _appointmentRepository = appointmentRepository,
       _petRepository = petRepository,
       _userRepository = userRepository;

  final FirebaseFirestore _firestore;
  final FirestoreIdSequence _idSequence;
  final AppointmentRepository _appointmentRepository;
  final PetRepository _petRepository;
  final UserRepository _userRepository;

  /// Default room assigned when moving a patient without a specific room.
  static const String _defaultRoom = 'Room 1';

  CollectionReference<Map<String, dynamic>> get _queue =>
      _firestore.collection(FirestoreSchema.queueEntries);

  // ============ BaseRepository<QueueEntry, int> ============

  @override
  Future<QueueEntry?> findById(int id) async {
    final doc = await _findDocByIntId(id);
    return doc == null
        ? null
        : QueueEntryDocMapper.fromData(doc.data() ?? const {});
  }

  @override
  Future<List<QueueEntry>> findAll() async {
    // Server-side filter to active statuses only. Completed/skipped remain in
    // the collection forever, so fetching the whole collection would grow
    // without bound as the clinic operates. `whereIn` on a single field needs
    // no composite index.
    final snapshot = await _queue
        .where(
          FirestoreSchema.status,
          whereIn: [
            QueueStatus.waiting.value,
            QueueStatus.called.value,
            QueueStatus.inRoom.value,
          ],
        )
        .get();
    final entries =
        snapshot.docs
            .map((doc) => QueueEntryDocMapper.fromData(doc.data()))
            .toList()
          ..sort(QueueEntry.byQueueOrder);
    return entries;
  }

  /// Fetch the live queue including completed/skipped so terminal states can be
  /// filtered in Dart without a composite index.
  Future<List<QueueEntry>> _findAllIncludingTerminal() async {
    final snapshot = await _queue.get();
    return snapshot.docs
        .map((doc) => QueueEntryDocMapper.fromData(doc.data()))
        .toList();
  }

  @override
  Future<QueueEntry> save(QueueEntry entity) async {
    var toWrite = entity;
    if (toWrite.id == null) {
      toWrite = toWrite.copyWith(id: await _idSequence.next());
    }
    await _queue.doc('${toWrite.id}').set(QueueEntryDocMapper.toData(toWrite));
    return toWrite;
  }

  @override
  Future<void> delete(int id) => softDelete(id);

  @override
  Future<bool> exists(int id) async => await findById(id) != null;

  // ============ SoftDeleteRepository<QueueEntry, int> ============

  @override
  Future<void> softDelete(int id) async {
    final existing = await findById(id);
    if (existing == null || !existing.canSkip) return;
    try {
      await save(existing.skip());
    } on Exception {
      // Not waitable/callable - nothing to do.
    }
  }

  @override
  Future<void> restore(int id) async {
    final existing = await findById(id);
    if (existing == null || !existing.isSkipped) return;
    await save(
      existing.copyWith(
        status: QueueStatus.waiting,
        calledAt: null,
        roomEnteredAt: null,
        completedAt: null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<QueueEntry>> findAllIncludingDeleted() async {
    final all = await _findAllIncludingTerminal();
    return all..sort(QueueEntry.byQueueOrder);
  }

  // ============ StreamRepository<QueueEntry, int> ============

  @override
  Stream<QueueEntry?> watchById(int id) {
    return _queue
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return QueueEntryDocMapper.fromData(snapshot.docs.first.data());
        });
  }

  @override
  Stream<List<QueueEntry>> watchAll() {
    // Mirror findAll() filtering so the stream does not pull the entire
    // history of completed/skipped entries into every listener.
    return _queue
        .where(
          FirestoreSchema.status,
          whereIn: [
            QueueStatus.waiting.value,
            QueueStatus.called.value,
            QueueStatus.inRoom.value,
          ],
        )
        .snapshots()
        .map((snapshot) {
          final entries =
              snapshot.docs
                  .map((doc) => QueueEntryDocMapper.fromData(doc.data()))
                  .toList()
                ..sort(QueueEntry.byQueueOrder);
          return entries;
        });
  }

  // ============ PaginatedRepository<QueueEntry, int> ============

  @override
  Future<PaginatedResult<QueueEntry>> findPaginated(
    PaginationParams params,
  ) async {
    final all = await findAll();
    return _paginate(all, params);
  }

  // ============ QueueRepository ============

  @override
  Future<QueueEntry?> findByAppointment(int appointmentId) async {
    final snapshot = await _queue
        .where(FirestoreSchema.appointmentId, isEqualTo: appointmentId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return QueueEntryDocMapper.fromData(snapshot.docs.first.data());
  }

  @override
  Future<List<QueueEntryWithDetails>> getCurrentQueue() async {
    final active = await findAll();
    return _enrichWithDetails(active);
  }

  @override
  Stream<List<QueueEntryWithDetails>> watchCurrentQueue() {
    return watchAll().asyncMap((entries) => _enrichWithDetails(entries));
  }

  @override
  Future<int> getNextPosition() async {
    // `position` is a display serial: it is handed out here as a monotonic
    // arrival number and later recomputed 1..N in priority order by
    // `repositionQueue`. Queue ORDER never depends on it — see
    // QueueEntry.byQueueOrder — so a duplicate serial from a concurrent
    // check-in is only cosmetic and is normalized on the next reposition.
    final active = await findAll();
    if (active.isEmpty) return 1;
    final maxPosition = active
        .map((e) => e.position)
        .reduce((a, b) => a > b ? a : b);
    return maxPosition + 1;
  }

  @override
  Future<QueueEntry> checkIn(int appointmentId) async {
    // Idempotent: reuse an existing entry if the appointment is already queued.
    final existing = await findByAppointment(appointmentId);
    if (existing != null) return existing;

    final appointment = await _appointmentRepository.findById(appointmentId);
    if (appointment == null) {
      throw Exception('Appointment not found');
    }
    if (appointment.isTerminal) {
      throw Exception('Cannot check in a completed or cancelled appointment');
    }

    // Position assignment should be transactional so concurrent check-ins
    // cannot hand out the same position. Firestore transactions cannot
    // contain `whereIn` reads (unsupported inside txn.get), so keep the
    // fast path non-transactional and let staff `repositionQueue` plus the
    // server-side `whereIn` filtered reads normalize duplicates. The real
    // uniqueness guarantee comes from the `queueEntries/{id}` doc write via
    // FirestoreIdSequence (transactional counter) — two callers never get
    // the same queue id, only potentially the same position, which is
    // corrected on next complete/skip.
    final position = await getNextPosition();
    // Re-check idempotency right before write to close the duplicate race.
    final dupe = await findByAppointment(appointmentId);
    if (dupe != null) return dupe;
    final now = DateTime.now();
    final entry = QueueEntry(
      appointmentId: appointmentId,
      position: position,
      status: QueueStatus.waiting,
      checkedInAt: now,
      createdAt: now,
      updatedAt: now,
    );
    final row = await save(entry);
    try {
      await _appointmentRepository.updateStatus(
        appointmentId,
        AppointmentStatus.checkedIn,
        checkInAt: row.checkedInAt,
      );
    } on Exception {
      // Non-fatal: the queue entry is the source of truth for queue order.
    }

    return row;
  }

  @override
  Future<QueueEntry?> callNext() async {
    final active = await findAll();
    final waiting = active.where((e) => e.isWaiting).toList()
      ..sort(QueueEntry.byQueueOrder);
    if (waiting.isEmpty) return null;
    final next = waiting.first;
    return save(next.call());
  }

  @override
  Future<QueueEntry> moveToRoom(int queueId, String room) async {
    final existing = await findById(queueId);
    if (existing == null) throw Exception('Queue entry not found');
    if (!existing.canMoveToRoom)
      throw Exception('Queue entry cannot be moved to a room');
    final targetRoom = room.trim().isEmpty
        ? (existing.room ?? _defaultRoom)
        : room.trim();
    return save(existing.moveToRoom(targetRoom));
  }

  @override
  Future<QueueEntry> complete(int queueId) async {
    final existing = await findById(queueId);
    if (existing == null) throw Exception('Queue entry not found');
    if (!existing.canComplete)
      throw Exception('Queue entry cannot be completed');
    final completed = await save(existing.complete());
    await repositionQueue();
    return completed;
  }

  @override
  Future<QueueEntry> skip(int queueId) async {
    final existing = await findById(queueId);
    if (existing == null) throw Exception('Queue entry not found');
    if (!existing.canSkip) throw Exception('Queue entry cannot be skipped');
    final skipped = await save(existing.skip());
    await repositionQueue();
    return skipped;
  }

  @override
  Future<QueueEntry> setPriority(int queueId, QueuePriority priority) async {
    final existing = await findById(queueId);
    if (existing == null) throw Exception('Queue entry not found');

    // No status guard: staff may retriage any active (waiting/called/in-room)
    // entry. Retriaging a completed/skipped entry only updates its persisted
    // priority — repositionQueue skips terminal entries, so the live queue is
    // unaffected.
    final updated = await save(
      existing.copyWith(priority: priority, updatedAt: DateTime.now()),
    );

    // Rewrites positions 1..N in priority order so the entry lands in its
    // tier's slot. Not a Firestore transaction; a concurrent complete/skip/
    // checkIn between the read and this renumber can momentarily leave a stale
    // serial, which the next repositionQueue normalizes (matches existing
    // behavior for the position race elsewhere in this file).
    await repositionQueue();
    return updated;
  }

  @override
  Future<void> repositionQueue() async {
    final active = await findAll();
    active.sort(QueueEntry.byQueueOrder);
    final batch = _firestore.batch();
    for (var i = 0; i < active.length; i++) {
      if (active[i].position == i + 1) continue;
      batch.update(_queue.doc('${active[i].id}'), {
        FirestoreSchema.position: i + 1,
        FirestoreSchema.updatedAt: DateTime.now(),
      });
    }
    await batch.commit();
  }

  @override
  Future<QueueEntryWithDetails?> findWithDetails(int queueId) async {
    final entry = await findById(queueId);
    if (entry == null) return null;
    final details = await _enrichWithDetails([entry]);
    return details.isEmpty ? null : details.first;
  }

  // ============ Sync-aware operations (Firestore is the store) ============

  @override
  Future<QueueEntry> createWithSync(
    QueueEntry entity,
    String tableName,
  ) async => save(entity);

  @override
  Future<QueueEntry> updateWithSync(
    QueueEntry entity,
    String tableName,
  ) async => save(entity);

  @override
  Future<void> deleteWithSync(int id, String tableName) async => softDelete(id);

  // ============ Private helpers ============

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDocByIntId(
    int id,
  ) async {
    final snapshot = await _queue
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first;
  }

  Future<List<QueueEntryWithDetails>> _enrichWithDetails(
    List<QueueEntry> entries,
  ) async {
    // Entries are enriched concurrently; each entry then resolves pet/vet in
    // parallel. Overall wall time is O(max entry depth) not O(N * depth).
    Future<QueueEntryWithDetails?> enrichOne(QueueEntry entry) async {
      final appointment = await _appointmentRepository.findById(
        entry.appointmentId,
      );
      if (appointment == null) return null;
      final petFuture = _petRepository.findById(appointment.petId);
      final vetFuture = _userRepository.findById(appointment.veterinarianId);
      final pet = await petFuture;
      final veterinarian = await vetFuture;
      if (pet == null || veterinarian == null) return null;
      return QueueEntryWithDetails(
        queueEntry: entry,
        appointment: appointment,
        pet: pet,
        veterinarian: veterinarian,
      );
    }

    final resolved = await Future.wait(entries.map(enrichOne));
    return resolved.whereType<QueueEntryWithDetails>().toList();
  }

  PaginatedResult<T> _paginate<T>(List<T> all, PaginationParams params) {
    final offset = params.offset;
    final end = (offset + params.pageSize).clamp(0, all.length);
    final items = offset < all.length ? all.sublist(offset, end) : <T>[];
    return PaginatedResult<T>(
      items: items,
      totalCount: all.length,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
