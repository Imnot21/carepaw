import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_section.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';

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
            final toolbarHeight = MediaQuery.textScalerOf(
              context,
            ).scale(60).clamp(64.0, 120.0);

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
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    toolbarHeight: toolbarHeight,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'PILA VET HUB · Pila, Laguna',
                          style: AppTextStyles.bodySmall.subtleOf(
                            Theme.of(context).brightness,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    actions: [
                      NeuIconButton(
                        icon: Icons.notifications_none_rounded,
                        svgAsset: SvgIcons.notifications,
                        tooltip: 'Notifications',
                        onPressed: () => context.push(Routes.notifications),
                        plain: true,
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
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: NeuTokens.maxContentWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PrimaryActionCard(),
                              _PetSummarySection(
                                pets: activePets,
                                state: petState,
                              ),
                              _UpcomingAppointmentsSection(),
                              _QuickLinksSection(),
                            ],
                          ),
                        ),
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

/// The one filled-accent surface on the owner's home: booking is the job
/// most people open the app for.
class _PrimaryActionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ink = ThemeColors.onPrimary(context);
    return Semantics(
      button: true,
      label: 'Book a visit',
      excludeSemantics: true,
      child: NeuContainer(
        onTap: () => context.push(Routes.appointmentRequest),
        color: ThemeColors.primary(context),
        borderRadius: NeuTokens.radiusMd,
        padding: const EdgeInsets.fromLTRB(
          NeuTokens.cardPadding,
          NeuTokens.spaceMd,
          NeuTokens.spaceMd,
          NeuTokens.spaceMd,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book a visit',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pick a pet, a service and a time',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ink.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: ink),
          ],
        ),
      ),
    );
  }
}

class _PetSummarySection extends StatelessWidget {
  final List<Pet> pets;
  final PetState state;

  const _PetSummarySection({required this.pets, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is PetError) {
      return const Padding(
        padding: EdgeInsets.only(top: NeuTokens.sectionGap),
        child: _PetsLoadError(),
      );
    }
    if (state is! PetsLoaded) {
      return const Padding(
        padding: EdgeInsets.only(top: NeuTokens.sectionGap),
        child: NeuShimmer(child: NeuSkeletonBox(height: 76, borderRadius: 16)),
      );
    }
    if (pets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: NeuTokens.sectionGap),
        child: _EmptyPetsPrompt(),
      );
    }

    return NeuSection(
      title: 'Your pets',
      actionLabel: pets.length > 5 ? 'View all' : null,
      onAction: pets.length > 5 ? () => context.push(Routes.pets) : null,
      child: SizedBox(
        height: MediaQuery.textScalerOf(context).scale(76),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: pets.length > 5 ? 5 : pets.length,
          separatorBuilder: (_, _) => const SizedBox(width: NeuTokens.tightGap),
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
    final speciesSvg = PetUtils.getSpeciesSvg(pet.species);

    final details = [
      pet.species.displayName,
      if (pet.birthDate != null) _formatAge(pet.birthDate!),
    ].join(' · ');

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 168, maxWidth: 220),
      child: NeuCard(
        onTap: () => context.push('/pets/${pet.id}'),
        padding: const EdgeInsets.symmetric(
          horizontal: NeuTokens.spaceSm,
          vertical: NeuTokens.spaceXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: speciesColor.withValues(alpha: 0.12),
              child: NeuSvgIcon(speciesSvg, size: 26),
            ),
            const SizedBox(width: NeuTokens.spaceSm),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    details,
                    style: AppTextStyles.bodySmall.subtleOf(
                      Theme.of(context).brightness,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
}

class _PetsLoadError extends StatelessWidget {
  const _PetsLoadError();

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(NeuTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Could not load your pets',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: NeuTokens.spaceXxs),
          Text(
            'Check your connection and try again.',
            style: AppTextStyles.bodyMedium.subtleOf(
              Theme.of(context).brightness,
            ),
          ),
          const SizedBox(height: NeuTokens.spaceMd),
          NeuButton(
            text: 'Try again',
            variant: NeuButtonVariant.secondary,
            expanded: true,
            onPressed: () {
              final auth = context.read<AuthBloc>().state;
              if (auth is AuthAuthenticated) {
                context.read<PetBloc>().add(LoadPets(ownerId: auth.user.id!));
              }
            },
          ),
        ],
      ),
    );
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
          NeuContainer(
            variant: NeuVariant.inset,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(NeuTokens.spaceLg),
            child: const NeuSvgIcon(SvgIcons.paw, size: 30),
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
            'Add your pet so the clinic can book and keep their records.',
            style: AppTextStyles.bodyMedium.subtleOf(
              Theme.of(context).brightness,
            ),
          ),
          const SizedBox(height: NeuTokens.spaceMd),
          NeuButton(
            text: 'Add a pet',
            onPressed: () => context.push(Routes.petAdd),
            variant: NeuButtonVariant.primary,
            icon: Icons.add,
            svgAsset: SvgIcons.add,
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
      actionLabel: 'See all',
      onAction: () => context.push(Routes.appointments),
      child: NeuCard(
        child: Row(
          children: [
            const NeuSvgIcon(SvgIcons.calendar, size: 28),
            const SizedBox(width: NeuTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your appointments',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'See your upcoming and past visits and their status.',
                    style: AppTextStyles.bodySmall.subtleOf(
                      Theme.of(context).brightness,
                    ),
                  ),
                ],
              ),
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
      title: 'Records',
      child: NeuCard(padding: EdgeInsets.zero, child: _QuickLinksList()),
    );
  }
}

class _QuickLinksList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _LinkTile(
      svgAsset: SvgIcons.visit,
      title: 'Health records',
      subtitle: 'Visits, vaccines and medicines, per pet',
      // Records need a pet (?petId=); send the owner to pick one —
      // the pet detail screen links straight to its records.
      onTap: () => context.push(Routes.pets),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String? svgAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkTile({
    this.svgAsset,
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
            svgAsset != null
                ? NeuSvgIcon(svgAsset!, size: 28)
                : const SizedBox(width: 28, height: 28),
            const SizedBox(width: NeuTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
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
            NeuSvgIcon(SvgIcons.chevronRight, size: NeuTokens.iconSm + 2),
          ],
        ),
      ),
    );
  }
}
