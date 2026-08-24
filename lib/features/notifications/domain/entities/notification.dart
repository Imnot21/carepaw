import 'package:equatable/equatable.dart';

/// Notification entity - domain layer representation
class Notification extends Equatable {
  final int? id;
  final int userId;
  final NotificationType type;
  final String title;
  final String message;
  final int? referenceId;
  final String? referenceType;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime? scheduledFor;

  const Notification({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.referenceId,
    this.referenceType,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.scheduledFor,
  });

  /// Check if notification is unread
  bool get isUnread => !isRead;

  /// Check if notification is scheduled for future
  bool get isScheduled => scheduledFor != null && scheduledFor!.isAfter(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        message,
        referenceId,
        referenceType,
        isRead,
        readAt,
        createdAt,
        scheduledFor,
      ];

  Notification copyWith({
    int? id,
    int? userId,
    NotificationType? type,
    String? title,
    String? message,
    int? referenceId,
    String? referenceType,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? scheduledFor,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
    );
  }
}

/// Notification type enum
enum NotificationType {
  appointmentReminder('APPOINTMENT_REMINDER'),
  queueUpdate('QUEUE_UPDATE'),
  prescriptionReady('PRESCRIPTION_READY'),
  inventoryLow('INVENTORY_LOW'),
  system('SYSTEM');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.system,
    );
  }

  String get displayName {
    switch (this) {
      case NotificationType.appointmentReminder:
        return 'Appointment Reminder';
      case NotificationType.queueUpdate:
        return 'Queue Update';
      case NotificationType.prescriptionReady:
        return 'Prescription Ready';
      case NotificationType.inventoryLow:
        return 'Inventory Low';
      case NotificationType.system:
        return 'System';
    }
  }
}

/// Notification preferences entity
class NotificationPreferences extends Equatable {
  final int? id;
  final int userId;
  final bool appointmentReminders;
  final bool queueUpdates;
  final bool prescriptionReady;
  final bool inventoryAlerts;
  final bool systemAnnouncements;
  final bool emailEnabled;
  final bool pushEnabled;
  final bool inAppEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationPreferences({
    this.id,
    required this.userId,
    this.appointmentReminders = true,
    this.queueUpdates = true,
    this.prescriptionReady = true,
    this.inventoryAlerts = true,
    this.systemAnnouncements = true,
    this.emailEnabled = true,
    this.pushEnabled = true,
    this.inAppEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        appointmentReminders,
        queueUpdates,
        prescriptionReady,
        inventoryAlerts,
        systemAnnouncements,
        emailEnabled,
        pushEnabled,
        inAppEnabled,
        createdAt,
        updatedAt,
      ];

  NotificationPreferences copyWith({
    int? id,
    int? userId,
    bool? appointmentReminders,
    bool? queueUpdates,
    bool? prescriptionReady,
    bool? inventoryAlerts,
    bool? systemAnnouncements,
    bool? emailEnabled,
    bool? pushEnabled,
    bool? inAppEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      appointmentReminders: appointmentReminders ?? this.appointmentReminders,
      queueUpdates: queueUpdates ?? this.queueUpdates,
      prescriptionReady: prescriptionReady ?? this.prescriptionReady,
      inventoryAlerts: inventoryAlerts ?? this.inventoryAlerts,
      systemAnnouncements: systemAnnouncements ?? this.systemAnnouncements,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}