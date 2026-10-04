import 'package:carepaw/core/errors/failures.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/authentication/domain/repositories/auth_repository.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late AuthResult adminResult;
  late AuthResult ownerResult;

  setUpAll(() {
    registerFallbackValue(UserRole.admin);
    registerFallbackValue(UserRole.petOwner);
    registerFallbackValue(UserRole.staff);
    registerFallbackValue(UserRole.veterinarian);
  });

  setUp(() {
    repository = MockAuthRepository();

    final now = DateTime(2026, 1, 1);
    adminResult = AuthResult(
      user: User(
        id: 1,
        firebaseUid: 'uid-admin',
        email: 'admin@carepaw.app',
        fullName: 'Dr. Admin',
        role: UserRole.admin,
        createdAt: now,
        updatedAt: now,
      ),
      accessToken: 'id-token-1',
      refreshToken: 'uid-admin',
      expiresAt: now.add(const Duration(hours: 1)),
    );

    ownerResult = AuthResult(
      user: User(
        id: 2,
        firebaseUid: 'uid-owner',
        email: 'owner@example.com',
        fullName: 'Pet Owner',
        role: UserRole.petOwner,
        createdAt: now,
        updatedAt: now,
      ),
      accessToken: 'id-token-2',
      refreshToken: 'uid-owner',
      expiresAt: now.add(const Duration(hours: 1)),
    );

    // The signal the block relies on a live auth-state stream. An empty stream
    // keeps the subscription active without injecting unrelated states.
    when(
      () => repository.authStateStream,
    ).thenAnswer((_) => Stream<AuthResult?>.empty());
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] on successful admin login',
      build: () {
        when(
          () => repository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => adminResult);
        return AuthBloc(authRepository: repository);
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: ' ADMIN@CAREPAW.APP ',
          password: 'secret123',
        ),
      ),
      expect: () => [const AuthLoading(), AuthAuthenticated(adminResult)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] on successful pet-owner registration',
      build: () {
        when(
          () => repository.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            role: any(named: 'role'),
          ),
        ).thenAnswer((_) async => ownerResult);
        return AuthBloc(authRepository: repository);
      },
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          email: 'owner@example.com',
          password: 'secret123',
          fullName: 'Pet Owner',
        ),
      ),
      expect: () => [const AuthLoading(), AuthAuthenticated(ownerResult)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Error] on invalid credentials',
      build: () {
        when(
          () => repository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const InvalidCredentialsFailure());
        return AuthBloc(authRepository: repository);
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: 'bad@carepaw.app', password: 'wrong'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError(InvalidCredentialsFailure()),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Unauthenticated] on logout',
      build: () {
        when(() => repository.logout()).thenAnswer((_) async {});
        return AuthBloc(authRepository: repository);
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Unauthenticated] when no saved session exists',
      build: () {
        when(() => repository.getCurrentUser()).thenAnswer((_) async => null);
        return AuthBloc(authRepository: repository);
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );
  });
}
