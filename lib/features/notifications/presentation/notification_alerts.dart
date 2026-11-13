import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:carepaw/core/notifications/local_notification_service.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';
import 'package:carepaw/features/notifications/domain/repositories/notification_repository.dart';

/// Shows each new notification of the signed-in user as a device alert.
///
/// Listens to the user's notifications in Firestore while the app is open or
/// running in the background. Notifications that already existed when the
/// listener started are not shown again; they stay in the in-app list.
///
/// The user's notification preferences decide which alerts are shown. A muted
/// notification still appears in the in-app list.
class NotificationAlerts {
  NotificationAlerts(this._repository);

  final NotificationRepository _repository;
  StreamSubscription<List<Notification>>? _subscription;
  final Set<int> _seen = {};
  int? _userId;
  NotificationPreferences? _preferences;

  /// Start listening for [userId]. Calling again for the same user is a no-op.
  void start(int userId) {
    if (_userId == userId && _subscription != null) return;
    stop();
    _userId = userId;
    _loadPreferences(userId);
    var primed = false;
    _subscription = _repository.watchByUser(userId, limit: 20).listen((list) {
      if (!primed) {
        // First snapshot: remember what is already there.
        _seen.addAll(list.map((n) => n.id).whereType<int>());
        primed = true;
        return;
      }
      for (final n in list) {
        final id = n.id;
        if (id == null || n.isRead || !_seen.add(id)) continue;
        // A muted notification stays marked as seen, so it does not alert
        // later when the user turns the category back on.
        if (!allows(_preferences, n.type)) continue;
        LocalNotificationService.showNotification(
          id: id,
          title: n.title,
          body: n.message,
          payload: payloadFor(n),
        );
      }
    }, onError: (Object e) => debugPrint('NotificationAlerts: $e'));
  }

  /// Stop listening (on sign-out).
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _seen.clear();
    _userId = null;
    _preferences = null;
  }

  /// Use [preferences] from now on. Called when the user changes a setting, so
  /// the change applies without a restart.
  void applyPreferences(NotificationPreferences preferences) {
    if (preferences.userId != _userId) return;
    _preferences = preferences;
  }

  Future<void> _loadPreferences(int userId) async {
    try {
      final preferences = await _repository.findPreferences(userId);
      // Keep a value the settings screen applied while this was loading.
      if (_userId == userId) _preferences ??= preferences;
    } catch (e) {
      // No preferences means every alert is shown, which is the default.
      debugPrint('NotificationAlerts: preferences not loaded: $e');
    }
  }

  /// Whether a notification of [type] may be shown as a device alert.
  ///
  /// With no saved preferences every alert is shown.
  @visibleForTesting
  static bool allows(
    NotificationPreferences? preferences,
    NotificationType type,
  ) {
    if (preferences == null) return true;
    if (!alertsEnabled(preferences)) return false;
    switch (type) {
      case NotificationType.appointmentReminder:
        return preferences.appointmentReminders;
      case NotificationType.queueUpdate:
        return preferences.queueUpdates;
      case NotificationType.prescriptionReady:
        return preferences.prescriptionReady;
      case NotificationType.inventoryLow:
        return preferences.inventoryAlerts;
      case NotificationType.system:
        return preferences.systemAnnouncements;
    }
  }

  /// The master switch. Both stored flags must be on: older versions of the
  /// settings screen wrote them from two separate switches.
  static bool alertsEnabled(NotificationPreferences preferences) =>
      preferences.inAppEnabled && preferences.pushEnabled;

  /// Tap payload understood by `notificationTargetFromPayload`.
  @visibleForTesting
  static String? payloadFor(Notification n) {
    switch (n.type) {
      case NotificationType.appointmentReminder:
        return n.referenceId != null
            ? 'appointment:${n.referenceId}'
            : 'appointment';
      case NotificationType.queueUpdate:
        return 'queue';
      case NotificationType.prescriptionReady:
      case NotificationType.inventoryLow:
      case NotificationType.system:
        return null;
    }
  }
}
