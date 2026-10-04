import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_bloc.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_event.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_state.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/app/theme/theme_colors.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_divider.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';

class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
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
          final isStaffOrAdmin =
              user.role == UserRole.staff || user.role == UserRole.admin;

          if (!isStaffOrAdmin) {
            return const _AccessDeniedView();
          }

          return _StaffDashboardContent(user: user);
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
              'This area is for clinic staff only.',
              style: AppTextStyles.bodyMedium.subtleOf(
                Theme.of(context).brightness,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NeuTokens.spaceMd),
            NeuContainer(
              variant: NeuVariant.pressed,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: NeuTokens.spaceLg,
                vertical: NeuTokens.spaceSm,
              ),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  'Go back',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: ThemeColors.textPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StaffDashboardContent extends StatelessWidget {
  final dynamic user;

  const _StaffDashboardContent({required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QueueBloc(
        repository: context.read(),
        authBloc: context.read<AuthBloc>(),
      )..add(const QueueStaffLoadRequested()),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final userName = user?.fullName?.split(' ')?.first ?? 'Staff';

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
                      'Staff dashboard \u2022 ${user?.role?.displayName ?? 'Staff'}',
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
                      const _StaffQuickStatsSection(),
                      SizedBox(height: NeuTokens.sectionGap),
                      const _StaffQuickActionsSection(),
                      SizedBox(height: NeuTokens.sectionGap),
                      const _StaffQueuePreviewSection(),
                      SizedBox(height: NeuTokens.sectionGap),
                      const _StaffQuickLinksSection(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
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

class _StaffQuickStatsSection extends StatelessWidget {
  const _StaffQuickStatsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QueueBloc, QueueState>(
      builder: (context, state) {
        int waiting = 0;
        int inRoom = 0;
        int currentServing = 0;

        if (state is QueueStaffLoaded) {
          waiting = state.totalWaiting;
          inRoom = state.totalInRoom;
          currentServing = state.currentServing;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\u2019s overview',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: NeuTokens.tightGap),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Waiting',
                    value: '$waiting',
                    icon: Icons.schedule_outlined,
                    color: ThemeColors.warning(context),
                    trend: 'pets',
                  ),
                ),
                const SizedBox(width: NeuTokens.tightGap),
                Expanded(
                  child: _StatCard(
                    label: 'In room',
                    value: '$inRoom',
                    icon: Icons.door_front_door_outlined,
                    color: ThemeColors.primary(context),
                    trend: 'active',
                  ),
                ),
                const SizedBox(width: NeuTokens.tightGap),
                Expanded(
                  child: _StatCard(
                    label: 'Now serving',
                    value: currentServing > 0 ? '#$currentServing' : '\u2014',
                    icon: Icons.person_outline,
                    color: ThemeColors.success(context),
                    trend: 'next',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuContainer(
                variant: NeuVariant.pressed,
                borderRadius: NeuTokens.radiusSm,
                padding: const EdgeInsets.all(NeuTokens.spaceXs),
                child: Icon(icon, color: color, size: NeuTokens.iconSm),
              ),
              const Spacer(),
              Text(
                trend,
                style: AppTextStyles.bodySmall.mutedOf(
                  Theme.of(context).brightness,
                ),
              ),
            ],
          ),
          const SizedBox(height: NeuTokens.tightGap),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.subtleOf(
              Theme.of(context).brightness,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StaffQuickActionsSection extends StatelessWidget {
  const _StaffQuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick actions',
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
            _StaffActionCard(
              icon: Icons.queue_outlined,
              label: 'Manage\nqueue',
              onTap: () => context.push(Routes.staffQueue),
            ),
            _StaffActionCard(
              icon: Icons.calendar_month_outlined,
              label: 'View\nappointments',
              onTap: () => context.push(Routes.staffAppointments),
            ),
            _StaffActionCard(
              icon: Icons.inventory_2_outlined,
              label: 'Check\ninventory',
              onTap: () => context.push(Routes.staffInventory),
            ),
            _StaffActionCard(
              icon: Icons.scanner_outlined,
              label: 'Scan\nmedicine',
              onTap: () => context.push(Routes.staffScanning),
            ),
            _StaffActionCard(
              icon: Icons.add_circle_outline,
              label: 'Add\nappointment',
              onTap: () => context.push(Routes.staffAppointments),
            ),
            _StaffActionCard(
              icon: Icons.assignment_outlined,
              label: 'Daily\nreport',
              onTap: () => _showComingSoon(context, 'Daily report'),
            ),
            _StaffActionCard(
              icon: Icons.people_outlined,
              label: 'Walk-in\ncheck-in',
              onTap: () => _showComingSoon(context, 'Walk-in check-in'),
            ),
            _StaffActionCard(
              icon: Icons.print_outlined,
              label: 'Print\nqueue',
              onTap: () => _showComingSoon(context, 'Print queue'),
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

class _StaffActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _StaffActionCard({
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

class _StaffQueuePreviewSection extends StatelessWidget {
  const _StaffQueuePreviewSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QueueBloc, QueueState>(
      builder: (context, state) {
        if (state is! QueueStaffLoaded || state.queueEntries.isEmpty) {
          return const _EmptyQueuePreview();
        }

        final waitingEntries =
            state.queueEntries
                .where(
                  (e) =>
                      e.queueEntry.status == QueueStatus.waiting ||
                      e.queueEntry.status == QueueStatus.called,
                )
                .toList()
              ..sort(
                (a, b) => QueueEntry.byQueueOrder(a.queueEntry, b.queueEntry),
              );

        final inRoomEntries =
            state.queueEntries
                .where((e) => e.queueEntry.status == QueueStatus.inRoom)
                .toList()
              ..sort(
                (a, b) => QueueEntry.byQueueOrder(a.queueEntry, b.queueEntry),
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live queue',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(Routes.staffQueue),
                  behavior: HitTestBehavior.opaque,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: NeuTokens.minTapTarget,
                    ),
                    child: Center(
                      child: Text(
                        'View all',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: ThemeColors.primary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: NeuTokens.tightGap),
            if (waitingEntries.isNotEmpty) ...[
              Text(
                'Waiting / called',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.warning(context),
                ),
              ),
              const SizedBox(height: NeuTokens.spaceXs),
              for (final entry in waitingEntries.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: NeuTokens.spaceXs),
                  child: _StaffQueuePreviewItem(entry: entry, isWaiting: true),
                ),
            ],
            if (inRoomEntries.isNotEmpty) ...[
              if (waitingEntries.isNotEmpty)
                const SizedBox(height: NeuTokens.spaceXs),
              Text(
                'In room',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.primary(context),
                ),
              ),
              const SizedBox(height: NeuTokens.spaceXs),
              for (final entry in inRoomEntries.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: NeuTokens.spaceXs),
                  child: _StaffQueuePreviewItem(entry: entry, isWaiting: false),
                ),
            ],
            if (waitingEntries.length > 3 || inRoomEntries.length > 3)
              Center(
                child: TextButton(
                  onPressed: () => context.push(Routes.staffQueue),
                  child: Text(
                    '+ ${state.queueEntries.length - 6} more',
                    style: AppTextStyles.labelMedium,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StaffQueuePreviewItem extends StatelessWidget {
  final QueueEntryWithDetails entry;
  final bool isWaiting;

  const _StaffQueuePreviewItem({required this.entry, required this.isWaiting});

  @override
  Widget build(BuildContext context) {
    final statusColor = isWaiting
        ? ThemeColors.warning(context)
        : ThemeColors.primary(context);

    return NeuCard(
      child: Row(
        children: [
          NeuContainer(
            variant: NeuVariant.pressed,
            shape: const CircleBorder(),
            padding: const EdgeInsets.symmetric(
              horizontal: NeuTokens.spaceSm,
              vertical: NeuTokens.spaceXs,
            ),
            child: Text(
              '#${entry.queueEntry.position}',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: NeuTokens.tightGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.pet.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.pet.species.displayName} \u2022 ${entry.appointment.reason ?? 'Checkup'}',
                  style: AppTextStyles.bodySmall.subtleOf(
                    Theme.of(context).brightness,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          NeuContainer(
            variant: NeuVariant.pressed,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(
              horizontal: NeuTokens.spaceXs + 2,
              vertical: 4,
            ),
            child: Text(
              entry.queueEntry.status.value.replaceAll('_', ' ').toLowerCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyQueuePreview extends StatelessWidget {
  const _EmptyQueuePreview();

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      child: Column(
        children: [
          NeuContainer(
            variant: NeuVariant.inset,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(NeuTokens.spaceLg),
            child: Icon(
              Icons.queue_outlined,
              size: 48,
              color: ThemeColors.primary(context),
            ),
          ),
          const SizedBox(height: NeuTokens.spaceMd),
          Text(
            'No patients in the queue',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NeuTokens.spaceXxs),
          Text(
            'Appointments will appear here when patients arrive.',
            style: AppTextStyles.bodyMedium.subtleOf(
              Theme.of(context).brightness,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StaffQuickLinksSection extends StatelessWidget {
  const _StaffQuickLinksSection();

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
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Appointment reminders & updates',
                onTap: () => context.push(Routes.notifications),
              ),
              NeuDivider(indent: 56),
              _LinkTile(
                icon: Icons.medical_services_outlined,
                title: 'Medical records',
                subtitle: 'View patient health history',
                onTap: () =>
                    NeuToast.info(context, 'Medical records coming soon'),
              ),
              NeuDivider(indent: 56),
              _LinkTile(
                icon: Icons.inventory_2_outlined,
                title: 'Low stock alerts',
                subtitle: 'Medicines needing restock',
                onTap: () =>
                    NeuToast.info(context, 'Low stock alerts coming soon'),
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
