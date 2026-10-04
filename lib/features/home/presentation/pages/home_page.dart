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
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/app/theme/theme_colors.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_medallion.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_section.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';

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
                    titleSpacing: NeuTokens.pagePadding,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${_getGreeting()}, $userName',
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontWeight: FontWeight.w800,
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
                      NeuIconButton(
                        icon: Icons.notifications_none_rounded,
                        tooltip: 'Notifications',
                        onPressed: () => context.push(Routes.notifications),
                      ),
                      const SizedBox(width: NeuTokens.spaceXs),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        NeuTokens.pagePadding,
                        NeuTokens.spaceXs,
                        NeuTokens.pagePadding,
                        NeuTokens.spaceXl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PrimaryActionCard(),
                          const SizedBox(height: NeuTokens.sectionGap),
                          _PetSummarySection(pets: activePets),
                          const SizedBox(height: NeuTokens.sectionGap),
                          _UpcomingAppointmentsSection(),
                          const SizedBox(height: NeuTokens.sectionGap),
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

class _PrimaryActionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NeuCard(
      onTap: () => context.push(Routes.appointmentRequest),
      child: Row(
        children: [
          NeuContainer(
            variant: NeuVariant.pressed,
            borderRadius: NeuTokens.radiusSm,
            padding: const EdgeInsets.all(NeuTokens.spaceSm),
            child: Icon(
              Icons.calendar_month_outlined,
              color: ThemeColors.primary(context),
              size: NeuTokens.iconLg - 6,
            ),
          ),
          const SizedBox(width: NeuTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book appointment',
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
      return const _EmptyPetsPrompt();
    }

    return NeuSection(
      title: 'Your pets',
      actionLabel: pets.length > 5 ? 'View all' : null,
      onAction: pets.length > 5 ? () => context.push(Routes.pets) : null,
      child: SizedBox(
        height: 152,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: pets.length > 5 ? 5 : pets.length,
          separatorBuilder: (_, __) =>
              const SizedBox(width: NeuTokens.tightGap),
          itemBuilder: (context, index) {
            final pet = pets[index];
            return _PetSummaryCard(pet: pet);
          },
        ),
      ),
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
      width: 134,
      child: NeuCard(
        onTap: () => context.push('/pets/${pet.id}'),
        padding: const EdgeInsets.all(NeuTokens.spaceSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child:           CircleAvatar(
                radius: NeuTokens.spaceXl - 4,
                backgroundColor: speciesColor.withValues(alpha: 0.12),
                child: Icon(speciesIcon, color: speciesColor, size: 26),
              ),
            ),
            const SizedBox(height: NeuTokens.spaceXs),
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

  Color colorMix(Color c, BuildContext context, {required double light}) {
    return c.withValues(alpha: light);
  }
}

class _EmptyPetsPrompt extends StatelessWidget {
  const _EmptyPetsPrompt();

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(NeuTokens.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NeuMedallion(
            radius: 56,
            color: ThemeColors.primary(context),
            child: Icon(Icons.pets_outlined, size: 48, color: ThemeColors.primary(context)),
          ),
          const SizedBox(height: NeuTokens.spaceMd),
          Text(
            'No pets yet',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: NeuTokens.spaceXxs),
          Text(
            'Add your first pet to get started',
            style: AppTextStyles.bodyMedium.subtleOf(
              Theme.of(context).brightness,
            ),
          ),
          const SizedBox(height: NeuTokens.spaceMd),
          NeuButton(
            text: 'Add pet',
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
    return NeuSection(
      title: 'Upcoming',
      actionLabel: 'View all',
      onAction: () => context.push(Routes.appointments),
      child: NeuCard(
        child: Column(
          children: [
            Row(
              children: [
                NeuContainer(
                  variant: NeuVariant.pressed,
                  borderRadius: NeuTokens.radiusSm,
                  padding: const EdgeInsets.all(NeuTokens.spaceXs),
                  child: Icon(
                    Icons.event_outlined,
                    color: ThemeColors.primary(context),
                    size: 22,
                  ),
                ),
                const SizedBox(width: NeuTokens.tightGap),
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
            const SizedBox(height: NeuTokens.spaceMd),
            NeuButton(
              text: 'Book appointment',
              onPressed: () => context.push(Routes.appointmentRequest),
              variant: NeuButtonVariant.secondary,
              icon: Icons.add,
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NeuSection(
      title: 'Quick actions',
      child: NeuCard(padding: EdgeInsets.zero, child: _QuickLinksList()),
    );
  }
}

class _QuickLinksList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LinkTile(
          icon: Icons.format_list_numbered_outlined,
          title: 'Queue status',
          subtitle: 'Check your place in line',
          onTap: () => context.push(Routes.queue),
        ),
        Divider(
          height: 1,
          thickness: 1,
          indent: 56,
          color: ThemeColors.divider(context),
        ),
        _LinkTile(
          icon: Icons.medical_services_outlined,
          title: 'Medical records',
          subtitle: 'Health history & vaccinations',
          onTap: () => context.push(Routes.medicalRecords),
        ),
        Divider(
          height: 1,
          thickness: 1,
          indent: 56,
          color: ThemeColors.divider(context),
        ),
        _LinkTile(
          icon: Icons.vaccines_outlined,
          title: 'Vaccinations',
          subtitle: 'Track immunization schedule',
          onTap: () => context.push(Routes.medicalRecords),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NeuTokens.spaceMd,
          vertical: NeuTokens.spaceSm + 2,
        ),
        child: Row(
          children: [
            NeuContainer(
              variant: NeuVariant.pressed,
              borderRadius: NeuTokens.radiusSm,
              padding: const EdgeInsets.all(NeuTokens.spaceXs),
              child: Icon(
                icon,
                color: ThemeColors.primary(context),
                size: NeuTokens.iconSm,
              ),
            ),
            const SizedBox(width: NeuTokens.tightGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.subtleOf(
                      Theme.of(context).brightness,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: NeuTokens.iconSm + 2,
              color: ThemeColors.textTertiary(context),
            ),
          ],
        ),
      ),
    );
  }
}
