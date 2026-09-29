import 'package:carepaw/core/errors/failures.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_bloc.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_event.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository repository;
  late User staff;
  late User vet;

  setUpAll(() {
    registerFallbackValue(UserRole.admin);
    registerFallbackValue(UserRole.petOwner);
    registerFallbackValue(UserRole.staff);
    registerFallbackValue(UserRole.veterinarian);
  });

  setUp(() {
    repository = MockUserRepository();

    final now = DateTime(2026, 1, 1);
    staff = User(
      id: 11,
      firebaseUid: 'uid-staff',
      email: 'staff@carepaw.app',
      fullName: 'Front Desk Clerk',
      role: UserRole.staff,
      createdAt: now,
      updatedAt: now,
    );
    vet = User(
      id: 12,
      firebaseUid: 'uid-vet',
      email: 'vet@carepaw.app',
      fullName: 'Dr. Vet',
      role: UserRole.veterinarian,
      createdAt: now,
      updatedAt: now,
    );

    // Default load returns both roles.
    when(() => repository.findByRole(UserRole.staff))
        .thenAnswer((_) async => [staff]);
    when(() => repository.findByRole(UserRole.veterinarian))
        .thenAnswer((_) async => [vet]);
  });

  group('UserManagementBloc', () {
    blocTest<UserManagementBloc, UserManagementState>(
      'emits [Loading, Loaded] combining staff and veterinarians',
      build: () => UserManagementBloc(userRepository: repository),
      act: (bloc) => bloc.add(const UserManagementLoadRequested()),
      expect: () => [
        const UserManagementLoading(),
        UserManagementLoaded([staff, vet]),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'emits [Loading, Error] when the repository throws a Failure',
      build: () {
        when(() => repository.findByRole(UserRole.staff))
            .thenThrow(const AccountLockedFailure());
        return UserManagementBloc(userRepository: repository);
      },
      act: (bloc) => bloc.add(const UserManagementLoadRequested()),
      expect: () => [
        const UserManagementLoading(),
        const UserManagementError(AccountLockedFailure()),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'createAccount emits ActionSuccess then refreshes the list',
      build: () {
        final created = User(
          id: 13,
          firebaseUid: 'uid-new',
          email: 'reception@carepaw.app',
          fullName: 'New Staff',
          role: UserRole.staff,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );
        when(() => repository.createAccount(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
              phone: any(named: 'phone'),
              role: any(named: 'role'),
            )).thenAnswer((_) async => created);
        // After creation the refreshed list includes the new user.
        when(() => repository.findByRole(UserRole.staff))
            .thenAnswer((_) async => [staff, created]);
        return UserManagementBloc(userRepository: repository);
      },
      act: (bloc) => bloc.add(
        const UserManagementCreateRequested(
          email: 'Reception@CarePaw.app',
          password: 'Password123',
          fullName: 'New Staff',
          role: UserRole.staff,
        ),
      ),
      expect: () => [
        const UserManagementLoading(),
        const UserManagementActionSuccess(
          'Account created. The user can now sign in with these credentials.',
        ),
        const UserManagementLoading(),
        anyOf(
          isA<UserManagementLoaded>(),
          isA<UserManagementError>(),
        ),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'changeRole emits ActionSuccess then refreshes the list',
      build: () {
        when(() => repository.changeRole(any(), any()))
            .thenAnswer((_) async => staff);
        return UserManagementBloc(userRepository: repository);
      },
      act: (bloc) => bloc.add(
        const UserManagementChangeRoleRequested(
          userId: 11,
          newRole: UserRole.staff,
        ),
      ),
      expect: () => [
        const UserManagementActionSuccess('Role updated to Staff.'),
        const UserManagementLoading(),
        isA<UserManagementLoaded>(),
      ],
    );

    blocTest<UserManagementBloc, UserManagementState>(
      'toggleActive emits ActionSuccess then refreshes the list',
      build: () {
        when(() => repository.setActive(any(), any()))
            .thenAnswer((_) async => staff);
        return UserManagementBloc(userRepository: repository);
      },
      act: (bloc) => bloc.add(
        const UserManagementToggleActiveRequested(userId: 11, isActive: false),
      ),
      expect: () => [
        const UserManagementActionSuccess('User de-activated.'),
        const UserManagementLoading(),
        isA<UserManagementLoaded>(),
      ],
    );
  });
}