import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';

/// Resolves the screen a notification should open, per role.
///
/// Returns null when the notification has no related screen (e.g. system
/// announcements), so callers can hide the action instead of guessing.
String? notificationTargetRoute(
  NotificationType type, {
  int? referenceId,
  required UserRole role,
}) {
  final isClinic = role == UserRole.ownerAdmin;
  switch (type) {
    case NotificationType.appointmentReminder:
      if (isClinic) return Routes.staffAppointments;
      return referenceId != null
          ? '${Routes.appointments}/$referenceId'
          : Routes.appointments;
    case NotificationType.queueUpdate:
      return isClinic ? Routes.staffQueue : Routes.queue;
    case NotificationType.prescriptionReady:
    case NotificationType.inventoryLow:
    case NotificationType.system:
      return null;
  }
}

/// Resolves a local-notification payload such as `appointment:123` or
/// `queue` to a route. Unknown or malformed payloads return null.
String? notificationTargetFromPayload(String? payload, UserRole role) {
  if (payload == null || payload.isEmpty) return null;
  final parts = payload.split(':');
  final referenceId = parts.length > 1 ? int.tryParse(parts[1]) : null;
  final type = switch (parts.first) {
    'appointment' => NotificationType.appointmentReminder,
    'queue' => NotificationType.queueUpdate,
    _ => null,
  };
  if (type == null) return null;
  return notificationTargetRoute(type, referenceId: referenceId, role: role);
}
