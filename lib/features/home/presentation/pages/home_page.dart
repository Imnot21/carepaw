import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_loader.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';
import 'package:carepaw/core/widgets/effects/scale_on_tap.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Home page for pet owners - main dashboard
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    _NavItem(icon: Icons.pets_outlined, selectedIcon: Icons.pets, label: 'Pets'),
    _NavItem(icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today, label: 'Appointments'),
    _NavItem(icon: Icons.queue_outlined, selectedIcon: Icons.queue, label: 'Queue'),
    _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
  ];

  Future<void> _exportDatabase() async {
    try {
      // Request storage permission (Android 13+)
      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          final status2 = await Permission.storage.request();
          if (!status2.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Storage permission denied')),
              );
            }
            return;
          }
        }
      }

      // Get app database
      final appDir = await getApplicationDocumentsDirectory();
      final dbFile = File('${appDir.path}/carepaw.sqlite');

      if (!await dbFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('DB not found: ${dbFile.path}')),
          );
        }
        return;
      }

      // Copy to Downloads (accessible from Windows File Explorer)
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        // Fallback for scoped storage
        final extDir = await getExternalStorageDirectory();
        final destFile = File('${extDir!.path}/carepaw_export.sqlite');
        await dbFile.copy(destFile.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Exported to: ${destFile.path}')),
          );
        }
        return;
      }

      final destFile = File('${downloadsDir.path}/carepaw_export.sqlite');
      await dbFile.copy(destFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Exported to Downloads/carepaw_export.sqlite')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(Routes.login);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const _LoadingView();
          }

          final user = authState.user;
          final ownerId = user.id!;

          return BlocProvider(
            create: (context) => PetBloc(
              petRepository: context.read<PetRepository>(),
            )..add(LoadPets(ownerId: ownerId)),
            child: AnimatedGradientBackground(
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                AppColors.tertiary.withValues(alpha: 0.03),
              ],
              child: Scaffold(
                backgroundColor: Theme.of(context).colorScheme.surface,
                extendBody: true,
                body: IndexedStack(
                  index: _currentIndex,
                  children: [
                    _HomeContent(onExportDatabase: _exportDatabase),
                    _PetsTab(ownerId: ownerId),
                    _AppointmentsTab(),
                    _QueueTab(),
                    _ProfileTab(),
                  ],
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  destinations: _navItems.map((item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  )).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CpLoader(size: 32, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: AppTextStyles.bodyMedium.subtle,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Home content with quick actions, pet summary, recent activity
class _HomeContent extends StatelessWidget {
  final VoidCallback onExportDatabase;

  const _HomeContent({required this.onExportDatabase});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        final userName = user?.fullName.split(' ').first ?? 'Pet Owner';

        return BlocBuilder<PetBloc, PetState>(
          builder: (context, petState) {
            final pets = petState is PetsLoaded ? petState.pets : <Pet>[];
            final activePets = pets.where((p) => p.isActive).toList();

            return RefreshIndicator(
              onRefresh: () async {
                final state = context.read<AuthBloc>().state;
                if (state is AuthAuthenticated) {
                  context.read<PetBloc>().add(LoadPets(ownerId: state.user.id!));
                }
              },
              child: CustomScrollView(
                slivers: [
                  // App bar with greeting
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${_getGreeting()}, $userName!',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Welcome back to CarePaw',
                          style: AppTextStyles.bodySmall.subtle,
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () => context.push(Routes.notifications),
                        tooltip: 'Notifications',
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => context.push(Routes.settings),
                        tooltip: 'Settings',
                      ),
                      // Export DB button (debug)
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: onExportDatabase,
                        tooltip: 'Export Database to Downloads',
                      ),
                    ],
                  ),

                  // Main content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Actions
                          _QuickActionsSection(),
                          const SizedBox(height: 24),

                          // Pet Summary
                          _PetSummarySection(pets: activePets),
                          const SizedBox(height: 24),

                          // Upcoming Appointments (placeholder)
                          _UpcomingAppointmentsSection(),
                          const SizedBox(height: 24),

                          // Quick Links
                          _QuickLinksSection(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

/// Pets tab that uses the shared PetBloc from HomePage
class _PetsTab extends StatelessWidget {
  final int ownerId;

  const _PetsTab({required this.ownerId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const _NotLoggedInView();
        }

        return _PetListView(ownerId: ownerId);
      },
    );
  }
}

class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Pets')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'Please log in to view your pets',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CpButton(
              text: 'Go to Login',
              onPressed: () => context.push('/login'),
              variant: ButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PetListView extends StatefulWidget {
  final int ownerId;

  const _PetListView({required this.ownerId});

  @override
  State<_PetListView> createState() => _PetListViewState();
}

class _PetListViewState extends State<_PetListView> {
  @override
  void initState() {
    super.initState();
    context.read<PetBloc>().add(LoadPets(ownerId: widget.ownerId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetBloc, PetState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Pets'),
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CpIconButton(
                  icon: Icons.add,
                  onPressed: () => context.push(Routes.petAdd),
                  tooltip: 'Add Pet',
                ),
              ),
            ],
          ),
          body: switch (state) {
            PetLoading() => const Center(child: CpLoader()),
            PetsLoaded() => state.pets.isEmpty
                ? _EmptyPetsList()
                : _PetList(pets: state.pets),
            PetError() => _ErrorView(message: state.failure.message),
            _ => const Center(child: CpLoader()),
          },
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push(Routes.petAdd),
            tooltip: 'Add Pet',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _PetList extends StatelessWidget {
  final List<Pet> pets;

  const _PetList({required this.pets});

  @override
  Widget build(BuildContext context) {
    final activePets = pets.where((p) => p.isActive).toList();

    return RefreshIndicator(
      onRefresh: () async {
        final state = context.read<AuthBloc>().state;
        if (state is AuthAuthenticated) {
          context.read<PetBloc>().add(LoadPets(ownerId: state.user.id!));
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: activePets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final pet = activePets[index];
          return _PetListItem(pet: pet);
        },
      ),
    );
  }
}

class _PetListItem extends StatelessWidget {
  final Pet pet;

  const _PetListItem({required this.pet});

  @override
  Widget build(BuildContext context) {
    final speciesColor = _getSpeciesColor(pet.species);
    final speciesIcon = _getSpeciesIcon(pet.species);

    return ScaleOnTap(
      onTap: () => context.push('/pets/${pet.id}'),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        blur: 12,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.glassBorderDark
            : AppColors.glassBorderLight,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    speciesColor.withValues(alpha: 0.25),
                    speciesColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(speciesIcon, color: speciesColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pet.species.displayName + (pet.breed != null ? ' • ${pet.breed}' : ''),
                    style: AppTextStyles.bodySmall.subtle,
                  ),
                ],
              ),
            ),
            if (pet.birthDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatAge(pet.birthDate!),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  String _formatAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    if (months < 0 || (months == 0 && now.day < birthDate.day)) {
      years--;
      months += 12;
    }
    if (years > 0) {
      return '$years yr${years > 1 ? 's' : ''}${months > 0 ? ' $months mo' : ''}';
    }
    return '$months mo';
  }

  IconData _getSpeciesIcon(PetSpecies species) {
    switch (species) {
      case PetSpecies.dog:
        return Icons.pets;
      case PetSpecies.cat:
        return Icons.pets_outlined;
      case PetSpecies.bird:
        return Icons.flutter_dash;
      case PetSpecies.rabbit:
        return Icons.landscape_outlined;
      case PetSpecies.reptile:
        return Icons.eco_outlined;
      case PetSpecies.other:
        return Icons.help_outline;
    }
  }

  Color _getSpeciesColor(PetSpecies species) {
    switch (species) {
      case PetSpecies.dog:
        return AppColors.dogAccent;
      case PetSpecies.cat:
        return AppColors.catAccent;
      case PetSpecies.bird:
        return AppColors.birdAccent;
      case PetSpecies.rabbit:
        return AppColors.rabbitAccent;
      case PetSpecies.reptile:
        return Colors.green;
      case PetSpecies.other:
        return Colors.grey;
    }
  }
}

class _EmptyPetsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PulsingGlow(
              glowColor: AppColors.primary,
              maxRadius: 30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: PremiumShadows.primary,
                ),
                child: Icon(
                  Icons.pets_outlined,
                  size: 60,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No pets yet',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first pet to get started',
              style: AppTextStyles.bodyMedium.subtle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CpButton(
              text: 'Add Pet',
              onPressed: () => context.push(Routes.petAdd),
              variant: ButtonVariant.primary,
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.gradientError,
                borderRadius: BorderRadius.circular(60),
                boxShadow: PremiumShadows.error,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error loading pets',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.subtle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CpButton(
              text: 'Retry',
              onPressed: () {
                final state = context.read<AuthBloc>().state;
                if (state is AuthAuthenticated) {
                  context.read<PetBloc>().add(LoadPets(ownerId: state.user.id!));
                }
              },
              variant: ButtonVariant.primary,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action buttons section
class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            _QuickActionCard(
              icon: Icons.add,
              label: 'Add Pet',
              color: AppColors.primary,
              onTap: () => context.push(Routes.petAdd),
            ),
            _QuickActionCard(
              icon: Icons.add,
              label: 'Book\nAppointment',
              color: AppColors.primary,
              onTap: () => context.push(Routes.appointmentRequest),
            ),
            _QuickActionCard(
              icon: Icons.queue_outlined,
              label: 'Check\nQueue',
              color: AppColors.info,
              onTap: () => context.push(Routes.queue),
            ),
            _QuickActionCard(
              icon: Icons.medical_services_outlined,
              label: 'Medical\nRecords',
              color: AppColors.success,
              onTap: () => context.push(Routes.medicalRecords),
            ),
            _QuickActionCard(
              icon: Icons.vaccines_outlined,
              label: 'Vaccination\nSchedule',
              color: Colors.purple,
              onTap: () => _showComingSoon(context, 'Vaccination Schedule'),
            ),
            _QuickActionCard(
              icon: Icons.local_pharmacy_outlined,
              label: 'Prescriptions',
              color: Colors.teal,
              onTap: () => _showComingSoon(context, 'Prescriptions'),
            ),
            _QuickActionCard(
              icon: Icons.receipt_long_outlined,
              label: 'Scan\nReceipt',
              color: Colors.orange,
              onTap: () => _showComingSoon(context, 'Scan Receipt'),
            ),
            _QuickActionCard(
              icon: Icons.chat_bubble_outline,
              label: 'Chat with\nVet',
              color: Colors.indigo,
              onTap: () => _showComingSoon(context, 'Chat with Vet'),
            ),
          ],
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pet summary section
class _PetSummarySection extends StatelessWidget {
  final List<Pet> pets;

  const _PetSummarySection({required this.pets});

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) {
      return _EmptyPetsPrompt();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Pets (${pets.length})',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push(Routes.pets),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pets.length > 5 ? 5 : pets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final pet = pets[index];
              return _PetSummaryCard(pet: pet);
            },
          ),
        ),
      ],
    );
  }
}

