import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/notifications/data/services/firestore_clinic_notifier.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';
import 'package:carepaw/features/notifications/domain/repositories/notification_repository.dart';
import 'package:carepaw/features/notifications/domain/services/clinic_notifier.dart';
import 'package:carepaw/features/notifications/presentation/notification_alerts.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Notifications extends Mock implements NotificationRepository {}

class _Users extends Mock implements UserRepository {}

class _Pets extends Mock implements PetRepository {}

class _Appointments extends Mock implements AppointmentRepository {}

void main() {
  final now = DateTime(2026, 11, 5, 9, 30);
  late _Notifications notifications;
  late _Users users;
  late _Pets pets;
  late _Appointments appointments;
  late FirestoreClinicNotifier notifier;
  final sent = <Notification>[];

  final appointment = Appointment(
    id: 40,
    petId: 10,
    ownerId: 1,
    veterinarianId: 3,
    scheduledAt: now,
    createdAt: now,
    updatedAt: now,
  );

  User admin(int id, String uid, {bool active = true}) => User(
    id: id,
    firebaseUid: uid,
    email: '$uid@x.com',
    fullName: uid,
    role: UserRole.ownerAdmin,
    isActive: active,
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(UserRole.petOwner);
    registerFallbackValue(
      Notification(
        userId: 0,
        type: NotificationType.system,
        title: '',
        message: '',
        createdAt: now,
      ),
    );
  });

  setUp(() {
    notifications = _Notifications();
    users = _Users();
    pets = _Pets();
    appointments = _Appointments();
    sent.clear();
    when(() => notifications.save(any())).thenAnswer((inv) async {
      final n = inv.positionalArguments.first as Notification;
      sent.add(n);
      return n;
    });
    when(() => pets.findById(10)).thenAnswer(
      (_) async => Pet(
        id: 10,
        ownerId: 1,
        name: 'Buddy',
        species: PetSpecies.dog,
        createdAt: now,
        updatedAt: now,
      ),
    );
    notifier = FirestoreClinicNotifier(
      notifications: notifications,
      users: users,
      pets: pets,
      appointments: appointments,
    );
  });

  test('a clinic change notifies the pet owner', () async {
    await notifier.appointment(
      appointment,
      AppointmentNotice.confirmed,
      byClinic: true,
    );
    expect(sent, hasLength(1));
    expect(sent.single.userId, 1);
    expect(sent.single.type, NotificationType.appointmentReminder);
    expect(sent.single.title, 'Appointment confirmed');
    expect(sent.single.message, contains('Buddy'));
    expect(sent.single.referenceId, 40);
    expect(sent.single.recipientUid, isNull);
    verifyNever(() => users.findByRole(any()));
  });

  test('an owner request notifies every active clinic account', () async {
    when(() => users.findByRole(UserRole.ownerAdmin)).thenAnswer(
      (_) async => [
        admin(3, 'uidC'),
        admin(4, 'uidD'),
        admin(5, 'uidE', active: false),
      ],
    );
    await notifier.appointment(
      appointment,
      AppointmentNotice.booked,
      byClinic: false,
    );
    expect(sent.map((n) => n.userId), [3, 4]);
    expect(sent.map((n) => n.recipientUid), ['uidC', 'uidD']);
    expect(sent.first.title, 'New appointment request');
  });

  test('calling a patient notifies the pet owner', () async {
    when(() => appointments.findById(40)).thenAnswer((_) async => appointment);
    await notifier.queueCalled(
      QueueEntry(
        id: 7,
        appointmentId: 40,
        position: 1,
        checkedInAt: now,
        createdAt: now,
      ),
    );
    expect(sent, hasLength(1));
    expect(sent.single.userId, 1);
    expect(sent.single.type, NotificationType.queueUpdate);
    expect(sent.single.message, contains('Buddy'));
  });

  test('a failed send never throws', () async {
    when(() => notifications.save(any())).thenThrow(Exception('offline'));
    await expectLater(
      notifier.appointment(
        appointment,
        AppointmentNotice.cancelled,
        byClinic: true,
      ),
      completes,
    );
  });

  test('alert tap payloads open the right screen', () {
    Notification n(NotificationType type, [int? ref]) => Notification(
      userId: 1,
      type: type,
      title: 't',
      message: 'm',
      referenceId: ref,
      createdAt: now,
    );
    expect(
      NotificationAlerts.payloadFor(
        n(NotificationType.appointmentReminder, 40),
      ),
      'appointment:40',
    );
    expect(
      NotificationAlerts.payloadFor(n(NotificationType.queueUpdate)),
      'queue',
    );
    expect(NotificationAlerts.payloadFor(n(NotificationType.system)), isNull);
  });
}
