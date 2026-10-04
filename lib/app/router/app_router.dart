import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/pages/login_page.dart';
import 'package:carepaw/features/authentication/presentation/pages/register_page.dart';
import 'package:carepaw/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:carepaw/features/authentication/presentation/pages/reset_password_page.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/pages/pet_list_page.dart';
import 'package:carepaw/features/pets/presentation/pages/pet_form_page.dart';
import 'package:carepaw/features/pets/presentation/pages/pet_detail_page.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:carepaw/features/appointments/presentation/pages/appointment_list_page.dart';
import 'package:carepaw/features/appointments/presentation/pages/appointment_form_page.dart';
import 'package:carepaw/features/appointments/presentation/pages/appointment_detail_page.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_bloc.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_event.dart';
import 'package:carepaw/features/queue/presentation/pages/queue_page.dart';
import 'package:carepaw/features/queue/presentation/pages/staff_queue_page.dart';
import 'package:carepaw/features/queue/domain/repositories/queue_repository.dart';
import 'package:carepaw/features/home/presentation/pages/home_page.dart';
import 'package:carepaw/features/home/presentation/pages/staff_dashboard_page.dart';
import 'package:carepaw/features/home/presentation/pages/vet_dashboard_page.dart';
import 'package:carepaw/features/home/presentation/pages/admin_dashboard_page.dart';
import 'package:carepaw/features/audit/presentation/bloc/audit_log_bloc.dart';
import 'package:carepaw/features/audit/presentation/bloc/audit_log_event.dart';
import 'package:carepaw/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:carepaw/features/audit/presentation/pages/admin_audit_page.dart';
import 'package:carepaw/features/home/presentation/pages/admin_settings_page.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_bloc.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_event.dart';
import 'package:carepaw/features/users/presentation/pages/admin_user_management_page.dart';
import 'package:carepaw/features/users/presentation/pages/profile_page.dart';
import 'package:carepaw/features/medical_records/presentation/pages/medical_record_list_page.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:carepaw/features/inventory/presentation/pages/inventory_list_page.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_bloc.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_event.dart';
import 'package:carepaw/features/scanning/domain/repositories/scan_repository.dart';
import 'package:carepaw/features/scanning/presentation/pages/scan_list_page.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_event.dart';
import 'package:carepaw/features/notifications/domain/repositories/notification_repository.dart';
import 'package:carepaw/features/notifications/presentation/pages/notification_list_page.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/shell/app_shell.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';

/// Application router configuration using GoRouter.
///
/// Provides declarative routing with:
/// - Deep linking support
/// - Role-based route protection
/// - Authentication state awareness
/// - Error handling
class AppRouter {
  AppRouter._();

