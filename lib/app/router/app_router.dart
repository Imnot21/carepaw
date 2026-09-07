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
import 'package:carepaw/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_bloc.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_event.dart';
import 'package:carepaw/features/queue/presentation/pages/queue_page.dart';
import 'package:carepaw/features/queue/presentation/pages/staff_queue_page.dart';
import 'package:carepaw/features/queue/data/repositories/queue_repository_impl.dart';
import 'package:carepaw/features/home/presentation/pages/home_page.dart';
import 'package:carepaw/features/home/presentation/pages/staff_dashboard_page.dart';
import 'package:carepaw/features/home/presentation/pages/vet_dashboard_page.dart';
import 'package:carepaw/features/home/presentation/pages/admin_dashboard_page.dart';
import 'package:carepaw/features/users/presentation/pages/admin_user_management_page.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/core/widgets/common/cp_loader.dart';

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
              final ownerId = authState is AuthAuthenticated ? authState.user.id! : 0;
              return BlocProvider(
                create: (context) => PetBloc(petRepository: getIt<PetRepository>()),
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
            repository: getIt<AppointmentRepositoryImpl>(),
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
              final petId = int.tryParse(state.uri.queryParameters['petId'] ?? '');
              final veterinarianId = int.tryParse(state.uri.queryParameters['veterinarianId'] ?? '');
              // Get user role from auth state
              final authState = context.read<AuthBloc>().state;
              final userRole = authState is AuthAuthenticated ? authState.user.role : UserRole.petOwner;
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (context) => PetBloc(petRepository: getIt<PetRepository>()),
                  ),
                  BlocProvider(
                    create: (context) => AppointmentBloc(
                      repository: getIt<AppointmentRepositoryImpl>(),
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
                return const PlaceholderPage(title: 'Invalid Appointment ID');
              }
              return BlocProvider(
                create: (context) => AppointmentBloc(
                  repository: getIt<AppointmentRepositoryImpl>(),
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
                return const PlaceholderPage(title: 'Invalid Appointment ID');
              }
              // Get user role from auth state
              final authState = context.read<AuthBloc>().state;
              final userRole = authState is AuthAuthenticated ? authState.user.role : UserRole.petOwner;
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (context) => PetBloc(petRepository: getIt<PetRepository>()),
                  ),
                  BlocProvider(
                    create: (context) => AppointmentBloc(
                      repository: getIt<AppointmentRepositoryImpl>(),
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

      // Queue route for pet owners
      GoRoute(
        path: Routes.queue,
        name: RouteNames.queue,
        builder: (context, state) => BlocProvider(
          create: (context) => QueueBloc(
            repository: getIt<QueueRepositoryImpl>(),
            authBloc: context.read<AuthBloc>(),
          )..add(const QueueLoadRequested()),
          child: const QueuePage(),
        ),
      ),

      GoRoute(
        path: Routes.medicalRecords,
        name: RouteNames.medicalRecordsRoute,
        builder: (context, state) => const PlaceholderPage(title: 'Medical Records'),
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
            builder: (context, state) => const PlaceholderPage(title: 'Staff Appointments'),
          ),
          GoRoute(
            path: 'queue',
            name: RouteNames.staffQueue,
            builder: (context, state) => BlocProvider(
              create: (context) => QueueBloc(
                repository: getIt<QueueRepositoryImpl>(),
                authBloc: context.read<AuthBloc>(),
              )..add(const QueueStaffLoadRequested()),
              child: const StaffQueuePage(),
            ),
          ),
          GoRoute(
            path: 'inventory',
            name: RouteNames.staffInventory,
            builder: (context, state) => const PlaceholderPage(title: 'Inventory'),
          ),
          GoRoute(
            path: 'scanning',
            name: RouteNames.staffScanning,
            builder: (context, state) => const PlaceholderPage(title: 'Scanning'),
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
            builder: (context, state) => const PlaceholderPage(title: 'Patients'),
          ),
          GoRoute(
            path: 'patients/:id',
            name: RouteNames.vetPatientDetail,
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return PlaceholderPage(title: 'Patient - $id');
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
            builder: (context, state) => const AdminUserManagementPage(),
          ),
          GoRoute(
            path: 'settings',
            name: RouteNames.adminSettings,
            builder: (context, state) => const PlaceholderPage(title: 'Settings'),
          ),
          GoRoute(
            path: 'audit',
            name: RouteNames.adminAudit,
            builder: (context, state) => const PlaceholderPage(title: 'Audit Logs'),
          ),
        ],
      ),

      // Common routes
      GoRoute(
        path: Routes.notifications,
        name: RouteNames.notifications,
        builder: (context, state) => const PlaceholderPage(title: 'Notifications'),
      ),
      GoRoute(
        path: Routes.profile,
        name: RouteNames.profile,
        builder: (context, state) => const PlaceholderPage(title: 'Profile'),
      ),
      GoRoute(
        path: Routes.settings,
        name: RouteNames.settings,
        builder: (context, state) => const PlaceholderPage(title: 'Settings'),
      ),
    ];
  }

  /// Build redirect logic for authentication and role-based access
  static String? Function(BuildContext, GoRouterState) _buildRedirect(AuthStateListenable authListenable) {
    return (context, state) {
      final authState = authListenable.authState;
      final user = switch (authState) {
        AuthAuthenticated() => authState.user,
        _ => null,
      };
      final isAuthenticated = user != null;
      final userRole = user?.role ?? UserRole.petOwner;

      final location = state.matchedLocation;
      final isAuthRoute = location.startsWith(Routes.login) ||
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
            const CpLoader(size: 32, strokeWidth: 3),
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
      appBar: AppBar(
        title: Text(title),
      ),
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
      appBar: AppBar(
        title: const Text('Error'),
      ),
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