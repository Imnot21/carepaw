import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/home/presentation/bloc/clinic_pulse_bloc.dart';
import 'package:carepaw/features/home/presentation/bloc/clinic_pulse_event.dart';
import 'package:carepaw/features/home/presentation/bloc/clinic_pulse_state.dart';
import 'package:carepaw/features/home/presentation/widgets/patient_picker_sheet.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';

/// Home screen for the Owner/Admin — the paper-aligned single clinic
/// operator (DocMyk's PILA VET HUB). Opens with the clinic pulse (waiting
/// line, today's bookings, low stock) and combines bookings, line, patients,
/// records, stock, and scanning entry points below it.
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
              child: NeuSvgIcon(SvgIcons.block, size: 48),
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

    return RefreshIndicator(
      onRefresh: () => _handleRefresh(context),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            toolbarHeight: MediaQuery.textScalerOf(
              context,
            ).scale(56).clamp(64.0, 120.0),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: NeuTokens.pagePadding,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_getGreeting().toLowerCase()}, $userName',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${DateFormat('EEEE, MMMM d').format(DateTime.now())} · PILA VET HUB',
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
                plain: true,
                icon: Icons.notifications_none_rounded,
                svgAsset: SvgIcons.notifications,
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
                0,
              ),
              child: const _CappedWidth(child: _ClinicPulseStrip()),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                NeuTokens.pagePadding,
                NeuTokens.sectionGap,
                NeuTokens.pagePadding,
                NeuTokens.spaceXl,
              ),
              child: _CappedWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bookings, line, patients, stock and scan already sit in
                    // the tab bar one thumb away; repeating them here as a tile
                    // grid only doubled the navigation. This list holds what
                    // the tab bar does not.
                    Text(
                      'More',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: NeuTokens.spaceXs),
                    NeuCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _ClinicLinkRow(
                            svgAsset: SvgIcons.visit,
                            title: 'Medical records',
                            subtitle: 'Pick a patient to open their history',
                            onTap: () => _openRecordsPicker(context),
                          ),
                          Divider(
                            height: 1,
                            indent: 60,
                            color: ThemeColors.divider(context),
                          ),
                          // Chapter 1 (Figure 1): the Owner/Veterinarian and
                          // the Co-Manager share the Owner/Admin role. The
                          // Owner creates the Co-Manager's account here.
                          _ClinicLinkRow(
                            svgAsset: SvgIcons.person,
                            title: 'Staff accounts',
                            subtitle: "Add or turn off the co-manager's login",
                            onTap: () => context.push(Routes.adminUsers),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh(BuildContext context) async {
    final bloc = context.read<ClinicPulseBloc>();
    final targetRevision = bloc.state.revision + 1;
    bloc.add(const ClinicPulseRefreshRequested());
    if (bloc.state.revision >= targetRevision) return;
    // Hold the spinner until the reload this pull started lands.
    try {
      await bloc.stream
          .firstWhere((s) => s.revision >= targetRevision)
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      // Stop the spinner; the cells keep their last known values.
    }
  }

  Future<void> _openRecordsPicker(BuildContext context) async {
    final petId = await showPatientPicker(context);
    if (petId == null || !context.mounted) return;
    // Records live per pet — the same destination the patient card opens.
    context.push('${Routes.medicalRecords}?petId=$petId');
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

/// The clinic's state at a glance — the first thing the operator reads.
///
/// Each cell opens the surface that owns its number; unknown values render
/// as a dash rather than a fake zero.
class _ClinicPulseStrip extends StatelessWidget {
  const _ClinicPulseStrip();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClinicPulseBloc, ClinicPulseState>(
      builder: (context, pulse) {
        final waiting = pulse.waiting;
        final lowStock = pulse.lowStock;
        Widget rule() =>
            Container(width: 1, color: ThemeColors.divider(context));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: NeuTokens.spaceXs),
            NeuCard(
              padding: const EdgeInsets.symmetric(
                vertical: NeuTokens.spaceMd,
                horizontal: NeuTokens.spaceXs,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PulseCell(
                      value: waiting,
                      label: 'in line',
                      alert: (waiting ?? 0) > 0
                          ? ThemeColors.warning(context)
                          : null,
                      onTap: () => context.push(Routes.staffQueue),
                    ),
                    rule(),
                    _PulseCell(
                      value: pulse.todayBookings,
                      label: 'booked today',
                      onTap: () => context.push(Routes.staffAppointments),
                    ),
                    rule(),
                    _PulseCell(
                      value: lowStock,
                      label: 'low on stock',
                      alert: (lowStock ?? 0) > 0
                          ? ThemeColors.error(context)
                          : null,
                      onTap: () => context.push(Routes.staffInventory),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One number on the Today panel. Unknown values show a dash, never a fake 0.
class _PulseCell extends StatelessWidget {
  final int? value;
  final String label;
  final Color? alert;
  final VoidCallback onTap;

  const _PulseCell({
    required this.value,
    required this.label,
    required this.onTap,
    this.alert,
  });

  @override
  Widget build(BuildContext context) {
    final shown = value?.toString() ?? '–';
    return Expanded(
      child: Semantics(
        button: true,
        label: value == null ? 'Unavailable, $label' : '$shown $label',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NeuTokens.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: NeuTokens.spaceXxs),
            child: Column(
              children: [
                Text(
                  shown,
                  style: AppTextStyles.numberLarge.copyWith(
                    color: alert ?? ThemeColors.textPrimary(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.subtleOf(
                    Theme.of(context).brightness,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row in the "More" list: small icon, what it is, what you do there.
class _ClinicLinkRow extends StatelessWidget {
  final String svgAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ClinicLinkRow({
    required this.svgAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: NeuTokens.spaceMd,
            vertical: NeuTokens.spaceSm,
          ),
          child: Row(
            children: [
              NeuSvgIcon(svgAsset, size: 28),
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
              const NeuSvgIcon(SvgIcons.chevronRight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps a scroll body readable on wide screens.
class _CappedWidth extends StatelessWidget {
  final Widget child;

  const _CappedWidth({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: NeuTokens.maxContentWidth),
        child: child,
      ),
    );
  }
}
