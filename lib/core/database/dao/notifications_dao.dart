import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/tables.dart';

part 'notifications_dao.g.dart';

@DriftAccessor(tables: [Notifications, Users, NotificationPreferences])
class NotificationsDao extends DatabaseAccessor<CarePawDatabase> with _$NotificationsDaoMixin {
  NotificationsDao(super.db);

  // ============ Queries ============

  /// Get notification by ID
  Future<Notification?> getById(int id) {
    return (select(notifications)..where((n) => n.id.equals(id))).getSingleOrNull();
  }

  /// Get notifications for a user
  Future<List<Notification>> getByUser(int userId, {int limit = 50}) {
    return (select(notifications)
          ..where((n) => n.userId.equals(userId))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Stream notifications for a user
  Stream<List<Notification>> watchByUser(int userId, {int limit = 50}) {
    return (select(notifications)
          ..where((n) => n.userId.equals(userId))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
          ..limit(limit))
        .watch();
  }

  /// Get unread notifications for a user
  Future<List<Notification>> getUnreadByUser(int userId) {
    return (select(notifications)
          ..where((n) => n.userId.equals(userId) & n.isRead.equals(false))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .get();
  }

  /// Get unread count for a user
  Future<int> getUnreadCount(int userId) {
    return (select(notifications)
          ..where((n) => n.userId.equals(userId) & n.isRead.equals(false)))
        .get()
        .then((list) => list.length);
  }

  /// Get notifications by type
  Future<List<Notification>> getByType(int userId, String type) {
    return (select(notifications)
          ..where((n) => n.userId.equals(userId) & n.type.equals(type))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .get();
  }

  // ============ Mutations ============

  /// Create notification
  Future<int> createNotification(NotificationsCompanion notification) {
    return into(notifications).insert(notification);
  }

  /// Mark as read
  Future<int> markAsRead(int id) {
    return (update(notifications)..where((n) => n.id.equals(id)))
        .write(NotificationsCompanion(
          isRead: const Value(true),
          readAt: Value(DateTime.now()),
        ));
  }

  /// Mark all as read for a user
  Future<int> markAllAsRead(int userId) {
    return (update(notifications)
          ..where((n) => n.userId.equals(userId) & n.isRead.equals(false)))
        .write(NotificationsCompanion(
          isRead: const Value(true),
          readAt: Value(DateTime.now()),
        ));
  }

  /// Delete old notifications (cleanup)
  Future<int> deleteOlderThan(DateTime cutoff) {
    return (delete(notifications)
          ..where((n) => n.createdAt.isSmallerThanValue(cutoff)))
        .go();
  }

  /// Delete notification by ID
  Future<int> deleteById(int id) {
    return (delete(notifications)..where((n) => n.id.equals(id))).go();
  }

  /// Get all notifications (for admin/staff)
  Future<List<Notification>> getAll({int limit = 100}) {
    return (select(notifications)
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Watch notification by ID
  Stream<Notification?> watchById(int id) {
    return (select(notifications)..where((n) => n.id.equals(id))).watchSingleOrNull();
  }

  /// Watch all notifications (for admin/staff)
  Stream<List<Notification>> watchAll({int limit = 100}) {
    return (select(notifications)
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
          ..limit(limit))
        .watch();
  }

  // ============ Notification Preferences ============

  /// Get notification preferences for a user
  Future<NotificationPreference?> getPreferences(int userId) {
    return (select(notificationPreferences)
          ..where((p) => p.userId.equals(userId)))
        .getSingleOrNull();
  }

  /// Watch notification preferences for a user
  Stream<NotificationPreference?> watchPreferences(int userId) {
    return (select(notificationPreferences)
          ..where((p) => p.userId.equals(userId)))
        .watchSingleOrNull();
  }

  /// Create or update notification preferences
  Future<int> upsertPreferences(NotificationPreferencesCompanion preferences) {
    return into(notificationPreferences).insertOnConflictUpdate(preferences);
  }
}