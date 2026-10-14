import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';

/// Home screen for the Owner/Admin — the paper-aligned single clinic
/// operator (DocMyk's PILA VET HUB). Combines bookings, line, patients,
/// stock, and scanning entry points in one place.
class ClinicDashboardPage extends StatelessWidget {
  const ClinicDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: NeuCircularProgress());
        }
        final user = authState.user;
        if (!user.isOwnerAdmin) {
          return const _AccessDeniedView();
        }
        return _ClinicDashboardContent(user: user);
      },
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
              'This area is for the clinic Owner/Admin only.',
              style: AppTextStyles.bodyMedium.subtleOf(
                Theme.of(context).brightness,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClinicDashboardContent extends StatelessWidget {
  final User user;

  const _ClinicDashboardContent({required this.user});

  @override
  Widget build(BuildContext context) {
    final userName = user.fullName
        .split(' ')
        .firstWhere((w) => w.isNotEmpty, orElse: () => 'Doc');

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
                'Good ${_getGreeting()}, $userName',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Clinic overview • Owner/Admin',
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
                Text(
                  'Clinic work',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: NeuTokens.tightGap),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: NeuTokens.tightGap,
                  mainAxisSpacing: NeuTokens.tightGap,
                  childAspectRatio: 0.95,
                  children: [
                    _ClinicActionCard(
                      icon: Icons.calendar_month_outlined,
                      label: 'Bookings',
                      onTap: () => context.push(Routes.staffAppointments),
                    ),
                    _ClinicActionCard(
                      icon: Icons.format_list_numbered_outlined,
                      label: 'Line',
                      onTap: () => context.push(Routes.staffQueue),
                    ),
                    _ClinicActionCard(
                      icon: Icons.people_outline_rounded,
                      label: 'Patients',
                      onTap: () => context.push(Routes.vetPatients),
                    ),
                    _ClinicActionCard(
                      icon: Icons.medical_services_outlined,
                      label: 'Records',
                      onTap: () => context.push(Routes.vetPatients),
                    ),
                    _ClinicActionCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Stock',
                      onTap: () => context.push(Routes.staffInventory),
                    ),
                    _ClinicActionCard(
                      icon: Icons.document_scanner_outlined,
                      label: 'Scan',
                      onTap: () => context.push(Routes.staffScanning),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _ClinicActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ClinicActionCard({
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