class _PetSummaryCard extends StatelessWidget {
  final Pet pet;

  const _PetSummaryCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    final speciesColor = _getSpeciesColor(pet.species);
    final speciesIcon = _getSpeciesIcon(pet.species);

    return ScaleOnTap(
      onTap: () => context.push('/pets/${pet.id}'),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: speciesColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    speciesColor.withValues(alpha: 0.2),
                    speciesColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(speciesIcon, color: speciesColor, size: 28),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pet.species.displayName,
                          style: AppTextStyles.bodySmall.subtle,
                        ),
                      ],
                    ),
                    if (pet.birthDate != null)
                      Text(
                        _formatAge(pet.birthDate!),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    if (months < 0 || (months == 0 && now.day < birthDate.day)) {
      years--;
      months += 12;
    }
    if (years > 0) {
      return '$years yr${years > 1 ? 's' : ''}${months > 0 ? ' $months mo' : ''}';
    }
    return '$months mo';
  }

  IconData _getSpeciesIcon(PetSpecies species) {
    switch (species) {
      case PetSpecies.dog:
        return Icons.pets;
      case PetSpecies.cat:
        return Icons.pets_outlined;
      case PetSpecies.bird:
        return Icons.flutter_dash;
      case PetSpecies.rabbit:
        return Icons.landscape_outlined;
      case PetSpecies.reptile:
        return Icons.eco_outlined;
      case PetSpecies.other:
        return Icons.help_outline;
    }
  }

  Color _getSpeciesColor(PetSpecies species) {
    switch (species) {
      case PetSpecies.dog:
        return AppColors.dogAccent;
      case PetSpecies.cat:
        return AppColors.catAccent;
      case PetSpecies.bird:
        return AppColors.birdAccent;
      case PetSpecies.rabbit:
        return AppColors.rabbitAccent;
      case PetSpecies.reptile:
        return Colors.green;
      case PetSpecies.other:
        return Colors.grey;
    }
  }
}

