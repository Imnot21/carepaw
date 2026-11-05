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
class NotificationAlerts {
  NotificationAlerts(this._repository);

  final NotificationRepository _repository;
  StreamSubscription<List<Notification>>? _subscription;
  final Set<int> _seen = {};
  int? _userId;

  /// Start listening for [userId]. Calling again for the same user is a no-op.
  void start(int userId) {
    if (_userId == userId && _subscription != null) return;
    stop();
    _userId = userId;
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
  }

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
