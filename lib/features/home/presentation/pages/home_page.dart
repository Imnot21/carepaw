import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';

/// Home page for pet owners - main dashboard content only.
///
/// The bottom navigation is provided by [AppShell] via [NeuBottomNav].
/// This page renders the home tab content; other tabs (Pets, Appointments,
/// Queue, Profile) are separate routes/pages.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
            child: const _HomeContent(),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const NeuCircularProgress(),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: AppTextStyles.bodyMedium.subtleOf(Theme.of(context).brightness),
          ),
        ],
      ),
    );
  }
}

/// Home content with quick actions, pet summary, recent activity
class _HomeContent extends StatelessWidget {
  const _HomeContent();

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
                          style: AppTextStyles.bodySmall.subtleOf(Theme.of(context).brightness),
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

/// Quick action buttons section
class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = ThemeColors.primary(context);
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
              icon: Icons.pets_outlined,
              label: 'Add Pet',
              color: accent,
              onTap: () => context.push(Routes.petAdd),
            ),
            _QuickActionCard(
              icon: Icons.event_available_outlined,
              label: 'Book\nAppointment',
              color: accent,
              onTap: () => context.push(Routes.appointmentRequest),
            ),
            _QuickActionCard(
              icon: Icons.queue_outlined,
              label: 'Check\nQueue',
              color: accent,
              onTap: () => context.push(Routes.queue),
            ),
            _QuickActionCard(
              icon: Icons.medical_services_outlined,
              label: 'Medical\nRecords',
              color: accent,
              onTap: () => context.push(Routes.medicalRecords),
            ),
            _QuickActionCard(
              icon: Icons.vaccines_outlined,
              label: 'Vaccination\nSchedule',
              color: accent,
              onTap: () => _showComingSoon(context, 'Vaccination Schedule'),
            ),
            _QuickActionCard(
              icon: Icons.local_pharmacy_outlined,
              label: 'Prescriptions',
              color: accent,
              onTap: () => _showComingSoon(context, 'Prescriptions'),
            ),
            _QuickActionCard(
              icon: Icons.receipt_long_outlined,
              label: 'Scan\nReceipt',
              color: accent,
              onTap: () => _showComingSoon(context, 'Scan Receipt'),
            ),
            _QuickActionCard(
              icon: Icons.chat_bubble_outline,
              label: 'Chat with\nVet',
              color: accent,
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
    return NeuCard(
      onTap: onTap,
      borderRadius: 16,
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

    return NeuCard(
      onTap: () => context.push('/pets/${pet.id}'),
      borderRadius: 16,
      padding: EdgeInsets.zero,
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
                        style: AppTextStyles.bodySmall.subtleOf(Theme.of(context).brightness),
                      ),
                    ],
                  ),
                  if (pet.birthDate != null)
                    Text(
                      _formatAge(pet.birthDate!),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: ThemeColors.primary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
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
        return AppColors.accentReptile;
      case PetSpecies.other:
        return AppColors.accentDefault;
    }
  }
}

class _EmptyPetsPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          NeuContainer(
            borderRadius: 90,
            padding: const EdgeInsets.all(20),
            color: AppColors.primary,
            boxShadow: NeuShadow.color(context, AppColors.primary, blur: 24, opacity: 0.32),
            child: const Icon(Icons.pets_outlined, size: 48, color: AppColors.textOnPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            'No pets yet',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your first pet to get started',
            style: AppTextStyles.bodyMedium.subtleOf(Theme.of(context).brightness),
          ),
          const SizedBox(height: 16),
          NeuButton(
            text: 'Add Pet',
            onPressed: () => context.push(Routes.petAdd),
            variant: NeuButtonVariant.primary,
            icon: Icons.add,
            expanded: true,
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
        NeuCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              NeuContainer(
                borderRadius: 90,
                padding: const EdgeInsets.all(20),
                color: AppColors.primary,
                boxShadow: NeuShadow.color(context, AppColors.primary, blur: 24, opacity: 0.32),
                child: const Icon(Icons.calendar_month_outlined, size: 48, color: AppColors.textOnPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'No upcoming appointments',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Book an appointment with your vet',
                style: AppTextStyles.bodyMedium.subtleOf(Theme.of(context).brightness),
              ),
              const SizedBox(height: 16),
              NeuButton(
                text: 'Book Appointment',
                onPressed: () => context.push(Routes.appointmentRequest),
                variant: NeuButtonVariant.primary,
                icon: Icons.add,
                expanded: true,
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
        NeuCard(
          borderRadius: 20,
          padding: EdgeInsets.zero,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: NeuContainer(
        borderRadius: 12,
        padding: const EdgeInsets.all(8),
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.16)
            : AppColors.primaryTint,
        child: Icon(icon, color: ThemeColors.primary(context), size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.subtleOf(Theme.of(context).brightness),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: ThemeColors.textTertiary(context),
      ),
      onTap: onTap,
    );
  }
}
