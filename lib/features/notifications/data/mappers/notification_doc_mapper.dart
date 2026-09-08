import 'package:carepaw/core/firebase/date_field_codec.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';

/// Maps between Firestore `notifications/{id}` documents and the domain [Notification].
///
/// Field names mirror the Drift table via [FirestoreSchema]. The document ID
/// is the string form of `Notification.id`.
class NotificationDocMapper {
  NotificationDocMapper._();

  /// Field stored on the document for a scheduled (delayed) notification.
  static const String scheduledForField = 'scheduledFor';

  /// Build a domain [Notification] from Firestore document data.
  static Notification fromData(Map<String, dynamic> data) {
    return Notification(
      id: data[FirestoreSchema.id] as int?,
      userId: (data[FirestoreSchema.userId] as num?)?.toInt() ?? 0,
      type: NotificationType.fromString((data[FirestoreSchema.typeNotif] as String?) ?? ''),
      title: (data[FirestoreSchema.titleNotif] as String?) ?? '',
      message: (data[FirestoreSchema.message] as String?) ?? '',
      referenceId: (data[FirestoreSchema.referenceIdNotif] as num?)?.toInt(),
      referenceType: data[FirestoreSchema.referenceTypeNotif] as String?,
      isRead: (data[FirestoreSchema.isRead] as bool?) ?? false,
      readAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.readAt]),
      createdAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.createdAt]) ?? DateTime.now(),
      scheduledFor: DateFieldCodec.fromFirestoreDate(data[scheduledForField]),
    );
  }

  /// Serialize a domain [Notification] to a Firestore document map.
  static Map<String, dynamic> toData(Notification notification) {
    return {
      FirestoreSchema.id: notification.id,
      FirestoreSchema.userId: notification.userId,
      FirestoreSchema.typeNotif: notification.type.value,
      FirestoreSchema.titleNotif: notification.title,
      FirestoreSchema.message: notification.message,
      FirestoreSchema.referenceIdNotif: notification.referenceId,
      FirestoreSchema.referenceTypeNotif: notification.referenceType,
      FirestoreSchema.isRead: notification.isRead,
      FirestoreSchema.readAt: DateFieldCodec.toFirestoreDate(notification.readAt),
      FirestoreSchema.createdAt: DateFieldCodec.toFirestoreDate(notification.createdAt),
      scheduledForField: DateFieldCodec.toFirestoreDate(notification.scheduledFor),
    };
  }
}

/// Maps between Firestore `notificationPreferences/{userId}` documents and the
/// domain [NotificationPreferences].
class NotificationPreferencesDocMapper {
  NotificationPreferencesDocMapper._();

  /// Build a domain [NotificationPreferences] from Firestore document data.
  static NotificationPreferences fromData(Map<String, dynamic> data) {
    return NotificationPreferences(
      id: data[FirestoreSchema.id] as int?,
      userId: (data[FirestoreSchema.userId] as num?)?.toInt() ?? 0,
      appointmentReminders: (data['appointmentReminders'] as bool?) ?? true,
      queueUpdates: (data['queueUpdates'] as bool?) ?? true,
      prescriptionReady: (data['prescriptionReady'] as bool?) ?? true,
      inventoryAlerts: (data['inventoryAlerts'] as bool?) ?? true,
      systemAnnouncements: (data['systemAnnouncements'] as bool?) ?? true,
      emailEnabled: (data['emailEnabled'] as bool?) ?? true,
      pushEnabled: (data['pushEnabled'] as bool?) ?? true,
      inAppEnabled: (data['inAppEnabled'] as bool?) ?? true,
      createdAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.createdAt]) ?? DateTime.now(),
      updatedAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.updatedAt]) ?? DateTime.now(),
    );
  }

  /// Serialize a domain [NotificationPreferences] to a Firestore document map.
  static Map<String, dynamic> toData(NotificationPreferences preferences) {
    return {
      FirestoreSchema.id: preferences.id,
      FirestoreSchema.userId: preferences.userId,
      'appointmentReminders': preferences.appointmentReminders,
      'queueUpdates': preferences.queueUpdates,
      'prescriptionReady': preferences.prescriptionReady,
      'inventoryAlerts': preferences.inventoryAlerts,
      'systemAnnouncements': preferences.systemAnnouncements,
      'emailEnabled': preferences.emailEnabled,
      'pushEnabled': preferences.pushEnabled,
      'inAppEnabled': preferences.inAppEnabled,
      FirestoreSchema.createdAt: DateFieldCodec.toFirestoreDate(preferences.createdAt),
      FirestoreSchema.updatedAt: DateFieldCodec.toFirestoreDate(preferences.updatedAt),
    };
  }
}