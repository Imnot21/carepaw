import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';

/// What happened to an appointment, for the notification text.
enum AppointmentNotice { booked, confirmed, rescheduled, cancelled, noShow }

/// Sends the automatic appointment and queue notifications (FR-22, FR-23).
///
/// A change made by the clinic notifies the pet owner. A change made by the
/// pet owner notifies every active Owner/Admin account. Sending never throws:
/// a failed notification must not undo the action that triggered it.
abstract class ClinicNotifier {
  Future<void> appointment(
    Appointment appointment,
    AppointmentNotice notice, {
    required bool byClinic,
  });

  /// Tells the pet owner that their pet was called from the queue.
  Future<void> queueCalled(QueueEntry entry);
}
