import 'package:bloc_test/bloc_test.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_bloc.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_event.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_state.dart';
import 'package:carepaw/features/users/presentation/pages/admin_user_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _UsersBloc extends MockBloc<UserManagementEvent, UserManagementState>
    implements UserManagementBloc {}

class _AuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

User _user(int id, String name) => User(
  id: id,
  email: '$name@example.com',
  fullName: '$name with a very long display name for overflow',
  role: UserRole.ownerAdmin,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  testWidgets('accounts page does not overflow at 320px and 1.6x text', (
    tester,
  ) async {
    final users = _UsersBloc();
    final auth = _AuthBloc();
    whenListen(
      users,
      const Stream<UserManagementState>.empty(),
      initialState: UserManagementLoaded([_user(1, 'alpha'), _user(2, 'beta')]),
    );
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthInitial(),
    );
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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
            BlocProvider<UserManagementBloc>.value(value: users),
            BlocProvider<AuthBloc>.value(value: auth),
          ],
          child: const AdminUserManagementPage(),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
