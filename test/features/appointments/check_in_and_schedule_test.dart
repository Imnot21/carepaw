import 'dart:typed_data';

import 'package:carepaw/features/appointments/domain/clinic_schedule.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/notifications/domain/services/clinic_notifier.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';
import 'package:carepaw/features/queue/domain/repositories/queue_repository.dart';
import 'package:carepaw/features/scanning/data/services/firebase_ai_scan_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Appointments extends Mock implements AppointmentRepository {}

class _Queue extends Mock implements QueueRepository {}

class _Auth extends Mock implements AuthBloc {}

class _Notifier extends Mock implements ClinicNotifier {}

Appointment _booking(DateTime when, {AppointmentStatus? status}) {
  final now = DateTime.now();
  return Appointment(
    id: 7,
    petId: 1,
    ownerId: 2,
    veterinarianId: 3,
    scheduledAt: when,
    status: status ?? AppointmentStatus.confirmed,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('check-in', () {
    late _Appointments appointments;
    late _Queue queue;
    late _Auth auth;

    setUp(() {
      appointments = _Appointments();
      queue = _Queue();
      auth = _Auth();
      when(() => auth.state).thenReturn(const AuthUnauthenticated());
    });

    AppointmentBloc bloc() => AppointmentBloc(
      repository: appointments,
      authBloc: auth,
      notifier: _Notifier(),
      queue: queue,
    );

    test('canCheckInNow only on the day of an approved visit', () {
      final now = DateTime.now();
      expect(_booking(now).canCheckInNow, isTrue);
      expect(
        _booking(now.add(const Duration(days: 3))).canCheckInNow,
        isFalse,
      );
      expect(
        _booking(now, status: AppointmentStatus.requested).canCheckInNow,
        isFalse,
      );
    });

    test('checking in today puts the pet in the queue', () async {
      final today = _booking(DateTime.now());
      final checkedIn = today.copyWith(status: AppointmentStatus.checkedIn);
      var reads = 0;
      when(() => appointments.findById(7)).thenAnswer(
        (_) async => reads++ == 0 ? today : checkedIn,
      );
      when(() => queue.checkIn(7)).thenAnswer(
        (_) async => QueueEntry(
          appointmentId: 7,
          position: 1,
          checkedInAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final b = bloc();
      final updated = b.stream.firstWhere((s) => s is AppointmentStatusUpdated);
      b.add(
        const AppointmentStatusUpdateRequested(7, AppointmentStatus.checkedIn),
      );
      final state = await updated as AppointmentStatusUpdated;

      verify(() => queue.checkIn(7)).called(1);
      expect(state.appointment.status, AppointmentStatus.checkedIn);
      await b.close();
    });

    test('a booking for another day cannot be checked in', () async {
      when(() => appointments.findById(7)).thenAnswer(
        (_) async => _booking(DateTime.now().add(const Duration(days: 3))),
      );

      final b = bloc();
      final error = b.stream.firstWhere((s) => s is AppointmentError);
      b.add(
        const AppointmentStatusUpdateRequested(7, AppointmentStatus.checkedIn),
      );
      final state = await error as AppointmentError;

      expect(state.message, contains('day of the visit'));
      verifyNever(() => queue.checkIn(any()));
      await b.close();
    });
  });

  group('booking time slots', () {
    test('round to the nearest 15 minutes', () {
      expect(
        ClinicSchedule.roundToSlot(DateTime(2026, 11, 28, 16, 23)),
        DateTime(2026, 11, 28, 16, 30),
      );
      expect(
        ClinicSchedule.roundToSlot(DateTime(2026, 11, 28, 9, 7)),
        DateTime(2026, 11, 28, 9, 0),
      );
    });
  });

  group('pet age', () {
    final now = DateTime(2026, 11, 26);

    test('counts whole months', () {
      expect(
        PetUtils.calculateAge(DateTime(2025, 3, 10), now: now),
        '1 year 8 months',
      );
      expect(PetUtils.calculateAge(DateTime(2025, 11, 26), now: now), '1 year');
      expect(
        PetUtils.calculateAge(DateTime(2025, 11, 27), now: now),
        '11 months',
      );
      expect(
        PetUtils.calculateAge(DateTime(2026, 11, 1), now: now),
        'Under 1 month',
      );
    });
  });

  group('scan image type', () {
    test('comes from the bytes when the path has no extension', () {
      final png = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0, //
      ]);
      expect(
        FirebaseAiScanReader.mimeTypeFor('blob:https://x/abc', png),
        'image/png',
      );
      final jpg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
      expect(FirebaseAiScanReader.mimeTypeFor('blob:x', jpg), 'image/jpeg');
    });
  });
}
