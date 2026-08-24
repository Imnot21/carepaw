import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/core/storage/local_storage.dart';
import 'package:carepaw/core/security/secure_storage.dart';
import 'package:carepaw/core/firebase/firebase_init.dart';
import 'package:carepaw/core/sync/background_sync.dart';
import 'package:carepaw/core/sync/sync_engine.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/domain/repositories/auth_repository.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage services
  await LocalStorage.init();
  SecureStorage.init();

  // Initialize Firebase
  await FirebaseInit.initialize();

  // Configure dependency injection
  await configureDependencies();

  // Initialize background sync
  final syncController = SyncController(
    syncEngine: getIt<SyncEngine>(),
    syncRepo: getIt<SyncRepository>(),
  );
  await syncController.initialize();

  runApp(const CarePawApp());
}

/// Main application widget
class CarePawApp extends StatelessWidget {
  const CarePawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PetRepository>(
          create: (context) => getIt<PetRepository>(),
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
        home: const _InitializingScreen(),
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