  /// Global navigator key for context access
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// Shell navigator key for nested navigation
  static final GlobalKey<NavigatorState> shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  /// Build the router with a custom refresh listenable
  static GoRouter buildRouter(AuthStateListenable refreshListenable) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: Routes.splash,
      debugLogDiagnostics: true,
      refreshListenable: refreshListenable,
      routes: _buildRoutes(),
      errorBuilder: (context, state) => ErrorPage(error: state.error),
      redirect: _buildRedirect(refreshListenable),
    );
  }

  /// Build all routes
  static List<RouteBase> _buildRoutes() {
    return [
      // Splash screen
      GoRoute(
        path: Routes.splash,
        name: RouteNames.splash,
        builder: (context, state) => const _SplashPage(),
      ),

      // Authentication routes
      GoRoute(
        path: Routes.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: Routes.resetPassword,
        name: RouteNames.resetPassword,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordPage(token: token);
        },
      ),

      // Authenticated content lives inside the bottom-nav shell.
      // Each child route is a top-level destination; the shell renders the
      // active page and highlights the matching tab for the user's role.
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Main home route (redirects based on role)
          GoRoute(
            path: Routes.home,
            name: RouteNames.home,
            builder: (context, state) => const HomePage(),
          ),

          // Pet Owner routes
          GoRoute(
            path: Routes.pets,
            name: RouteNames.pets,
            builder: (context, state) => const PetListPage(),
            routes: [
              GoRoute(
                path: 'add',
                name: RouteNames.petAdd,
                builder: (context, state) {
                  // Get owner ID from auth state
                  final authState = context.read<AuthBloc>().state;
                  final ownerId = authState is AuthAuthenticated
                      ? authState.user.id!
                      : 0;
                  return BlocProvider(
                    create: (context) =>
                        PetBloc(petRepository: getIt<PetRepository>()),
                    child: PetFormPage(ownerId: ownerId),
                  );
                },
              ),
              GoRoute(
                path: ':id',
                name: RouteNames.petDetail,
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const PlaceholderPage(title: 'Invalid Pet ID');
                  }
                  return PetDetailPageWithBloc(petId: id);
                },
              ),
              GoRoute(
                path: ':id/edit',
                name: RouteNames.petEdit,
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const PlaceholderPage(title: 'Invalid Pet ID');
                  }
                  return PetFormPageWithBloc(petId: id);
                },
              ),
            ],
          ),

          GoRoute(
            path: Routes.appointments,
            name: RouteNames.appointments,
            builder: (context, state) => BlocProvider(
              create: (context) => AppointmentBloc(
                repository: getIt<AppointmentRepository>(),
                authBloc: context.read<AuthBloc>(),
              )..add(const AppointmentLoadRequested()),
              child: const AppointmentListPage(),
            ),
            routes: [
              GoRoute(
                path: 'request',
                name: RouteNames.appointmentRequest,
                builder: (context, state) {
                  // Get petId and veterinarianId from query parameters if provided
                  final petId = int.tryParse(
                    state.uri.queryParameters['petId'] ?? '',
                  );
                  final veterinarianId = int.tryParse(
                    state.uri.queryParameters['veterinarianId'] ?? '',
                  );
                  // Get user role from auth state
                  final authState = context.read<AuthBloc>().state;
                  final userRole = authState is AuthAuthenticated
                      ? authState.user.role
                      : UserRole.petOwner;
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (context) =>
                            PetBloc(petRepository: getIt<PetRepository>()),
                      ),
                      BlocProvider(
                        create: (context) => AppointmentBloc(
                          repository: getIt<AppointmentRepository>(),
                          authBloc: context.read<AuthBloc>(),
                        ),
                      ),
                    ],
                    child: AppointmentFormPage(
                      petId: petId,
                      veterinarianId: veterinarianId,
                      userRole: userRole,
                    ),
                  );
                },
              ),
              GoRoute(
                path: ':id',
                name: RouteNames.appointmentDetail,
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const PlaceholderPage(
                      title: 'Invalid Appointment ID',
                    );
                  }
                  return BlocProvider(
                    create: (context) => AppointmentBloc(
                      repository: getIt<AppointmentRepository>(),
                      authBloc: context.read<AuthBloc>(),
                    )..add(AppointmentDetailLoadRequested(id)),
                    child: AppointmentDetailPageWithBloc(appointmentId: id),
                  );
                },
              ),
              GoRoute(
                path: ':id/edit',
                name: RouteNames.appointmentEdit,
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const PlaceholderPage(
                      title: 'Invalid Appointment ID',
                    );
                  }
                  // Get user role from auth state
                  final authState = context.read<AuthBloc>().state;
                  final userRole = authState is AuthAuthenticated
                      ? authState.user.role
                      : UserRole.petOwner;
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (context) =>
                            PetBloc(petRepository: getIt<PetRepository>()),
                      ),
                      BlocProvider(
                        create: (context) => AppointmentBloc(
                          repository: getIt<AppointmentRepository>(),
                          authBloc: context.read<AuthBloc>(),
                        ),
                      ),
                    ],
                    child: AppointmentFormPage(
                      appointmentId: id,
                      userRole: userRole,
                    ),
                  );
                },
              ),
            ],
          ),

          // Queue route for pet owners — provides Queue + Appointments so the
          // empty state can surface a "Check in an upcoming appointment" list.
          GoRoute(
            path: Routes.queue,
            name: RouteNames.queue,
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => QueueBloc(
                    repository: getIt<QueueRepository>(),
                    authBloc: context.read<AuthBloc>(),
                  )..add(const QueueLoadRequested()),
                ),
                BlocProvider(
                  create: (context) => AppointmentBloc(
                    repository: getIt<AppointmentRepository>(),
                    authBloc: context.read<AuthBloc>(),
                  )..add(const AppointmentLoadRequested()),
                ),
              ],
              child: const QueuePage(),
            ),
          ),

          GoRoute(
            path: Routes.medicalRecords,
            name: RouteNames.medicalRecordsRoute,
            builder: (context, state) {
              final petId = int.tryParse(
                state.uri.queryParameters['petId'] ?? '',
              );
              if (petId == null) {
                return const PlaceholderPage(
                  title: 'Medical Records - Pet Required',
                );
              }
              return BlocProvider(
                create: (context) =>
                    PetBloc(petRepository: getIt<PetRepository>())
                      ..add(LoadPetsById(petId)),
                child: _MedicalRecordsLoader(petId: petId),
              );
            },
          ),

          // Staff routes
          GoRoute(
            path: Routes.staffDashboard,
            name: RouteNames.staffDashboard,
            builder: (context, state) => const StaffDashboardPage(),
            routes: [
              GoRoute(
                path: 'appointments',
                name: RouteNames.staffAppointments,
                builder: (context, state) => BlocProvider(
                  create: (context) => AppointmentBloc(
                    repository: getIt<AppointmentRepository>(),
                    authBloc: context.read<AuthBloc>(),
                  )..add(const AppointmentLoadRequested()),
                  child: const AppointmentListPage(),
                ),
              ),
              GoRoute(
                path: 'queue',
                name: RouteNames.staffQueue,
                builder: (context, state) => BlocProvider(
                  create: (context) => QueueBloc(
                    repository: getIt<QueueRepository>(),
                    authBloc: context.read<AuthBloc>(),
                  )..add(const QueueStaffLoadRequested()),
                  child: const StaffQueuePage(),
                ),
              ),
              GoRoute(
                path: 'inventory',
                name: RouteNames.staffInventory,
                builder: (context, state) => BlocProvider(
                  create: (context) => InventoryBloc(
                    itemRepository: getIt<InventoryItemRepository>(),
                    batchRepository: getIt<InventoryBatchRepository>(),
                    transactionRepository:
                        getIt<InventoryTransactionRepository>(),
                  )..add(const LoadInventoryItems()),
                  child: const InventoryListPage(),
                ),
              ),
              GoRoute(
                path: 'scanning',
                name: RouteNames.staffScanning,
                builder: (context, state) => BlocProvider(
                  create: (context) =>
                      ScanBloc(scanRepository: getIt<ScanRecordRepository>())
                        ..add(const LoadScanRecords()),
                  child: const ScanListPage(),
                ),
              ),
            ],
          ),

          // Veterinarian routes
          GoRoute(
            path: Routes.vetDashboard,
            name: RouteNames.vetDashboard,
            builder: (context, state) => const VetDashboardPage(),
            routes: [
              GoRoute(
                path: 'patients',
                name: RouteNames.vetPatients,
                builder: (context, state) => BlocProvider(
                  create: (context) =>
                      PetBloc(petRepository: getIt<PetRepository>()),
                  child: const PetListPage(),
                ),
              ),
              GoRoute(
                path: 'patients/:id',
                name: RouteNames.vetPatientDetail,
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const PlaceholderPage(title: 'Invalid Pet ID');
                  }
                  return PetDetailPageWithBloc(petId: id);
                },
              ),
              GoRoute(
                path: 'records',
                name: RouteNames.vetRecords,
                builder: (context, state) {
                  final petId = int.tryParse(
                    state.uri.queryParameters['petId'] ?? '',
                  );
                  if (petId == null) {
                    return const PlaceholderPage(
                      title: 'Records - Pet Required',
                    );
                  }
                  return BlocProvider(
                    create: (context) =>
                        PetBloc(petRepository: getIt<PetRepository>())
                          ..add(LoadPetsById(petId)),
                    child: _MedicalRecordsLoader(petId: petId),
                  );
                },
              ),
            ],
          ),

          // Admin routes
          GoRoute(
            path: Routes.adminDashboard,
            name: RouteNames.adminDashboard,
            builder: (context, state) => const AdminDashboardPage(),
            routes: [
              GoRoute(
                path: 'users',
                name: RouteNames.adminUsers,
                builder: (context, state) => BlocProvider(
                  create: (context) => UserManagementBloc(
                    userRepository: getIt<UserRepository>(),
                  )..add(const UserManagementLoadRequested()),
                  child: const AdminUserManagementPage(),
                ),
              ),
              GoRoute(
                path: 'settings',
                name: RouteNames.adminSettings,
                builder: (context, state) => const AdminSettingsPage(),
              ),
              GoRoute(
                path: 'audit',
                name: RouteNames.adminAudit,
                builder: (context, state) => BlocProvider(
                  create: (context) => AuditLogBloc(
                    auditLogRepository: getIt<AuditLogRepository>(),
                  )..add(const AuditLogLoadRequested()),
                  child: const AdminAuditPage(),
                ),
              ),
            ],
          ),

          // Common routes
          GoRoute(
            path: Routes.notifications,
            name: RouteNames.notifications,
            builder: (context, state) => BlocProvider(
              create: (context) => NotificationBloc(
                notificationRepository: getIt<NotificationRepository>(),
              )..add(const LoadNotifications()),
              child: const NotificationListPage(),
            ),
          ),
          GoRoute(
            path: Routes.profile,
            name: RouteNames.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ];
  }

  /// Build redirect logic for authentication and role-based access
  static String? Function(BuildContext, GoRouterState) _buildRedirect(
    AuthStateListenable authListenable,
  ) {
    return (context, state) {
      final authState = authListenable.authState;
      final user = switch (authState) {
        AuthAuthenticated() => authState.user,
        _ => null,
      };
      final isAuthenticated = user != null;
      final userRole = user?.role ?? UserRole.petOwner;

      final location = state.matchedLocation;
      final isAuthRoute =
          location.startsWith(Routes.login) ||
          location.startsWith(Routes.register) ||
          location.startsWith(Routes.forgotPassword) ||
          location.startsWith(Routes.resetPassword);
      final isSplashRoute = location == Routes.splash;
      final isLoading = authState is AuthLoading;
      final isInitial = authState is AuthInitial;

      // If still loading or initial (auth check not started), don't redirect yet (stay on current route)
      if (isLoading || isInitial) {
        return null;
      }

      // Allow splash route without auth, but redirect to login after auth check completes if unauthenticated
      if (isSplashRoute) {
        if (!isAuthenticated) {
          return Routes.login;
        }
        // Authenticated on splash - redirect to home
        return _getHomeRouteForRole(userRole);
      }

      // If not authenticated and not on auth route, redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return Routes.login;
      }

      // If authenticated and on auth route, redirect to appropriate home
      if (isAuthenticated && isAuthRoute) {
        return _getHomeRouteForRole(userRole);
      }

      // Role-based route protection
      if (isAuthenticated) {
        // Staff routes require STAFF or ADMIN
        if (location.startsWith(Routes.staffDashboard) &&
            userRole != UserRole.staff &&
            userRole != UserRole.admin) {
          return _getHomeRouteForRole(userRole);
        }

        // Vet routes require VETERINARIAN or ADMIN
        if (location.startsWith(Routes.vetDashboard) &&
            userRole != UserRole.veterinarian &&
            userRole != UserRole.admin) {
          return _getHomeRouteForRole(userRole);
        }

        // Admin routes require ADMIN
        if (location.startsWith(Routes.adminDashboard) &&
            userRole != UserRole.admin) {
          return _getHomeRouteForRole(userRole);
        }
      }

      return null; // No redirect needed
    };
  }

  /// Get the appropriate home route for a user role
  static String _getHomeRouteForRole(UserRole role) {
    return switch (role) {
      UserRole.admin => Routes.adminDashboard,
      UserRole.veterinarian => Routes.vetDashboard,
      UserRole.staff => Routes.staffDashboard,
      UserRole.petOwner => Routes.home,
    };
  }
}

