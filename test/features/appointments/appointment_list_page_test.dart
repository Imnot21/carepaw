import 'package:bloc_test/bloc_test.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:carepaw/features/appointments/presentation/pages/appointment_list_page.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _AppointmentBloc extends MockBloc<AppointmentEvent, AppointmentState>
    implements AppointmentBloc {}

class _AuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  testWidgets('list page lays out at 320 px and 1.6x text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final visit = Appointment(
      id: 1,
      petId: 1,
      veterinarianId: 1,
      scheduledAt: now.add(const Duration(days: 2)),
      reason: 'A very long reason for the visit ' * 6,
      createdAt: now,
      updatedAt: now,
    );
    final appointments = _AppointmentBloc();
    whenListen(
      appointments,
      const Stream<AppointmentState>.empty(),
      initialState: AppointmentLoaded(
        appointments: [visit],
        upcomingAppointments: [visit],
      ),
    );
    final auth = _AuthBloc();
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: AuthInitial(),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppointmentBloc>.value(value: appointments),
          BlocProvider<AuthBloc>.value(value: auth),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: const AppointmentListPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });
}
