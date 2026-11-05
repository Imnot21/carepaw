import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';
import 'package:carepaw/features/notifications/domain/repositories/notification_repository.dart';
import 'package:carepaw/features/notifications/domain/services/clinic_notifier.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';

/// [ClinicNotifier] that saves notifications in Firestore.
///
/// The receiving phone shows each new notification as a device alert
/// (see NotificationAlerts), so no push server is needed.
class FirestoreClinicNotifier implements ClinicNotifier {
  FirestoreClinicNotifier({
    required this._notifications,
    required this._users,
    required this._pets,
    required this._appointments,
  });

  final NotificationRepository _notifications;
  final UserRepository _users;
  final PetRepository _pets;
  final AppointmentRepository _appointments;

  static final _when = DateFormat('MMM d, y \'at\' h:mm a');

  @override
  Future<void> appointment(
    Appointment appointment,
    AppointmentNotice notice, {
    required bool byClinic,
  }) async {
    try {
      final id = appointment.id;
      if (id == null) return;
      final pet = await _petName(appointment.petId);
      final when = _when.format(appointment.scheduledAt);
      final (title, message) = _text(notice, pet, when, byClinic);
      if (byClinic) {
        await _send(
          userId: appointment.ownerId,
          type: NotificationType.appointmentReminder,
          title: title,
          message: message,
          referenceId: id,
          referenceType: 'appointment',
        );
        return;
      }
      final clinic = await _users.findByRole(UserRole.ownerAdmin);
      for (final admin in clinic.where((u) => u.isActive && u.id != null)) {
        await _send(
          userId: admin.id!,
          recipientUid: admin.firebaseUid,
          type: NotificationType.appointmentReminder,
          title: title,
          message: message,
          referenceId: id,
          referenceType: 'appointment',
        );
      }
    } catch (e) {
      debugPrint('ClinicNotifier.appointment failed: $e');
    }
  }

  @override
  Future<void> queueCalled(QueueEntry entry) async {
    try {
      final appointment = await _appointments.findById(entry.appointmentId);
      if (appointment == null) return;
      final pet = await _petName(appointment.petId);
      await _send(
        userId: appointment.ownerId,
        type: NotificationType.queueUpdate,
        title: 'It is your turn',
        message: '$pet is being called. Please proceed to the clinic.',
        referenceId: entry.id,
        referenceType: 'queue',
      );
    } catch (e) {
      debugPrint('ClinicNotifier.queueCalled failed: $e');
    }
  }

  Future<String> _petName(int petId) async {
    try {
      final pet = await _pets.findById(petId);
      if (pet != null && pet.name.trim().isNotEmpty) return pet.name.trim();
    } catch (_) {
      // Fall back to a generic name; the notification still goes out.
    }
    return 'Your pet';
  }

  static (String, String) _text(
    AppointmentNotice notice,
    String pet,
    String when,
    bool byClinic,
  ) {
    switch (notice) {
      case AppointmentNotice.booked:
        return byClinic
            ? (
                'Appointment booked',
                'The clinic booked an appointment for $pet on $when.',
              )
            : (
                'New appointment request',
                '$pet has a new appointment request for $when.',
              );
      case AppointmentNotice.confirmed:
        return (
          'Appointment confirmed',
          'The appointment for $pet on $when is confirmed.',
        );
      case AppointmentNotice.rescheduled:
        return byClinic
            ? (
                'Appointment rescheduled',
                'The appointment for $pet was moved to $when.',
              )
            : (
                'Appointment changed',
                'The pet owner changed the appointment for $pet to $when.',
              );
      case AppointmentNotice.cancelled:
        return byClinic
            ? (
                'Appointment cancelled',
                'The clinic cancelled the appointment for $pet on $when.',
              )
            : (
                'Appointment cancelled',
                'The pet owner cancelled the appointment for $pet on $when.',
              );
      case AppointmentNotice.noShow:
        return (
          'Missed appointment',
          'The appointment for $pet on $when was marked as a no-show.',
        );
    }
  }

  Future<void> _send({
    required int userId,
    required NotificationType type,
    required String title,
    required String message,
    int? referenceId,
    String? referenceType,
    String? recipientUid,
  }) {
    return _notifications.save(
      Notification(
        userId: userId,
        type: type,
        title: title,
        message: message,
        referenceId: referenceId,
        referenceType: referenceType,
        createdAt: DateTime.now(),
        recipientUid: recipientUid,
      ),
    );
  }
}
