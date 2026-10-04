import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/app/theme/theme_colors.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_divider.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';

class VetDashboardPage extends StatefulWidget {
  const VetDashboardPage({super.key});

  @override
  State<VetDashboardPage> createState() => _VetDashboardPageState();
}

class _VetDashboardPageState extends State<VetDashboardPage> {
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
          final isVetOrAdmin =
              user.role == UserRole.veterinarian || user.role == UserRole.admin;

          if (!isVetOrAdmin) {
            return const _AccessDeniedView();
          }

          return _VetDashboardContent(user: user);
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
          const SizedBox(height: NeuTokens.spaceMd),
          Text(
            'Loading\u2026',
            style: AppTextStyles.bodyMedium.subtleOf(
              Theme.of(context).brightness,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NeuTokens.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuContainer(
              variant: NeuVariant.inset,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(NeuTokens.spaceLg),
              child: Icon(
                Icons.block_rounded,
                size: 48,
                color: ThemeColors.error(context),
              ),
            ),
            const SizedBox(height: NeuTokens.spaceLg),
            Text(
              'Access denied',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NeuTokens.spaceXs),
            Text(
              'This area is for veterinarians only.',
              style: AppTextStyles.bodyMedium.subtleOf(
                Theme.of(context).brightness,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NeuTokens.spaceMd),
            NeuButton(
              text: 'Go back',
              icon: Icons.arrow_back_rounded,
              variant: NeuButtonVariant.secondary,
              onPressed: () => context.pop(),
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _VetDashboardContent extends StatelessWidget {
  final dynamic user;

  const _VetDashboardContent({required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userName = user?.fullName?.split(' ')?.first ?? 'Doctor';

        return CustomScrollView(
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
                    'Good ${_getGreeting()}, Dr. $userName',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Veterinarian dashboard',
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
                  NeuTokens.spaceMd,
                  NeuTokens.pagePadding,
                  NeuTokens.spaceXl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _VetQuickActionsSection(),
                    SizedBox(height: NeuTokens.sectionGap),
                    const _VetQuickLinksSection(),
                  ],
                ),
              ),
            ),
          ],
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

// ─────────────────────────────────────────────────────────────────────────────

class _VetQuickActionsSection extends StatelessWidget {
  const _VetQuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clinical actions',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: NeuTokens.tightGap),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: NeuTokens.tightGap,
          mainAxisSpacing: NeuTokens.tightGap,
          childAspectRatio: 0.9,
          children: [
            _VetActionCard(
              icon: Icons.note_add_outlined,
              label: 'New\nvisit record',
              onTap: () => _showComingSoon(context, 'New visit record'),
            ),
            _VetActionCard(
              icon: Icons.medication_outlined,
              label: 'Prescribe\nmedication',
              onTap: () => _showComingSoon(context, 'Prescribe medication'),
            ),
            _VetActionCard(
              icon: Icons.vaccines_outlined,
              label: 'Add\nvaccination',
              onTap: () => _showComingSoon(context, 'Add vaccination'),
            ),
            _VetActionCard(
              icon: Icons.science_outlined,
              label: 'Order\nlab tests',
              onTap: () => _showComingSoon(context, 'Order lab tests'),
            ),
            _VetActionCard(
              icon: Icons.note_outlined,
              label: 'Clinical\nnotes',
              onTap: () => _showComingSoon(context, 'Clinical notes'),
            ),
            _VetActionCard(
              icon: Icons.attach_file_outlined,
              label: 'Attach\nresults',
              onTap: () => _showComingSoon(context, 'Attach results'),
            ),
            _VetActionCard(
              icon: Icons.history_outlined,
              label: 'Patient\nhistory',
              onTap: () => context.push(Routes.vetPatients),
            ),
            _VetActionCard(
              icon: Icons.print_outlined,
              label: 'Generate\nsummary',
              onTap: () => _showComingSoon(context, 'Generate summary'),
            ),
          ],
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    NeuToast.info(context, '$feature coming soon');
  }
}

class _VetActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _VetActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColors.primary(context);
    return NeuCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          NeuContainer(
            variant: NeuVariant.pressed,
            borderRadius: NeuTokens.radiusSm,
            padding: const EdgeInsets.all(NeuTokens.spaceXs),
            child: Icon(icon, color: accent, size: NeuTokens.iconLg - 4),
          ),
          const SizedBox(height: NeuTokens.spaceXs),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: accent,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _VetQuickLinksSection extends StatelessWidget {
  const _VetQuickLinksSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: NeuTokens.tightGap),
        NeuCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _LinkTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Lab results & alerts',
                onTap: () => context.push(Routes.notifications),
              ),
              NeuDivider(indent: 56),
              _LinkTile(
                icon: Icons.medical_services_outlined,
                title: 'Medical records',
                subtitle: 'Full patient history access',
                onTap: () => context.push(Routes.medicalRecords),
              ),
              NeuDivider(indent: 56),
              _LinkTile(
                icon: Icons.inventory_2_outlined,
                title: 'Medicine catalog',
                subtitle: 'Available medications & dosages',
                onTap: () => _showComingSoon(context, 'Medicine catalog'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    NeuToast.info(context, '$feature coming soon');
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
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.subtleOf(
                      Theme.of(context).brightness,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ThemeColors.textTertiary(context)),
          ],
        ),
      ),
    );
  }
}
