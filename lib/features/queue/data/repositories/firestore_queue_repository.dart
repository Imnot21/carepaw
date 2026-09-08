import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/firebase/firestore_id_sequence.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/repositories/base_repository.dart';
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
  })  : _firestore = firestore,
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
    return doc == null ? null : QueueEntryDocMapper.fromData(doc.data() ?? const {});
  }

  @override
  Future<List<QueueEntry>> findAll() async {
    final all = await _findAllIncludingTerminal();
    return _activeOnly(all);
  }

  /// Fetch the live queue including completed/skipped so terminal states can be
  /// filtered in Dart without a composite index.
  Future<List<QueueEntry>> _findAllIncludingTerminal() async {
    final snapshot = await _queue.get();
    return snapshot.docs.map((doc) => QueueEntryDocMapper.fromData(doc.data())).toList();
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
    await save(existing.copyWith(
      status: QueueStatus.waiting,
      calledAt: null,
      roomEnteredAt: null,
      completedAt: null,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<List<QueueEntry>> findAllIncludingDeleted() => findAll();

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
    return _queue.snapshots().map((snapshot) {
      final entries = snapshot.docs
          .map((doc) => QueueEntryDocMapper.fromData(doc.data()))
          .toList();
      return _activeOnly(entries);
    });
  }

  // ============ PaginatedRepository<QueueEntry, int> ============

  @override
  Future<PaginatedResult<QueueEntry>> findPaginated(PaginationParams params) async {
    final all = await findAll();
    return _paginate(all, params);
  }

  // ============ QueueRepository ============

  @override
  Future<QueueEntry?> findByAppointment(int appointmentId) async {
    final snapshot = await _queue.where(FirestoreSchema.appointmentId, isEqualTo: appointmentId).limit(1).get();
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
    final active = await findAll();
    if (active.isEmpty) return 1;
    final maxPosition = active.map((e) => e.position).reduce((a, b) => a > b ? a : b);
    return maxPosition + 1;
  }

  @override
  Future<QueueEntry?> callNext() async {
    final active = await findAll();
    final waiting = active.where((e) => e.isWaiting).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    if (waiting.isEmpty) return null;
    final next = waiting.first;
    return save(next.call());
  }

  @override
  Future<QueueEntry> moveToRoom(int queueId) async {
    final existing = await findById(queueId);
    if (existing == null) throw Exception('Queue entry not found');
    if (!existing.canMoveToRoom) throw Exception('Queue entry cannot be moved to a room');
    return save(existing.moveToRoom(existing.room ?? _defaultRoom));
  }

  @override
  Future<QueueEntry> complete(int queueId) async {
    final existing = await findById(queueId);
    if (existing == null) throw Exception('Queue entry not found');
    if (!existing.canComplete) throw Exception('Queue entry cannot be completed');
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
  Future<void> repositionQueue() async {
    final active = await findAll();
    active.sort((a, b) => a.position.compareTo(b.position));
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
  Future<QueueEntry> createWithSync(QueueEntry entity, String tableName) async => save(entity);

  @override
  Future<QueueEntry> updateWithSync(QueueEntry entity, String tableName) async => save(entity);

  @override
  Future<void> deleteWithSync(int id, String tableName) async => softDelete(id);

  // ============ Private helpers ============

  List<QueueEntry> _activeOnly(List<QueueEntry> entries) {
    final active = entries.where((e) => !e.isCompleted && !e.isSkipped).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return active;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDocByIntId(int id) async {
    final snapshot = await _queue.where(FirestoreSchema.id, isEqualTo: id).limit(1).get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first;
  }

  Future<List<QueueEntryWithDetails>> _enrichWithDetails(List<QueueEntry> entries) async {
    final result = <QueueEntryWithDetails>[];
    for (final entry in entries) {
      final appointment = await _appointmentRepository.findById(entry.appointmentId);
      if (appointment == null) continue;
      final pet = await _petRepository.findById(appointment.petId);
      final veterinarian = await _userRepository.findById(appointment.veterinarianId);
      if (pet == null || veterinarian == null) continue;
      result.add(QueueEntryWithDetails(
        queueEntry: entry,
        appointment: appointment,
        pet: pet,
        veterinarian: veterinarian,
      ));
    }
    return result;
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