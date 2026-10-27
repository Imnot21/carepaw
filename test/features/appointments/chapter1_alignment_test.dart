import 'package:flutter_test/flutter_test.dart';
import 'package:carepaw/core/constants/app_constants.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';

Appointment visit({
  required DateTime scheduledAt,
  AppointmentStatus status = AppointmentStatus.confirmed,
  String? service = 'Consultation',
}) {
  final now = DateTime.now();
  return Appointment(
    petId: 1,
    veterinarianId: 1,
    scheduledAt: scheduledAt,
    status: status,
    service: service,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Appointment.isLate', () {
    const grace = Duration(minutes: AppConstants.lateArrivalMinutes);

    test('is late once the grace period passes without check-in', () {
      final past = DateTime.now().subtract(grace + const Duration(minutes: 1));
      expect(visit(scheduledAt: past).isLate, isTrue);
      expect(
        visit(
          scheduledAt: past,
          status: AppointmentStatus.rescheduled,
        ).isLate,
        isTrue,
      );
    });

    test('is not late within the grace period', () {
      final recent = DateTime.now().subtract(const Duration(minutes: 1));
      expect(visit(scheduledAt: recent).isLate, isFalse);
    });

    test('is not late once checked in, finished, or a home visit', () {
      final past = DateTime.now().subtract(grace + const Duration(hours: 1));
      for (final status in [
        AppointmentStatus.checkedIn,
        AppointmentStatus.inProgress,
        AppointmentStatus.completed,
        AppointmentStatus.noShow,
        AppointmentStatus.requested,
      ]) {
        expect(visit(scheduledAt: past, status: status).isLate, isFalse);
      }
      expect(
        visit(scheduledAt: past, service: homeServiceLabel).isLate,
        isFalse,
      );
    });
  });

  test('Home Service is a bookable service', () {
    expect(clinicServices, contains(homeServiceLabel));
    expect(
      visit(scheduledAt: DateTime.now(), service: homeServiceLabel)
          .isHomeService,
      isTrue,
    );
  });

  group('PetSpecies.clinicSupported', () {
    test('offers dogs and cats only', () {
      expect(PetSpecies.clinicSupported(), [PetSpecies.dog, PetSpecies.cat]);
      expect(PetSpecies.clinicSupported(PetSpecies.cat), [
        PetSpecies.dog,
        PetSpecies.cat,
      ]);
    });

    test('keeps a legacy species so editing does not change it', () {
      expect(
        PetSpecies.clinicSupported(PetSpecies.bird),
        contains(PetSpecies.bird),
      );
    });
  });

  group('QueuePriority.selectable', () {
    test('hides Emergency because the clinic takes no emergencies', () {
      expect(QueuePriority.selectable(QueuePriority.routine), [
        QueuePriority.urgent,
        QueuePriority.routine,
      ]);
    });

    test('keeps Emergency on an entry that already has it', () {
      expect(
        QueuePriority.selectable(QueuePriority.emergency),
        contains(QueuePriority.emergency),
      );
    });
  });
}
