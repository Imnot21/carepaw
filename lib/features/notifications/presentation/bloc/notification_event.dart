import 'package:equatable/equatable.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';

/// Base class for all notification events.
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load all notifications for current user.
class LoadNotifications extends NotificationEvent {
  final int? userId;
  final int? limit;
  final int? offset;

  const LoadNotifications({this.userId, this.limit, this.offset});

  @override
  List<Object?> get props => [userId, limit, offset];
}

/// Load unread notifications count.
class LoadUnreadCount extends NotificationEvent {
  final int? userId;

  const LoadUnreadCount({this.userId});
}

/// Load notifications by type.
class LoadNotificationsByType extends NotificationEvent {
  final int? userId;
  final NotificationType type;
  final int? limit;

  const LoadNotificationsByType(this.type, {this.userId, this.limit});

  @override
  List<Object?> get props => [userId, type, limit];
}

/// Mark notification as read.
class MarkAsRead extends NotificationEvent {
  final int notificationId;

  const MarkAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Mark all notifications as read.
class MarkAllAsRead extends NotificationEvent {
  final int? userId;

  const MarkAllAsRead({this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Delete a notification.
class DeleteNotification extends NotificationEvent {
  final int notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Delete all read notifications.
class DeleteAllReadNotifications extends NotificationEvent {
  const DeleteAllReadNotifications();
}

/// Create a new notification (for testing/admin).
class CreateNotification extends NotificationEvent {
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final int? targetUserId;

  const CreateNotification({
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.targetUserId,
  });

  @override
  List<Object?> get props => [title, body, type, data, targetUserId];
}

/// Update notification preferences.
class UpdateNotificationPreferences extends NotificationEvent {
  final NotificationPreferences preferences;

  const UpdateNotificationPreferences(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

/// Load notification preferences.
class LoadNotificationPreferences extends NotificationEvent {
  const LoadNotificationPreferences();
}

/// Refresh notifications (pull to refresh).
class RefreshNotifications extends NotificationEvent {
  const RefreshNotifications();
}