class _EmptyPetsPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      blur: 15,
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.glassBorderDark
          : AppColors.glassBorderLight,
      child: Column(
        children: [
          Icon(
            Icons.pets_outlined,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            'No pets yet',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your first pet to get started',
            style: AppTextStyles.bodyMedium.subtle,
          ),
          const SizedBox(height: 16),
          CpButton(
            text: 'Add Pet',
            onPressed: () => context.push(Routes.petAdd),
            variant: ButtonVariant.primary,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }
}

/// Upcoming appointments section (placeholder)
class _UpcomingAppointmentsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Appointments',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push(Routes.appointments),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(24),
          blur: 15,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.glassBorderDark
              : AppColors.glassBorderLight,
          child: Column(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 12),
              Text(
                'No upcoming appointments',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Book an appointment with your vet',
                style: AppTextStyles.bodyMedium.subtle,
              ),
              const SizedBox(height: 16),
              CpButton(
                text: 'Book Appointment',
                onPressed: () => context.push(Routes.appointmentRequest),
                variant: ButtonVariant.primary,
                icon: Icons.add,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Quick links section
class _QuickLinksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GlassContainer(
          borderRadius: 20,
          blur: 15,
          padding: EdgeInsets.zero,
          borderColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.glassBorderDark
              : AppColors.glassBorderLight,
          child: Column(
            children: [
              _LinkTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Appointment reminders & updates',
                onTap: () => context.push(Routes.notifications),
              ),
              const Divider(height: 1, indent: 56),
              _LinkTile(
                icon: Icons.medical_services_outlined,
                title: 'Medical Records',
                subtitle: 'View health history & vaccinations',
                onTap: () => context.push(Routes.medicalRecords),
              ),
              const Divider(height: 1, indent: 56),
              _LinkTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'FAQs, contact us, feedback',
                onTap: () => _showComingSoon(context, 'Help & Support'),
              ),
              const Divider(height: 1, indent: 56),
              _LinkTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'App preferences & account',
                onTap: () => context.push(Routes.settings),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary.scale(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.subtle,
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.textHint,
      ),
      onTap: onTap,
    );
  }
}

