import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Local notification service - free alternative to Firebase Cloud Messaging.
///
/// Uses flutter_local_notifications for on-device notifications with no
/// external service dependency. Integrates with existing WorkManager-based
/// background polling to display notifications when new records are detected.
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialize the notification service.
  ///
  /// Must be called before showing any notifications.
  /// Safe to call multiple times.
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database for scheduled notifications
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels (Android)
    await _createChannels();

    _initialized = true;
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate to relevant screen based on payload
    // e.g., if payload is 'appointment:123', navigate to appointment detail
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Create Android notification channels
  static Future<void> _createChannels() async {
    // Channels are automatically created on first notification show
    // This is just to ensure they exist early
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'carepaw_instant',
            'CarePaw Instant',
            description:
                'Immediate notifications (appointment confirmations, queue updates)',
            importance: Importance.high,
          ),
        );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'carepaw_scheduled',
            'CarePaw Scheduled',
            description:
                'Scheduled notifications (appointment reminders, prescription refills)',
            importance: Importance.high,
          ),
        );
  }

  /// Show an instant notification.
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'carepaw_instant',
      'CarePaw Instant',
      channelDescription:
          'Immediate notifications (appointment confirmations, queue updates)',
      importance: _mapPriority(priority),
      priority: _mapPriorityToPriority(priority),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Schedule a notification for future delivery.
  ///
  /// Useful for appointment reminders, prescription refill alerts, etc.
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledFor,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    final androidDetails = const AndroidNotificationDetails(
      'carepaw_scheduled',
      'CarePaw Scheduled',
      channelDescription:
          'Scheduled notifications (appointment reminders, prescription refills)',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledFor, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Periodic notification (every specified duration).
  ///
  /// Example: Daily medication reminder.
  static Future<void> showPeriodicNotification({
    required int id,
    required String title,
    required String body,
    required Duration repeatInterval,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    // Map to RepeatInterval enum (closest match)
    final interval = _mapRepeatInterval(repeatInterval);

    const androidDetails = AndroidNotificationDetails(
      'carepaw_scheduled',
      'CarePaw Scheduled',
      channelDescription:
          'Scheduled notifications (appointment reminders, prescription refills)',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.periodicallyShow(
      id,
      title,
      body,
      interval,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Cancel a specific notification.
  static Future<void> cancel(int id) => _notifications.cancel(id);

  /// Cancel all notifications.
  static Future<void> cancelAll() => _notifications.cancelAll();

  /// Get pending notification requests (for debugging).
  static Future<List<PendingNotificationRequest>> pendingNotifications() =>
      _notifications.pendingNotificationRequests();

  /// Map custom priority to Flutter Local Notifications importance.
  static Importance _mapPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.medium:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.max:
        return Importance.max;
    }
  }

  /// Map custom priority to Flutter Local Notifications priority.
  static Priority _mapPriorityToPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.medium:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.max:
        return Priority.max;
    }
  }

  /// Map Duration to RepeatInterval (closest match).
  static RepeatInterval _mapRepeatInterval(Duration duration) {
    if (duration.inHours >= 24 * 7) return RepeatInterval.weekly;
    if (duration.inHours >= 24) return RepeatInterval.daily;
    if (duration.inHours >= 1) return RepeatInterval.hourly;
    return RepeatInterval.everyMinute;
  }

  /// Check if notifications are initialized.
  static bool get isInitialized => _initialized;

  /// Reset for testing.
  static void resetForTesting() => _initialized = false;
}

/// Notification priority enum (maps to platform-specific priorities).
enum NotificationPriority { low, medium, high, max }