/// Listenable for auth state changes to refresh GoRouter
class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable();

  AuthState? _authState;

  AuthState? get authState => _authState;

  /// Initialize the listener with the AuthBloc
  void initialize(AuthBloc authBloc) {
    _authState = authBloc.state;
    authBloc.stream.listen((state) {
      _authState = state;
      // Notify router to re-evaluate redirects
      notifyListeners();
    });
  }
}

/// Splash page shown on app startup
class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    // Trigger auth check on splash
    context.read<AuthBloc>().add(const AuthCheckRequested());

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.pets,
                size: 60,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'CarePaw',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart Veterinary Care',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            const NeuCircularProgress(size: 32, strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}

/// Placeholder page for routes not yet implemented
class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '$title Screen',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This feature is not yet implemented',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error page for routing errors
class ErrorPage extends StatelessWidget {
  final Exception? error;

  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (error != null) ...[
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loads a pet by ID and displays its medical records.
class _MedicalRecordsLoader extends StatelessWidget {
  final int petId;

  const _MedicalRecordsLoader({required this.petId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetBloc, PetState>(
      builder: (context, state) {
        if (state is PetDetailLoaded) {
          return MedicalRecordListPage(pet: state.pet);
        }
        if (state is PetError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Medical Records')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load pet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.failure.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Medical Records')),
          body: const Center(child: NeuCircularProgress()),
        );
      },
    );
  }
}
