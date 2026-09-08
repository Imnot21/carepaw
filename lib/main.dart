import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:device_preview/device_preview.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/core/storage/local_storage.dart';
import 'package:carepaw/core/security/secure_storage.dart';
import 'package:carepaw/core/firebase/firebase_init.dart';
import 'package:carepaw/core/sync/background_sync.dart';
import 'package:carepaw/core/notifications/local_notification_service.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/domain/repositories/auth_repository.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/queue/domain/repositories/queue_repository.dart';
import 'package:carepaw/features/medical_records/domain/repositories/medical_record_repository.dart';
import 'package:carepaw/features/medical_records/domain/repositories/vaccination_repository.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:carepaw/features/scanning/domain/repositories/scan_repository.dart';
import 'package:carepaw/features/notifications/domain/repositories/notification_repository.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';

void main() async {
  // Enable device preview ONLY for web/desktop development (simulates mobile devices)
  // Disable on actual mobile devices (Android/iOS) to avoid initialization issues
  final isMobile = defaultTargetPlatform == TargetPlatform.android ||
                   defaultTargetPlatform == TargetPlatform.iOS;
  DevicePreview.enable(
    enabled: !kReleaseMode && !isMobile,
    padding: const EdgeInsets.all(16),
    backgroundDecoration: const BoxDecoration(color: Color(0xFF1D1D25)),
  );

  WidgetsFlutterBinding.ensureInitialized();

  // Run app IMMEDIATELY with initializing screen
  // Do all heavy initialization in background after first frame
  runApp(const CarePawApp());
}

/// Main application widget
class CarePawApp extends StatefulWidget {
  const CarePawApp({super.key});

  @override
  State<CarePawApp> createState() => _CarePawAppState();
}

class _CarePawAppState extends State<CarePawApp> {
  bool _servicesInitialized = false;
  Object? _initError;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      debugPrint('🔄 Initializing LocalStorage...');
      await LocalStorage.init().timeout(const Duration(seconds: 10));
      debugPrint('✅ LocalStorage initialized');
    } catch (e) {
      debugPrint('⚠️ LocalStorage init failed: $e');
    }

    try {
      debugPrint('🔄 Initializing SecureStorage...');
      SecureStorage.init();
      debugPrint('✅ SecureStorage initialized');
    } catch (e) {
      debugPrint('⚠️ SecureStorage init failed: $e');
    }

    try {
      debugPrint('🔄 Initializing Firebase...');
      await FirebaseInit.initialize().timeout(const Duration(seconds: 15));
      debugPrint('✅ Firebase initialized');
    } catch (e) {
      debugPrint('⚠️ Firebase init failed: $e');
    }

    try {
      debugPrint('🔄 Initializing LocalNotificationService...');
      await LocalNotificationService.initialize().timeout(const Duration(seconds: 10));
      debugPrint('✅ LocalNotificationService initialized');
    } catch (e) {
      debugPrint('⚠️ LocalNotificationService init failed: $e');
    }

    try {
      debugPrint('🔄 Configuring Dependencies...');
      await configureDependencies().timeout(const Duration(seconds: 10));
      debugPrint('✅ Dependencies configured');
    } catch (e) {
      debugPrint('⚠️ Dependency configuration failed: $e');
      _initError = e;
    }

    try {
      debugPrint('🔄 Initializing Background Sync...');
      final syncController = getIt<SyncController>();
      await syncController.initialize().timeout(const Duration(seconds: 10));
      debugPrint('✅ Background Sync initialized');
    } catch (e) {
      debugPrint('⚠️ Background Sync init failed: $e');
    }

    if (mounted) {
      setState(() {
        _servicesInitialized = true;
      });
      debugPrint('🚀 Services initialized');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_servicesInitialized) {
      return MaterialApp(
        title: 'CarePaw',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: _initError != null
            ? _InitializationErrorScreen(error: _initError!)
            : const _InitializingScreen(),
      );
    }

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => getIt<AuthRepository>(),
        ),
        RepositoryProvider<UserRepository>(
          create: (context) => getIt<UserRepository>(),
        ),
        RepositoryProvider<PetRepository>(
          create: (context) => getIt<PetRepository>(),
        ),
        RepositoryProvider<AppointmentRepository>(
          create: (context) => getIt<AppointmentRepository>(),
        ),
        RepositoryProvider<QueueRepository>(
          create: (context) => getIt<QueueRepository>(),
        ),
        RepositoryProvider<MedicalRecordRepository>(
          create: (context) => getIt<MedicalRecordRepository>(),
        ),
        RepositoryProvider<VaccinationRepository>(
          create: (context) => getIt<VaccinationRepository>(),
        ),
        RepositoryProvider<InventoryItemRepository>(
          create: (context) => getIt<InventoryItemRepository>(),
        ),
        RepositoryProvider<InventoryBatchRepository>(
          create: (context) => getIt<InventoryBatchRepository>(),
        ),
        RepositoryProvider<InventoryTransactionRepository>(
          create: (context) => getIt<InventoryTransactionRepository>(),
        ),
        RepositoryProvider<ScanRecordRepository>(
          create: (context) => getIt<ScanRecordRepository>(),
        ),
        RepositoryProvider<NotificationRepository>(
          create: (context) => getIt<NotificationRepository>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: getIt<AuthRepository>(),
            )..add(const AuthCheckRequested()),
          ),
        ],
        child: _CarePawAppRouter(),
      ),
    );
  }
}

/// Separate widget to initialize router after BlocProvider is ready
class _CarePawAppRouter extends StatefulWidget {
  const _CarePawAppRouter();

  @override
  State<_CarePawAppRouter> createState() => _CarePawAppRouterState();
}

class _CarePawAppRouterState extends State<_CarePawAppRouter> {
  late final AuthStateListenable _authStateListenable;
  late final GoRouter _router;
  bool _initialized = false;
  Object? _initError;

  @override
  void initState() {
    super.initState();
    _authStateListenable = AuthStateListenable();
    // Initialize the listenable with the AuthBloc immediately
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Small delay to ensure BlocProvider is fully ready
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    try {
      final authBloc = context.read<AuthBloc>();
      _authStateListenable.initialize(authBloc);
      _initialized = true;
      // Build router with the listenable AFTER initialization
      _router = AppRouter.buildRouter(_authStateListenable);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Handle initialization error
      debugPrint('Auth initialization error: $e');
      _initError = e;
      _router = AppRouter.buildRouter(_authStateListenable);
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _authStateListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        title: 'CarePaw',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: _initError != null
            ? _InitializationErrorScreen(error: _initError!)
            : const _InitializingScreen(),
      );
    }

    return MaterialApp.router(
      title: 'CarePaw',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Router configuration with auth state listener
      routerConfig: _router,
    );
  }
}

/// Screen shown when initialization fails
class _InitializationErrorScreen extends StatelessWidget {
  final Object error;

  const _InitializationErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 60,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Initialization Failed',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'CarePaw could not start properly.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  // Restart the app by exiting
                  SystemNavigator.pop();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen shown while initializing auth
class _InitializingScreen extends StatelessWidget {
  const _InitializingScreen();

  @override
  Widget build(BuildContext context) {
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
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Initializing...',
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
