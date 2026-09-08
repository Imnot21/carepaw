import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/firebase/firestore_id_sequence.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/scanning/data/mappers/scan_record_doc_mapper.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/features/scanning/domain/repositories/scan_repository.dart';

/// Scan record repository implementation - data layer (Firestore-backed).
///
/// Implements [ScanRecordRepository] with Cloud Firestore's `scanRecords`
/// collection as the source of truth. Documents are keyed by the app-facing
/// integer `id` (string form).
///
/// Scans capture OCR output which is never trusted blindly - records move
/// through [ScanStatus.pending] -> confirmed/rejected by a human operator.
///
/// The former Drift repository is intentionally set aside and no longer wired.
class FirestoreScanRecordRepository implements ScanRecordRepository {
  FirestoreScanRecordRepository({
    required FirebaseFirestore firestore,
    required FirestoreIdSequence scanRecordIdSequence,
  })  : _firestore = firestore,
        _idSequence = scanRecordIdSequence;

  final FirebaseFirestore _firestore;
  final FirestoreIdSequence _idSequence;

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection(FirestoreSchema.scanRecords);

  // ============ BaseRepository<ScanRecord, int> ============

  @override
  Future<ScanRecord?> findById(int id) async {
    final doc = await _findDocByIntId(id);
    return doc == null ? null : ScanRecordDocMapper.fromData(doc.data() ?? const {});
  }

  @override
  Future<List<ScanRecord>> findAll() async {
    final snapshot = await _records.get();
    return snapshot.docs
        .map((doc) => ScanRecordDocMapper.fromData(doc.data()))
        .toList();
  }

  @override
  Future<ScanRecord> save(ScanRecord entity) async {
    var toWrite = entity;
    if (toWrite.id == null) {
      toWrite = toWrite.copyWith(id: await _idSequence.next());
    }
    await _records.doc('${toWrite.id}').set(ScanRecordDocMapper.toData(toWrite));
    return toWrite;
  }

  @override
  Future<void> delete(int id) => softDelete(id);

  @override
  Future<bool> exists(int id) async => await findById(id) != null;

  // ============ SoftDeleteRepository<ScanRecord, int> ============

  @override
  Future<void> softDelete(int id) async {
    final doc = await _findDocByIntId(id);
    await doc?.reference.delete();
  }

  @override
  Future<void> restore(int id) {
    throw UnsupportedError('Scan records cannot be restored after deletion');
  }

  @override
  Future<List<ScanRecord>> findAllIncludingDeleted() => findAll();

  // ============ StreamRepository<ScanRecord, int> ============

  @override
  Stream<ScanRecord?> watchById(int id) {
    return _records
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ScanRecordDocMapper.fromData(snapshot.docs.first.data());
    });
  }

  @override
  Stream<List<ScanRecord>> watchAll() {
    return _records.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ScanRecordDocMapper.fromData(doc.data()))
        .toList());
  }

  // ============ PaginatedRepository<ScanRecord, int> ============

  @override
  Future<PaginatedResult<ScanRecord>> findPaginated(PaginationParams params) async {
    final all = await findAll();
    return _paginate(all, params);
  }

  // ============ ScanRecordRepository ============

  @override
  Future<List<ScanRecord>> findByType(ScanType scanType) async {
    final snapshot = await _records.where(FirestoreSchema.scanType, isEqualTo: scanType.value).get();
    final scans = snapshot.docs
        .map((doc) => ScanRecordDocMapper.fromData(doc.data()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return scans;
  }

  @override
  Future<List<ScanRecord>> findByStatus(ScanStatus status) async {
    final snapshot = await _records.where(FirestoreSchema.statusScan, isEqualTo: status.value).get();
    return snapshot.docs
        .map((doc) => ScanRecordDocMapper.fromData(doc.data()))
        .toList();
  }

  @override
  Future<List<ScanRecord>> findPending() async {
    final pending = await findByStatus(ScanStatus.pending);
    return pending
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<ScanRecord> confirm(int id, int confirmedBy, String? corrections) async {
    final existing = await findById(id);
    if (existing == null) throw Exception('Scan record not found');
    return save(existing.copyWith(
      status: ScanStatus.confirmed,
      confirmedBy: confirmedBy,
      confirmedAt: DateTime.now(),
      corrections: corrections ?? existing.corrections,
    ));
  }

  @override
  Future<ScanRecord> reject(int id, int rejectedBy, String reason) async {
    final existing = await findById(id);
    if (existing == null) throw Exception('Scan record not found');
    return save(existing.copyWith(
      status: ScanStatus.rejected,
      confirmedBy: rejectedBy,
      confirmedAt: DateTime.now(),
      corrections: reason,
    ));
  }

  @override
  Future<ScanRecord> updateExtractedData(int id, String extractedData) async {
    final existing = await findById(id);
    if (existing == null) throw Exception('Scan record not found');
    return save(existing.copyWith(extractedData: extractedData));
  }

  @override
  Future<ScanRecord> updateConfidence(int id, double confidenceScore) async {
    final existing = await findById(id);
    if (existing == null) throw Exception('Scan record not found');
    return save(existing.copyWith(confidenceScore: confidenceScore));
  }

  @override
  Future<int> countByStatus(ScanStatus status) async {
    final scans = await findByStatus(status);
    return scans.length;
  }

  // ============ Sync-aware operations (Firestore is the store) ============

  @override
  Future<ScanRecord> createWithSync(ScanRecord entity, String tableName) async => save(entity);

  @override
  Future<ScanRecord> updateWithSync(ScanRecord entity, String tableName) async => save(entity);

  @override
  Future<void> deleteWithSync(int id, String tableName) async => softDelete(id);

  // ============ Private helpers ============

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDocByIntId(int id) async {
    final snapshot = await _records.where(FirestoreSchema.id, isEqualTo: id).limit(1).get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first;
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