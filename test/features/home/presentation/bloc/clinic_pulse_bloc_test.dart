import 'package:bloc_test/bloc_test.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/home/presentation/bloc/clinic_pulse_bloc.dart';
import 'package:carepaw/features/home/presentation/bloc/clinic_pulse_event.dart';
import 'package:carepaw/features/home/presentation/bloc/clinic_pulse_state.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';
import 'package:carepaw/features/queue/domain/repositories/queue_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockQueueRepository extends Mock implements QueueRepository {}

class _MockAppointmentRepository extends Mock
    implements AppointmentRepository {}

class _MockInventoryItemRepository extends Mock
    implements InventoryItemRepository {}

class _MockPet extends Mock implements Pet {}

class _MockVeterinarian extends Mock implements User {}

Appointment _appointment({
  int id = 1,
  DateTime? scheduledAt,
  AppointmentStatus status = AppointmentStatus.confirmed,
}) {
  final now = DateTime.now();
  return Appointment(
    id: id,
    petId: 1,
    veterinarianId: 1,
    scheduledAt: scheduledAt ?? now,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

QueueEntryWithDetails _queueEntry(QueueStatus status, {int id = 1}) {
  final checkedInAt = DateTime(2026, 10, 17, 9);
  return QueueEntryWithDetails(
    queueEntry: QueueEntry(
      id: id,
      appointmentId: id,
      position: id,
      status: status,
      checkedInAt: checkedInAt,
      createdAt: checkedInAt,
    ),
    appointment: _appointment(id: id),
    pet: _MockPet(),
    veterinarian: _MockVeterinarian(),
  );
}

AppointmentWithPetDetails _appointmentWithPet(Appointment appointment) =>
    AppointmentWithPetDetails(appointment: appointment, pet: _MockPet());

InventoryItem _lowStockItem({int id = 1}) {
  final now = DateTime(2026, 10, 17);
  return InventoryItem(
    id: id,
    name: 'Item $id',
    category: InventoryCategory.vaccine,
    unit: 'vial',
    currentStock: 1,
    minStock: 2,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late _MockQueueRepository queueRepository;
  late _MockAppointmentRepository appointmentRepository;
  late _MockInventoryItemRepository inventoryRepository;

  setUp(() {
    queueRepository = _MockQueueRepository();
    appointmentRepository = _MockAppointmentRepository();
    inventoryRepository = _MockInventoryItemRepository();
  });

  ClinicPulseBloc build() => ClinicPulseBloc(
    queueRepository: queueRepository,
    appointmentRepository: appointmentRepository,
    inventoryRepository: inventoryRepository,
  );

  blocTest<ClinicPulseBloc, ClinicPulseState>(
    'counts waiting + called patients, today\'s non-cancelled bookings, and low stock',
    build: () {
      when(() => queueRepository.getCurrentQueue()).thenAnswer(
        (_) async => [
          _queueEntry(QueueStatus.waiting, id: 1),
          _queueEntry(QueueStatus.called, id: 2),
          _queueEntry(QueueStatus.inRoom, id: 3),
          _queueEntry(QueueStatus.completed, id: 4),
        ],
      );
      when(() => appointmentRepository.findAllWithPetDetails()).thenAnswer(
        (_) async => [
          _appointmentWithPet(_appointment()),
          _appointmentWithPet(
            _appointment(id: 2, status: AppointmentStatus.cancelled),
          ),
          _appointmentWithPet(
            _appointment(
              id: 3,
              scheduledAt: DateTime.now().add(const Duration(days: 1)),
            ),
          ),
        ],
      );
      when(
        () => inventoryRepository.findLowStock(),
      ).thenAnswer((_) async => [_lowStockItem(id: 1), _lowStockItem(id: 2)]);
      return build();
    },
    act: (bloc) => bloc.add(const ClinicPulseStarted()),
    expect: () => [
      const ClinicPulseState(status: ClinicPulseStatus.loading),
      const ClinicPulseState(
        status: ClinicPulseStatus.ready,
        waiting: 2,
        todayBookings: 1,
        lowStock: 2,
        revision: 1,
      ),
    ],
  );

  blocTest<ClinicPulseBloc, ClinicPulseState>(
    'a failing source leaves its counter unknown without taking the others down',
    build: () {
      when(() => queueRepository.getCurrentQueue())
          .thenThrow(Exception('offline'));
      when(() => appointmentRepository.findAllWithPetDetails())
          .thenAnswer((_) async => [_appointmentWithPet(_appointment())]);
      when(() => inventoryRepository.findLowStock())
          .thenAnswer((_) async => [_lowStockItem()]);
      return build();
    },
    act: (bloc) => bloc.add(const ClinicPulseStarted()),
    expect: () => [
      const ClinicPulseState(status: ClinicPulseStatus.loading),
      const ClinicPulseState(
        status: ClinicPulseStatus.ready,
        waiting: null,
        todayBookings: 1,
        lowStock: 1,
        revision: 1,
      ),
    ],
  );

  blocTest<ClinicPulseBloc, ClinicPulseState>(
    'all sources failing still reaches ready with every counter unknown',
    build: () {
      when(() => queueRepository.getCurrentQueue())
          .thenThrow(Exception('offline'));
      when(() => appointmentRepository.findAllWithPetDetails())
          .thenThrow(Exception('offline'));
      when(() => inventoryRepository.findLowStock())
          .thenThrow(Exception('offline'));
      return build();
    },
    act: (bloc) => bloc.add(const ClinicPulseStarted()),
    expect: () => [
      const ClinicPulseState(status: ClinicPulseStatus.loading),
      const ClinicPulseState(status: ClinicPulseStatus.ready, revision: 1),
    ],
  );

  blocTest<ClinicPulseBloc, ClinicPulseState>(
    'refresh keeps the previous value of a source that fails and bumps the revision',
    seed: () => const ClinicPulseState(
      status: ClinicPulseStatus.ready,
      waiting: 2,
      todayBookings: 1,
      lowStock: 3,
      revision: 1,
    ),
    build: () {
      when(() => queueRepository.getCurrentQueue())
          .thenThrow(Exception('offline'));
      when(() => appointmentRepository.findAllWithPetDetails())
          .thenAnswer((_) async => [_appointmentWithPet(_appointment())]);
      when(() => inventoryRepository.findLowStock())
          .thenAnswer((_) async => [_lowStockItem()]);
      return build();
    },
    act: (bloc) => bloc.add(const ClinicPulseRefreshRequested()),
    expect: () => [
      const ClinicPulseState(
        status: ClinicPulseStatus.ready,
        waiting: 2,
        todayBookings: 1,
        lowStock: 1,
        revision: 2,
      ),
    ],
  );
}
