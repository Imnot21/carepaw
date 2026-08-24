import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';

/// Notification repository interface - domain layer contract
abstract class NotificationRepository extends SoftDeleteRepository<Notification, int>
    implements StreamRepository<Notification, int>, PaginatedRepository<Notification, int> {
  /// Sync-aware operations
  @override
  Future<Notification> createWithSync(Notification entity, String tableName);

  @override
  Future<Notification> updateWithSync(Notification entity, String tableName);

  @override
  Future<void> deleteWithSync(int id, String tableName);
  /// Find notifications for a user
  Future<List<Notification>> findByUser(int userId, {int limit = 50});

  /// Watch notifications for a user (real-time)
  Stream<List<Notification>> watchByUser(int userId, {int limit = 50});

  /// Find unread notifications for a user
  Future<List<Notification>> findUnreadByUser(int userId);

  /// Get unread count for a user
  Future<int> getUnreadCount(int userId);

  /// Find notifications by type for a user
  Future<List<Notification>> findByType(int userId, NotificationType type);

  /// Mark notification as read
  Future<Notification> markAsRead(int id);

  /// Mark all notifications as read for a user
  Future<int> markAllAsRead(int userId);

  /// Delete notifications older than a date
  Future<int> deleteOlderThan(DateTime cutoff);

  /// Find notification preferences for a user
  Future<NotificationPreferences?> findPreferences(int userId);

  /// Update notification preferences
  Future<NotificationPreferences> updatePreferences(NotificationPreferences preferences);
}