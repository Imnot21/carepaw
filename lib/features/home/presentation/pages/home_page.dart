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
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';

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

          final ownerId = authState.user.id!;

          return BlocProvider(
            create: (context) =>
                PetBloc(petRepository: context.read<PetRepository>())
                  ..add(LoadPets(ownerId: ownerId)),
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
    return const Center(child: NeuCircularProgress());
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        final userName = user?.fullName.split(' ').first ?? 'there';

        return BlocBuilder<PetBloc, PetState>(
          builder: (context, petState) {
            final pets = petState is PetsLoaded ? petState.pets : <Pet>[];
            final activePets = pets.where((p) => p.isActive).toList();

            return RefreshIndicator(
              onRefresh: () async {
                final state = context.read<AuthBloc>().state;
                if (state is AuthAuthenticated) {
                  context.read<PetBloc>().add(
                        LoadPets(ownerId: state.user.id!),
                      );
                }
              },
              child: CustomScrollView(
                slivers: [
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
                          'Good ${_getGreeting()}, $userName',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'How are your pets today?',
                          style: AppTextStyles.bodySmall.subtleOf(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _NotificationButton(),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PrimaryActionCard(),
                          const SizedBox(height: 28),
                          _PetSummarySection(pets: activePets),
                          const SizedBox(height: 28),
                          _UpcomingAppointmentsSection(),
                          const SizedBox(height: 28),
                          _QuickLinksSection(),
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
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () => context.push(Routes.notifications),
      tooltip: 'Notifications',
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NeuCard(
      onTap: () => context.push(Routes.appointmentRequest),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: ThemeColors.primary(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              color: ThemeColors.primary(context),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Appointment',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Schedule a visit with your vet',
                  style: AppTextStyles.bodySmall.subtleOf(
                    Theme.of(context).brightness,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: ThemeColors.textTertiary(context),
          ),
        ],
      ),
    );
  }
}

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
              'Your Pets',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => context.push(Routes.pets),
              child: Text(
                'View All',
                style: AppTextStyles.labelMedium.copyWith(
                  color: ThemeColors.primary(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 148,
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
    final speciesColor = AppColors.accentForSpecies(pet.species.displayName);
    final speciesIcon = _getSpeciesIcon(pet.species);

    return SizedBox(
      width: 132,
      child: NeuCard(
        onTap: () => context.push('/pets/${pet.id}'),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: NeuAvatar(
                radius: 26,
                icon: speciesIcon,
                backgroundColor: speciesColor.withValues(alpha: 0.15),
                foregroundColor: speciesColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              pet.name,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              pet.species.displayName,
              style: AppTextStyles.bodySmall.subtleOf(
                Theme.of(context).brightness,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
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
    if (years > 0) return '$years yr${years > 1 ? 's' : ''}';
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
            boxShadow: NeuShadow.color(
              context,
              AppColors.primary,
              blur: 24,
              opacity: 0.32,
            ),
            child: const Icon(
              Icons.pets_outlined,
              size: 48,
              color: AppColors.textOnPrimary,
            ),
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
            style: AppTextStyles.bodyMedium.subtleOf(
              Theme.of(context).brightness,
            ),
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
              'Upcoming',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => context.push(Routes.appointments),
              child: Text(
                'View All',
                style: AppTextStyles.labelMedium.copyWith(
                  color: ThemeColors.primary(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        NeuCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ThemeColors.primary(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.event_outlined,
                      color: ThemeColors.primary(context),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No upcoming appointments',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Book a visit with your vet',
                          style: AppTextStyles.bodySmall.subtleOf(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              NeuButton(
                text: 'Book Appointment',
                onPressed: () => context.push(Routes.appointmentRequest),
                variant: NeuButtonVariant.secondary,
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

class _QuickLinksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        NeuCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _LinkTile(
                icon: Icons.queue_outlined,
                title: 'Queue Status',
                subtitle: 'Check your place in line',
                onTap: () => context.push(Routes.queue),
              ),
              const Divider(height: 1, indent: 56),
              _LinkTile(
                icon: Icons.medical_services_outlined,
                title: 'Medical Records',
                subtitle: 'Health history & vaccinations',
                onTap: () => context.push(Routes.medicalRecords),
              ),
              const Divider(height: 1, indent: 56),
              _LinkTile(
                icon: Icons.vaccines_outlined,
                title: 'Vaccinations',
                subtitle: 'Track immunization schedule',
                onTap: () => context.push(Routes.medicalRecords),
              ),
            ],
          ),
        ),
      ],
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
          color: ThemeColors.primary(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: ThemeColors.primary(context), size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
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
