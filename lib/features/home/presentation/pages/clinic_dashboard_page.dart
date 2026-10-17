import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
import 'package:carepaw/core/widgets/neomorphism/neu_stat.dart';
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
              child: const _ClinicPulseStrip(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                NeuTokens.pagePadding,
                NeuTokens.spaceLg,
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
                  BlocBuilder<ClinicPulseBloc, ClinicPulseState>(
                    builder: (context, pulse) => GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: NeuTokens.tightGap,
                      mainAxisSpacing: NeuTokens.tightGap,
                      childAspectRatio: 0.95,
                      children: [
                        _ClinicActionCard(
                          svgAsset: SvgIcons.calendar,
                          label: 'Bookings',
                          onTap: () => context.push(Routes.staffAppointments),
                        ),
                        _ClinicActionCard(
                          svgAsset: SvgIcons.listNumbered,
                          label: 'Line',
                          onTap: () => context.push(Routes.staffQueue),
                        ),
                        _ClinicActionCard(
                          svgAsset: SvgIcons.people,
                          label: 'Patients',
                          onTap: () => context.push(Routes.vetPatients),
                        ),
                        _ClinicActionCard(
                          svgAsset: SvgIcons.visit,
                          label: 'Records',
                          onTap: () => _openRecordsPicker(context),
                        ),
                        _ClinicActionCard(
                          svgAsset: SvgIcons.inventory,
                          label: 'Stock',
                          alert: (pulse.lowStock ?? 0) > 0,
                          onTap: () => context.push(Routes.staffInventory),
                        ),
                        _ClinicActionCard(
                          svgAsset: SvgIcons.scan,
                          label: 'Scan',
                          onTap: () => context.push(Routes.staffScanning),
                        ),
                      ],
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

  Future<void> _handleRefresh(BuildContext context) async {
    final bloc = context.read<ClinicPulseBloc>();
    final targetRevision = bloc.state.revision + 1;
    bloc.add(const ClinicPulseRefreshRequested());
    if (bloc.state.revision >= targetRevision) return;
    // Hold the spinner until the reload this pull started lands.
    await bloc.stream.firstWhere((s) => s.revision >= targetRevision);
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
        return NeuStatGrid(
          mobileColumns: 3,
          // "Today's bookings" wraps to two lines in a third of the width;
          // 0.70 keeps the two-line label clear even at the narrower logical
          // width of a framed preview (~393pt).
          childAspectRatio: 0.70,
          tiles: [
            NeuStatTile(
              label: 'Waiting',
              value: waiting?.toString() ?? '-',
              icon: Icons.people_outline_rounded,
              svgAsset: SvgIcons.person,
              accent: (waiting ?? 0) > 0 ? ThemeColors.warning(context) : null,
              onTap: () => context.push(Routes.staffQueue),
            ),
            NeuStatTile(
              label: "Today's bookings",
              value: pulse.todayBookings?.toString() ?? '-',
              icon: Icons.event_available_outlined,
              svgAsset: SvgIcons.calendar,
              onTap: () => context.push(Routes.staffAppointments),
            ),
            NeuStatTile(
              label: 'Low stock',
              value: lowStock?.toString() ?? '-',
              icon: Icons.inventory_2_outlined,
              svgAsset: SvgIcons.inventory,
              accent: (lowStock ?? 0) > 0 ? ThemeColors.error(context) : null,
              onTap: () => context.push(Routes.staffInventory),
            ),
          ],
        );
      },
    );
  }
}

class _ClinicActionCard extends StatelessWidget {
  final String? svgAsset;
  final String label;
  final VoidCallback onTap;

  /// Marks the tile with an accent dot — something in this area needs
  /// attention (e.g. low stock).
  final bool alert;

  const _ClinicActionCard({
    this.svgAsset,
    required this.label,
    required this.onTap,
    this.alert = false,
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              NeuContainer(
                variant: NeuVariant.pressed,
                borderRadius: NeuTokens.radiusSm,
                padding: const EdgeInsets.all(NeuTokens.spaceXs),
                child: svgAsset != null
                    ? NeuSvgIcon(svgAsset!, size: NeuTokens.iconLg - 4)
                    : const SizedBox(
                        width: NeuTokens.iconLg - 4,
                        height: NeuTokens.iconLg - 4,
                      ),
              ),
              if (alert)
                Positioned(
                  top: -1,
                  right: -1,
                  child: ExcludeSemantics(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: ThemeColors.error(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ThemeColors.background(context),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
