import 'package:flutter_test/flutter_test.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';
import 'package:carepaw/features/notifications/presentation/notification_target.dart';

void main() {
  group('notificationTargetRoute', () {
    test('pet owner appointment with reference opens its detail', () {
      expect(
        notificationTargetRoute(
          NotificationType.appointmentReminder,
          referenceId: 12,
          role: UserRole.petOwner,
        ),
        '${Routes.appointments}/12',
      );
    });

    test('pet owner appointment without reference opens the list', () {
      expect(
        notificationTargetRoute(
          NotificationType.appointmentReminder,
          role: UserRole.petOwner,
        ),
        Routes.appointments,
      );
    });

    test('clinic roles open their own tabs', () {
      expect(
        notificationTargetRoute(
          NotificationType.appointmentReminder,
          referenceId: 12,
          role: UserRole.ownerAdmin,
        ),
        Routes.staffAppointments,
      );
      expect(
        notificationTargetRoute(
          NotificationType.queueUpdate,
          role: UserRole.ownerAdmin,
        ),
        Routes.staffQueue,
      );
    });

    test('types without a screen return null', () {
      expect(
        notificationTargetRoute(
          NotificationType.system,
          role: UserRole.petOwner,
        ),
        isNull,
      );
    });
  });

  group('notificationTargetFromPayload', () {
    test('parses appointment and queue payloads', () {
      expect(
        notificationTargetFromPayload('appointment:7', UserRole.petOwner),
        '${Routes.appointments}/7',
      );
      expect(
        notificationTargetFromPayload('queue', UserRole.petOwner),
        Routes.queue,
      );
    });

    test('ignores empty, unknown and malformed payloads', () {
      expect(notificationTargetFromPayload(null, UserRole.petOwner), isNull);
      expect(notificationTargetFromPayload('', UserRole.petOwner), isNull);
      expect(notificationTargetFromPayload('pets:3', UserRole.petOwner), isNull);
      expect(
        notificationTargetFromPayload('appointment:abc', UserRole.petOwner),
        Routes.appointments,
      );
    });
  });
}
