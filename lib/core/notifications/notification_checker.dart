import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/notifications/local_notification_service.dart';

/// Checks for new notifications in the local database and displays them.
///
/// Designed to be called from WorkManager background sync to show
/// local notifications for new records (appointments, queue updates, etc.).
class NotificationChecker {
  final CarePawDatabase _database;

  NotificationChecker(this._database);

  /// Check for new unread notifications and display them.
  ///
  /// Returns the count of notifications shown.
  Future<int> checkAndShowNewNotifications(int userId) async {
    // Get unread notifications for this user since last check
    final newNotifications = await (_database.select(_database.notifications)
          ..where((n) => n.userId.equals(userId) & n.isRead.equals(false))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
          ..limit(10))
        .get();

    if (newNotifications.isEmpty) return 0;

    int shown = 0;
    for (final notification in newNotifications) {
      await LocalNotificationService.showNotification(
        id: notification.id,
        title: notification.title,
        body: notification.message,
        payload: _buildPayload(notification),
      );
      shown++;
    }

    return shown;
  }

  /// Check for specific notification types that need immediate display.
  ///
  /// Some notifications (queue updates, appointment confirmations) should
  /// be shown immediately even if the app is in foreground.
  Future<int> checkAndShowPriorityNotifications(int userId) async {
    final priorityTypes = [
      'QUEUE_UPDATE',
      'APPOINTMENT_REMINDER',
      'PRESCRIPTION_READY',
    ];

    final priorityNotifications = await (_database.select(_database.notifications)
          ..where((n) =>
              n.userId.equals(userId) &
              n.isRead.equals(false) &
              n.type.isIn(priorityTypes))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
          ..limit(5))
        .get();

    int shown = 0;
    for (final notification in priorityNotifications) {
      await LocalNotificationService.showNotification(
        id: notification.id,
        title: notification.title,
        body: notification.message,
        payload: _buildPayload(notification),
        priority: NotificationPriority.max,
      );
      shown++;
    }

    return shown;
  }

  /// Schedule appointment reminders.
  ///
  /// Call this when appointments are created/confirmed to schedule
  /// reminder notifications (e.g., 1 hour before, 1 day before).
  Future<void> scheduleAppointmentReminders(int appointmentId, DateTime scheduledAt) async {
    final reminders = [
      // 1 day before
      scheduledAt.subtract(const Duration(days: 1)),
      // 1 hour before
      scheduledAt.subtract(const Duration(hours: 1)),
      // 15 minutes before
      scheduledAt.subtract(const Duration(minutes: 15)),
    ];

    for (final reminderTime in reminders) {
      if (reminderTime.isAfter(DateTime.now())) {
        await LocalNotificationService.scheduleNotification(
          id: appointmentId * 10 + reminders.indexOf(reminderTime),
          title: 'Upcoming Appointment',
          body: 'Your appointment is in ${_formatDuration(scheduledAt.difference(reminderTime))}',
          scheduledFor: reminderTime,
          payload: 'appointment:$appointmentId',
        );
      }
    }
  }

  /// Cancel appointment reminders.
  Future<void> cancelAppointmentReminders(int appointmentId) async {
    for (int i = 0; i < 3; i++) {
      await LocalNotificationService.cancel(appointmentId * 10 + i);
    }
  }

  /// Schedule prescription refill reminder.
  Future<void> schedulePrescriptionReminder(int prescriptionId, DateTime dueDate) async {
    // Remind 3 days before refill due
    final reminderTime = dueDate.subtract(const Duration(days: 3));
    if (reminderTime.isAfter(DateTime.now())) {
      await LocalNotificationService.scheduleNotification(
        id: 100000 + prescriptionId,
        title: 'Prescription Refill Due Soon',
        body: 'Your prescription refill is due in 3 days',
        scheduledFor: reminderTime,
        payload: 'prescription:$prescriptionId',
      );
    }
  }

  /// Build payload string for deep linking.
  String _buildPayload(dynamic notification) {
    final refType = notification.referenceType;
    final refId = notification.referenceId;
    if (refType != null && refId != null) {
      return '$refType:$refId';
    }
    return 'notification:${notification.id}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) return '${duration.inDays} day(s)';
    if (duration.inHours > 0) return '${duration.inHours} hour(s)';
    return '${duration.inMinutes} minute(s)';
  }
}