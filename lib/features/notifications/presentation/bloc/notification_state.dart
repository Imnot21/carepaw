import 'package:equatable/equatable.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';
import 'package:carepaw/core/errors/failures.dart';

/// Base class for all notification states.
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

/// Loading state.
class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

/// Notifications loaded state.
class NotificationsLoaded extends NotificationState {
  final List<Notification> notifications;
  final bool hasReachedMax;

  const NotificationsLoaded({
    required this.notifications,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [notifications, hasReachedMax];
}

/// Unread count loaded state.
class UnreadCountLoaded extends NotificationState {
  final int count;

  const UnreadCountLoaded(this.count);

  @override
  List<Object?> get props => [count];
}

/// Notifications by type loaded state.
class NotificationsByTypeLoaded extends NotificationState {
  final List<Notification> notifications;
  final NotificationType type;

  const NotificationsByTypeLoaded(this.notifications, this.type);

  @override
  List<Object?> get props => [notifications, type];
}

/// Notification marked as read state.
class NotificationMarkedAsRead extends NotificationState {
  final int notificationId;

  const NotificationMarkedAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// All notifications marked as read state.
class AllNotificationsMarkedAsRead extends NotificationState {
  const AllNotificationsMarkedAsRead();
}

/// Notification deleted state.
class NotificationDeleted extends NotificationState {
  final int notificationId;

  const NotificationDeleted(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// All read notifications deleted state.
class AllReadNotificationsDeleted extends NotificationState {
  const AllReadNotificationsDeleted();
}

/// Notification created state.
class NotificationCreated extends NotificationState {
  final Notification notification;

  const NotificationCreated(this.notification);

  @override
  List<Object?> get props => [notification];
}

/// Notification preferences loaded state.
class NotificationPreferencesLoaded extends NotificationState {
  final NotificationPreferences preferences;

  const NotificationPreferencesLoaded(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

/// Notification preferences updated state.
class NotificationPreferencesUpdated extends NotificationState {
  const NotificationPreferencesUpdated();
}

/// Error state.
class NotificationError extends NotificationState {
  final Failure failure;

  const NotificationError(this.failure);

  @override
  List<Object?> get props => [failure];
}