import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:device_preview/device_preview.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/core/storage/local_storage.dart';
import 'package:carepaw/core/security/secure_storage.dart';
import 'package:carepaw/core/firebase/firebase_init.dart';
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
import 'package:carepaw/core/widgets/neomorphism/index.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const CarePawApp(),
    ),
  );
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
    // Independent subsystems run in parallel: startup is bounded by the
    // slowest step, not the sum of all of them.
    await Future.wait([
      _initStep(
        'LocalStorage',
        () => LocalStorage.init(),
        timeout: const Duration(seconds: 10),
      ),
      _initStep(
        'SecureStorage',
        () async => SecureStorage.init(),
        timeout: const Duration(seconds: 5),
      ),
      _initStep(
        'Firebase',
        () => FirebaseInit.initialize(),
        timeout: const Duration(seconds: 15),
      ),
      _initStep(
        'LocalNotificationService',
        () => LocalNotificationService.initialize(),
        timeout: const Duration(seconds: 10),
      ),
    ]);

    // Dependency registration needs Firebase to be initialized first.
    try {
      debugPrint('🔄 Configuring Dependencies...');
      await configureDependencies().timeout(const Duration(seconds: 10));
      debugPrint('✅ Dependencies configured');
    } catch (e) {
      debugPrint('⚠️ Dependency configuration failed: $e');
      _initError = e;
    }

    if (mounted) {
      setState(() {
        _servicesInitialized = true;
      });
      debugPrint('🚀 Services initialized');
    }
  }

  /// Run one startup step, logging its outcome without aborting the others.
  Future<void> _initStep(
    String name,
    Future<void> Function() step, {
    required Duration timeout,
  }) async {
    try {
      debugPrint('🔄 Initializing $name...');
      await step().timeout(timeout);
      debugPrint('✅ $name initialized');
    } catch (e) {
      debugPrint('⚠️ $name init failed: $e');
    }
  }

  void _retryInitialization() {
    setState(() {
      _initError = null;
      _servicesInitialized = false;
    });
    _initializeServices();
  }

  @override
  Widget build(BuildContext context) {
    if (!_servicesInitialized) {
      return MaterialApp(
        title: 'CarePaw',
        debugShowCheckedModeBanner: false,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: _initError != null
            ? _InitializationErrorScreen(
                error: _initError!,
                onRetry: _retryInitialization,
              )
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
            create: (context) =>
                AuthBloc(authRepository: getIt<AuthRepository>())
                  ..add(const AuthCheckRequested()),
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

  @override
  void initState() {
    super.initState();
    _authStateListenable = AuthStateListenable();
    // `AuthBloc` is provided by an ancestor (see [_CarePawAppState]), and
    // ancestors are already mounted when this widget initializes — the bloc
    // can be read synchronously, so no delay/rebuild dance is needed.
    _authStateListenable.initialize(context.read<AuthBloc>());
    _router = AppRouter.buildRouter(_authStateListenable);
  }

  @override
  void dispose() {
    _authStateListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CarePaw',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

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
  final VoidCallback onRetry;

  const _InitializationErrorScreen({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withAlpha((255 * 0.45).round()),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Material(
                color: Theme.of(context).cardColor,
                elevation: 0,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 94,
                        height: 94,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: NeuSvgIcon(SvgIcons.error, size: 52),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Initialization Failed',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.error,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'CarePaw could not start properly.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        error.toString(),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const NeuSvgIcon(SvgIcons.refresh, size: 20),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withAlpha((255 * 0.5).round()),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha((255 * 0.22).round()),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: NeuSvgIcon(SvgIcons.paw, size: 58),
              ),
              const SizedBox(height: 24),
              Text(
                'CarePaw',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
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
              const SizedBox(height: 30),
              const NeuCircularProgress(),
              const SizedBox(height: 18),
              Text(
                'Initializing...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
