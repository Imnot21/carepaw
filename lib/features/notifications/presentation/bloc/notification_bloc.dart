import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/core/storage/local_storage.dart';
import 'package:carepaw/features/notifications/domain/repositories/notification_repository.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_event.dart'
    as events;
import 'package:carepaw/features/notifications/presentation/bloc/notification_state.dart'
    as states;
import 'package:carepaw/core/errors/failures.dart';

/// Notification BLoC for managing notifications and preferences.
class NotificationBloc
    extends Bloc<events.NotificationEvent, states.NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationBloc({required this._notificationRepository})
    : super(const states.NotificationInitial()) {
    on<events.LoadNotifications>(_onLoadNotifications);
    on<events.LoadUnreadCount>(_onLoadUnreadCount);
    on<events.LoadNotificationsByType>(_onLoadNotificationsByType);
    on<events.MarkAsRead>(_onMarkAsRead);
    on<events.MarkAllAsRead>(_onMarkAllAsRead);
    on<events.DeleteNotification>(_onDeleteNotification);
    on<events.DeleteAllReadNotifications>(_onDeleteAllReadNotifications);
    on<events.CreateNotification>(_onCreateNotification);
    on<events.UpdateNotificationPreferences>(_onUpdateNotificationPreferences);
    on<events.LoadNotificationPreferences>(_onLoadNotificationPreferences);
    on<events.RefreshNotifications>(_onRefreshNotifications);
  }

  /// Signed-in user id (LocalStorage is set at login). `1` is only a legacy
  /// fallback so behavior matches the old data if the session is missing.
  int get _currentUserId {
    try {
      return LocalStorage.getUserId() ?? 1;
    } catch (_) {
      return 1;
    }
  }

  /// Load all notifications with pagination
  Future<void> _onLoadNotifications(
    events.LoadNotifications event,
    Emitter<states.NotificationState> emit,
  ) async {
    emit(const states.NotificationLoading());
    try {
      final notifications = await _notificationRepository.findByUser(
        event.userId ?? _currentUserId,
        limit: event.limit ?? 20,
      );
      emit(
        states.NotificationsLoaded(
          notifications: notifications,
          hasReachedMax: notifications.length < (event.limit ?? 20),
        ),
      );
    } on Failure catch (failure) {
      emit(states.NotificationError(failure));
    } catch (e) {
      emit(states.NotificationError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load unread count
  Future<void> _onLoadUnreadCount(
    events.LoadUnreadCount event,
    Emitter<states.NotificationState> emit,
  ) async {
    try {
      final count = await _notificationRepository.getUnreadCount(
        event.userId ?? _currentUserId,
      );
      emit(states.UnreadCountLoaded(count));
    } on Failure catch (failure) {
      emit(states.NotificationError(failure));
    } catch (e) {
      emit(states.NotificationError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load notifications by type
  Future<void> _onLoadNotificationsByType(
    events.LoadNotificationsByType event,
    Emitter<states.NotificationState> emit,
  ) async {
    emit(const states.NotificationLoading());
    try {
      final notifications = await _notificationRepository.findByType(
        event.userId ?? _currentUserId,
        event.type,
      );
      emit(states.NotificationsByTypeLoaded(notifications, event.type));
    } on Failure catch (failure) {
      emit(states.NotificationError(failure));
    } catch (e) {
      emit(states.NotificationError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Mark notification as read
  Future<void> _onMarkAsRead(
    events.MarkAsRead event,
    Emitter<states.NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markAsRead(event.notificationId);
      emit(states.NotificationMarkedAsRead(event.notificationId));
      // Reload unread count
      add(const events.LoadUnreadCount());
    } on Failure catch (failure) {
      emit(states.NotificationError(failure));
    } catch (e) {
      emit(states.NotificationError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Mark all notifications as read
  Future<void> _onMarkAllAsRead(
    events.MarkAllAsRead event,
    Emitter<states.NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markAllAsRead(event.userId ?? _currentUserId);
      emit(const states.AllNotificationsMarkedAsRead());
      add(const events.LoadUnreadCount());
      add(const events.LoadNotifications());
    } on Failure catch (failure) {
      emit(states.NotificationError(failure));
    } catch (e) {
      emit(states.NotificationError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Delete a notification
  Future<void> _onDeleteNotification(
    events.DeleteNotification event,
    Emitter<states.NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.delete(event.notificationId);
      emit(states.NotificationDeleted(event.notificationId));
      add(const events.LoadUnreadCount());
    } on Failure catch (failure) {
      emit(states.NotificationError(failure));
    } catch (e) {
      emit(states.NotificationError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Delete all read notifications
  Future<void> _onDeleteAllReadNotifications(
    events.DeleteAllReadNotifications event,
    Emitter<states.NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.deleteOlderThan(
        DateTime.now().subtract(const Duration(days: 30)),
      );
      emit(const states.AllReadNotificationsDeleted());
      add(const events.LoadUnreadCount());
      add(const events.LoadNotifications());
    } on Failure catch (failure) {
      emit(states.NotificationError(failure));
    } catch (e) {
      emit(states.NotificationError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Create a new notification
  Future<void> _onCreateNotification(
    events.CreateNotification event,
    Emitter<states.NotificationState> emit,
  ) async {
    emit(const states.NotificationLoading());
    try {
      final notification = Notification(
        id: null,
        userId: event.targetUserId ?? _currentUserId,
        title: event.title,
        message: event.body,
        type: event.type,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await _notificationRepository.save(notification);
      emit(states.NotificationCreated(notification));
      add(events.LoadNotifications(userId: event.targetUserId ?? _currentUserId));
    } on Failure catch (failure) {
      emit(states.NotificationError(failure));
    } catch (e) {
      emit(states.NotificationError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Update notification preferences
  Future<void> _onUpdateNotificationPreferences(
    events.UpdateNotificationPreferences event,
    Emitter<states.NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.updatePreferences(event.preferences);
      emit(const states.NotificationPreferencesUpdated());
    } on Failure catch (failure) {
      emit(states.NotificationError(failure));
    } catch (e) {
      emit(states.NotificationError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load notification preferences
  Future<void> _onLoadNotificationPreferences(
    events.LoadNotificationPreferences event,
    Emitter<states.NotificationState> emit,
  ) async {
    try {
      // Preferences live in notificationPreferences/{userId}; the rules only
      // let a caller read their own document, so the id must be the signed-in
      // user's (previously hardcoded to 1, which denied everyone else).
      final userId = LocalStorage.getUserId() ?? 1;
      final preferences = await _notificationRepository.findPreferences(
        userId,
      );
      if (preferences != null) {
        emit(states.NotificationPreferencesLoaded(preferences));
      } else {
        // Create default preferences if none exist
        final defaultPrefs = NotificationPreferences(
          id: null,
          userId: userId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        emit(states.NotificationPreferencesLoaded(defaultPrefs));
      }
    } on Failure catch (failure) {
      emit(states.NotificationError(failure));
    } catch (e) {
      emit(states.NotificationError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Refresh notifications (pull to refresh)
  Future<void> _onRefreshNotifications(
    events.RefreshNotifications event,
    Emitter<states.NotificationState> emit,
  ) async {
    add(const events.LoadNotifications());
    add(const events.LoadUnreadCount());
  }
}