/// Placeholder tabs for other navigation items
class _AppointmentsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(70),
                boxShadow: PremiumShadows.primary,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 70,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text('Appointments', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Coming soon!', style: AppTextStyles.bodyMedium.subtle),
            const SizedBox(height: 16),
            CpButton(
              text: 'Book Appointment',
              onPressed: () => context.push(Routes.appointmentRequest),
              variant: ButtonVariant.primary,
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(70),
                boxShadow: PremiumShadows.primary,
              ),
              child: Icon(
                Icons.queue_outlined,
                size: 70,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text('Queue', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Coming soon!', style: AppTextStyles.bodyMedium.subtle),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  blur: 20,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.65),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderColor: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.glassBorderDark
                      : AppColors.glassBorderLight,
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: PremiumShadows.primary,
                        ),
                        child: Center(
                          child: Text(
                            user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : '?',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.textOnPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Guest',
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user?.email ?? '',
                              style: AppTextStyles.bodyMedium.subtle,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user?.role.displayName ?? 'Pet Owner',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Menu items
                Text(
                  'Account',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  borderRadius: 20,
                  blur: 15,
                  padding: EdgeInsets.zero,
                  borderColor: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.glassBorderDark
                      : AppColors.glassBorderLight,
                  child: Column(
                    children: [
                      _LinkTile(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profile',
                        subtitle: 'Update your information',
                        onTap: () => _showComingSoon(context, 'Edit Profile'),
                      ),
                      const Divider(height: 1, indent: 56),
                      _LinkTile(
                        icon: Icons.lock_outlined,
                        title: 'Change Password',
                        subtitle: 'Update your password',
                        onTap: () => _showComingSoon(context, 'Change Password'),
                      ),
                      const Divider(height: 1, indent: 56),
                      _LinkTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notification Settings',
                        subtitle: 'Manage your preferences',
                        onTap: () => context.push(Routes.notifications),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Danger zone
                GlassContainer(
                  borderRadius: 20,
                  blur: 15,
                  padding: EdgeInsets.zero,
                  borderColor: AppColors.error.withValues(alpha: 0.3),
                  borderWidth: 2,
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout, color: AppColors.error, size: 22),
                    ),
                    title: Text(
                      'Sign Out',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    subtitle: Text(
                      'Sign out of your account',
                      style: AppTextStyles.bodySmall.subtle,
                    ),
                    onTap: () => _showSignOutDialog(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!'), behavior: SnackBarBehavior.floating),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          CpButton(
            text: 'Sign Out',
            variant: ButtonVariant.destructive,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            icon: Icons.logout,
          ),
        ],
      ),
    );
  }
}
