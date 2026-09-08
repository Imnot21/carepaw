import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/firebase/firestore_id_sequence.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/notifications/data/mappers/notification_doc_mapper.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';
import 'package:carepaw/features/notifications/domain/repositories/notification_repository.dart';

/// Notification repository implementation - data layer (Firestore-backed).
///
/// Implements [NotificationRepository] with Cloud Firestore's `notifications`
/// collection as the source of truth. Documents are keyed by the app-facing
/// integer `id` (string form). User preferences live in a separate
/// `notificationPreferences/{userId}` document.
///
/// The former Drift repository is intentionally set aside and no longer wired.
class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository({
    required FirebaseFirestore firestore,
    required FirestoreIdSequence notificationIdSequence,
  })  : _firestore = firestore,
        _idSequence = notificationIdSequence;

  final FirebaseFirestore _firestore;
  final FirestoreIdSequence _idSequence;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(FirestoreSchema.notifications);

  CollectionReference<Map<String, dynamic>> get _preferences =>
      _firestore.collection(FirestoreSchema.notificationPreferences);

  // ============ BaseRepository<Notification, int> ============

  @override
  Future<Notification?> findById(int id) async {
    final doc = await _findDocByIntId(id);
    return doc == null ? null : NotificationDocMapper.fromData(doc.data() ?? const {});
  }

  @override
  Future<List<Notification>> findAll() async {
    final snapshot = await _notifications.get();
    return snapshot.docs
        .map((doc) => NotificationDocMapper.fromData(doc.data()))
        .toList();
  }

  @override
  Future<Notification> save(Notification entity) async {
    var toWrite = entity;
    if (toWrite.id == null) {
      toWrite = toWrite.copyWith(id: await _idSequence.next());
    }
    await _notifications.doc('${toWrite.id}').set(NotificationDocMapper.toData(toWrite));
    return toWrite;
  }

  @override
  Future<void> delete(int id) async {
    final doc = await _findDocByIntId(id);
    await doc?.reference.delete();
  }

  @override
  Future<bool> exists(int id) async => await findById(id) != null;

  // ============ SoftDeleteRepository<Notification, int> ============

  @override
  Future<void> softDelete(int id) async {
    final doc = await _findDocByIntId(id);
    await doc?.reference.delete();
  }

  @override
  Future<void> restore(int id) {
    throw UnsupportedError('Notifications cannot be restored after deletion');
  }

  @override
  Future<List<Notification>> findAllIncludingDeleted() => findAll();

  // ============ StreamRepository<Notification, int> ============

  @override
  Stream<Notification?> watchById(int id) {
    return _notifications
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return NotificationDocMapper.fromData(snapshot.docs.first.data());
    });
  }

  @override
  Stream<List<Notification>> watchAll() {
    return _notifications.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => NotificationDocMapper.fromData(doc.data()))
        .toList());
  }

  // ============ PaginatedRepository<Notification, int> ============

  @override
  Future<PaginatedResult<Notification>> findPaginated(PaginationParams params) async {
    final all = await findAll();
    return _paginate(all, params);
  }

  // ============ NotificationRepository ============

  @override
  Future<List<Notification>> findByUser(int userId, {int limit = 50}) async {
    final snapshot = await _notifications.where(FirestoreSchema.userId, isEqualTo: userId).get();
    final notifications = snapshot.docs
        .map((doc) => NotificationDocMapper.fromData(doc.data()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications.take(limit).toList();
  }

  @override
  Stream<List<Notification>> watchByUser(int userId, {int limit = 50}) {
    return _notifications
        .where(FirestoreSchema.userId, isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => NotificationDocMapper.fromData(doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications.take(limit).toList();
    });
  }

  @override
  Future<List<Notification>> findUnreadByUser(int userId) async {
    final all = await findByUser(userId, limit: 500);
    return all.where((n) => n.isUnread).toList();
  }

  @override
  Future<int> getUnreadCount(int userId) async {
    final unread = await findUnreadByUser(userId);
    return unread.length;
  }

  @override
  Future<List<Notification>> findByType(int userId, NotificationType type) async {
    final all = await findByUser(userId, limit: 500);
    return all.where((n) => n.type == type).toList();
  }

  @override
  Future<Notification> markAsRead(int id) async {
    final existing = await findById(id);
    if (existing == null) throw Exception('Notification not found');
    return save(existing.copyWith(isRead: true, readAt: existing.readAt ?? DateTime.now()));
  }

  @override
  Future<int> markAllAsRead(int userId) async {
    final notifications = await findUnreadByUser(userId);
    if (notifications.isEmpty) return 0;
    final batch = _firestore.batch();
    for (final notification in notifications) {
      batch.update(_notifications.doc('${notification.id}'), {
        FirestoreSchema.isRead: true,
        FirestoreSchema.readAt: DateTime.now(),
      });
    }
    await batch.commit();
    return notifications.length;
  }

  @override
  Future<int> deleteOlderThan(DateTime cutoff) async {
    final all = await findAll();
    final stale = all.where((n) => n.createdAt.isBefore(cutoff)).toList();
    if (stale.isEmpty) return 0;
    final batch = _firestore.batch();
    for (final notification in stale) {
      batch.delete(_notifications.doc('${notification.id}'));
    }
    await batch.commit();
    return stale.length;
  }

  @override
  Future<NotificationPreferences?> findPreferences(int userId) async {
    final doc = await _preferences.doc('$userId').get();
    if (!doc.exists) return null;
    return NotificationPreferencesDocMapper.fromData(doc.data() ?? const {});
  }

  @override
  Future<NotificationPreferences> updatePreferences(NotificationPreferences preferences) async {
    final now = DateTime.now();
    final existing = await findPreferences(preferences.userId);
    final toWrite = existing == null
        ? preferences.copyWith(id: preferences.id ?? preferences.userId, createdAt: now, updatedAt: now)
        : preferences.copyWith(createdAt: existing.createdAt, updatedAt: now);
    await _preferences.doc('${preferences.userId}').set(NotificationPreferencesDocMapper.toData(toWrite));
    return toWrite;
  }

  // ============ Sync-aware operations (Firestore is the store) ============

  @override
  Future<Notification> createWithSync(Notification entity, String tableName) async => save(entity);

  @override
  Future<Notification> updateWithSync(Notification entity, String tableName) async => save(entity);

  @override
  Future<void> deleteWithSync(int id, String tableName) async => delete(id);

  // ============ Private helpers ============

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDocByIntId(int id) async {
    final snapshot = await _notifications.where(FirestoreSchema.id, isEqualTo: id).limit(1).get();
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