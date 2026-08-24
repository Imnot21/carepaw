import 'package:drift/drift.dart' show Value;
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/dao/notifications_dao.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/features/notifications/domain/repositories/notification_repository.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart' as domain;
import 'package:carepaw/core/repositories/base_repository.dart';

/// Notification repository implementation - data layer
/// Converts between Drift entities and domain entities
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationsDao _dao;
  final SyncRepository _syncRepo;

  NotificationRepositoryImpl(CarePawDatabase database, {required SyncRepository syncRepo})
      : _dao = NotificationsDao(database),
        _syncRepo = syncRepo;

  @override
  Future<domain.Notification?> findById(int id) async {
    final entity = await _dao.getById(id);
    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<List<domain.Notification>> findAll() async {
    // For notifications, we typically query by user, so this would need a DAO method
    // Using getAll from DAO (returns latest 100 by default)
    final entities = await _dao.getAll();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<domain.Notification> save(domain.Notification entity) async {
    final companion = _toCompanion(entity);
    if (entity.id == null) {
      final id = await _dao.createNotification(companion);
      return entity.copyWith(id: id);
    } else {
      // Notifications are typically not updated except marking as read
      // We'll just create a new one for updates
      throw UnimplementedError('Updating notifications not supported - use markAsRead');
    }
  }

  @override
  Future<void> delete(int id) async {
    await _dao.deleteById(id);
  }

  @override
  Future<bool> exists(int id) async {
    final entity = await _dao.getById(id);
    return entity != null;
  }

  @override
  Future<void> softDelete(int id) async {
    await delete(id);
  }

  @override
  Future<void> restore(int id) async {
    throw UnsupportedError('Notifications cannot be restored');
  }

  @override
  Future<List<domain.Notification>> findAllIncludingDeleted() async {
    return findAll();
  }

  @override
  Stream<domain.Notification?> watchById(int id) {
    return _dao.watchById(id).map((entity) => entity != null ? _toDomain(entity) : null);
  }

  @override
  Stream<List<domain.Notification>> watchAll() {
    return _dao.watchAll().map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<List<domain.Notification>> findByUser(int userId, {int limit = 50}) async {
    final entities = await _dao.getByUser(userId, limit: limit);
    return entities.map(_toDomain).toList();
  }

  @override
  Stream<List<domain.Notification>> watchByUser(int userId, {int limit = 50}) {
    return _dao.watchByUser(userId, limit: limit).map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<List<domain.Notification>> findUnreadByUser(int userId) async {
    final entities = await _dao.getUnreadByUser(userId);
    return entities.map(_toDomain).toList();
  }

  @override
  Future<int> getUnreadCount(int userId) async {
    return await _dao.getUnreadCount(userId);
  }

  @override
  Future<List<domain.Notification>> findByType(int userId, domain.NotificationType type) async {
    final entities = await _dao.getByType(userId, type.value);
    return entities.map(_toDomain).toList();
  }

  @override
  Future<domain.Notification> markAsRead(int id) async {
    await _dao.markAsRead(id);
    final entity = await _dao.getById(id);
    if (entity == null) {
      throw Exception('Notification not found');
    }
    return _toDomain(entity);
  }

  @override
  Future<int> markAllAsRead(int userId) async {
    return await _dao.markAllAsRead(userId);
  }

  @override
  Future<int> deleteOlderThan(DateTime cutoff) async {
    return await _dao.deleteOlderThan(cutoff);
  }

  @override
  Future<domain.NotificationPreferences?> findPreferences(int userId) async {
    final entity = await _dao.getPreferences(userId);
    return entity != null ? _preferencesToDomain(entity) : null;
  }

  @override
  Future<domain.NotificationPreferences> updatePreferences(domain.NotificationPreferences preferences) async {
    final companion = _preferencesToCompanion(preferences);
    final id = await _dao.upsertPreferences(companion);
    return preferences.copyWith(id: id);
  }

  @override
  Future<PaginatedResult<domain.Notification>> findPaginated(PaginationParams params) async {
    // For paginated results, we need a userId - this should be handled by the caller
    // For now, we'll return empty result
    return PaginatedResult(
      items: [],
      totalCount: 0,
      page: params.page,
      pageSize: params.pageSize,
    );
  }

  // Private mapping methods

  domain.Notification _toDomain(Notification entity) {
    return domain.Notification(
      id: entity.id,
      userId: entity.userId,
      type: domain.NotificationType.fromString(entity.type),
      title: entity.title,
      message: entity.message,
      referenceId: entity.referenceId,
      referenceType: entity.referenceType,
      isRead: entity.isRead,
      readAt: entity.readAt,
      createdAt: entity.createdAt,
      scheduledFor: entity.createdAt, // Using createdAt as fallback since Drift doesn't have scheduledFor
    );
  }

  NotificationsCompanion _toCompanion(domain.Notification entity) {
    return NotificationsCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      userId: Value(entity.userId),
      type: Value(entity.type.value),
      title: Value(entity.title),
      message: Value(entity.message),
      referenceId: Value(entity.referenceId),
      referenceType: Value(entity.referenceType),
      isRead: Value(entity.isRead),
      readAt: Value(entity.readAt),
      createdAt: entity.id == null ? Value(entity.createdAt) : const Value.absent(),
    );
  }

  domain.NotificationPreferences _preferencesToDomain(NotificationPreference entity) {
    return domain.NotificationPreferences(
      id: entity.id,
      userId: entity.userId,
      appointmentReminders: entity.appointmentReminders,
      queueUpdates: entity.queueUpdates,
      prescriptionReady: entity.prescriptionReady,
      inventoryAlerts: entity.inventoryAlerts,
      systemAnnouncements: entity.systemAnnouncements,
      emailEnabled: entity.emailEnabled,
      pushEnabled: entity.pushEnabled,
      inAppEnabled: entity.inAppEnabled,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  NotificationPreferencesCompanion _preferencesToCompanion(domain.NotificationPreferences entity) {
    return NotificationPreferencesCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      userId: Value(entity.userId),
      appointmentReminders: Value(entity.appointmentReminders),
      queueUpdates: Value(entity.queueUpdates),
      prescriptionReady: Value(entity.prescriptionReady),
      inventoryAlerts: Value(entity.inventoryAlerts),
      systemAnnouncements: Value(entity.systemAnnouncements),
      emailEnabled: Value(entity.emailEnabled),
      pushEnabled: Value(entity.pushEnabled),
      inAppEnabled: Value(entity.inAppEnabled),
      createdAt: entity.id == null ? Value(entity.createdAt) : const Value.absent(),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  Future<domain.Notification> createWithSync(domain.Notification entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'userId': entity.userId,
        'type': entity.type.value,
        'title': entity.title,
        'message': entity.message,
        'referenceId': entity.referenceId,
        'referenceType': entity.referenceType,
        'isRead': entity.isRead,
        'readAt': entity.readAt?.toIso8601String(),
        'createdAt': entity.createdAt.toIso8601String(),
      };
      await _syncRepo.queueForSync(
        tableName: tableName,
        recordId: saved.id!,
        operation: SyncOperation.insert,
        payload: payload,
      );
    }
    return saved;
  }

  @override
  Future<domain.Notification> updateWithSync(domain.Notification entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'userId': entity.userId,
        'type': entity.type.value,
        'title': entity.title,
        'message': entity.message,
        'referenceId': entity.referenceId,
        'referenceType': entity.referenceType,
        'isRead': entity.isRead,
        'readAt': entity.readAt?.toIso8601String(),
        'createdAt': entity.createdAt.toIso8601String(),
      };
      await _syncRepo.queueForSync(
        tableName: tableName,
        recordId: saved.id!,
        operation: SyncOperation.update,
        payload: payload,
      );
    }
    return saved;
  }

  @override
  Future<void> deleteWithSync(int id, String tableName) async {
    // Would need a DAO method for delete
    await _syncRepo.queueForSync(
      tableName: tableName,
      recordId: id,
      operation: SyncOperation.delete,
    );
  }
}