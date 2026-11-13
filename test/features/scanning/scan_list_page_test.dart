import 'package:bloc_test/bloc_test.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_bloc.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_event.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_state.dart';
import 'package:carepaw/features/scanning/presentation/pages/scan_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _AuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _ScanBloc extends MockBloc<ScanEvent, ScanState> implements ScanBloc {}

void main() {
  testWidgets('scan list page lays out at 320 wide and 1.6x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final now = DateTime(2026, 1, 1);
    final auth = _AuthBloc();
    final scan = _ScanBloc();
    final state = AuthAuthenticated(
      AuthResult(
        user: User(
          id: 1,
          email: 'a@b.c',
          fullName: 'Admin',
          role: UserRole.ownerAdmin,
          createdAt: now,
          updatedAt: now,
        ),
        accessToken: 't',
        refreshToken: 'r',
        expiresAt: now,
      ),
    );
    whenListen(auth, const Stream<AuthState>.empty(), initialState: state);
    whenListen(
      scan,
      const Stream<ScanState>.empty(),
      initialState: const ScanRecordsLoaded([]),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: auth),
            BlocProvider<ScanBloc>.value(value: scan),
          ],
          child: const ScanListPage(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Medicine box'), findsOneWidget);
  });
}
