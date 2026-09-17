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
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';

/// Staff Dashboard - Clinic staff management features
/// Only accessible by STAFF and ADMIN roles
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
          const SizedBox(height: 16),
          Text(
            'Loading...',
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuContainer(
              borderRadius: 80,
              padding: const EdgeInsets.all(28),
              color: AppColors.error,
              boxShadow: NeuShadow.color(
                context,
                AppColors.error,
                blur: 24,
                opacity: 0.32,
              ),
              child: const Icon(
                Icons.block_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Access Denied',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: ThemeColors.error(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This area is for clinic staff only.\n\nUse the pet owner dashboard instead.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            NeuButton(
              text: 'Go Back',
              onPressed: () => context.pop(),
              icon: Icons.arrow_back_rounded,
              variant: NeuButtonVariant.secondary,
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Main staff dashboard content
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
                      'Staff Dashboard - ${user?.role?.displayName ?? 'Staff'}',
                      style: AppTextStyles.bodySmall.subtleOf(
                        Theme.of(context).brightness,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push(Routes.notifications),
                    tooltip: 'Notifications',
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
                      // Quick Stats
                      _StaffQuickStatsSection(),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _StaffQuickActionsSection(),
                      const SizedBox(height: 24),

                      // Today's Queue Preview
                      _StaffQueuePreviewSection(),
                      const SizedBox(height: 24),

                      // Quick Links
                      _StaffQuickLinksSection(),
                      const SizedBox(height: 24),
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

/// Quick stats cards for staff
class _StaffQuickStatsSection extends StatelessWidget {
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
              'Today\'s Overview',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Waiting',
                    value: '$waiting',
                    icon: Icons.schedule_outlined,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.warningOnDark
                        : AppColors.warning,
                    trend: 'pets',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'In Room',
                    value: '$inRoom',
                    icon: Icons.door_front_door_outlined,
                    color: ThemeColors.primary(context),
                    trend: 'active',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Now Serving',
                    value: currentServing > 0 ? '#$currentServing' : '-',
                    icon: Icons.person_outlined,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.successOnDark
                        : AppColors.success,
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
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
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
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
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

/// Quick actions for staff
class _StaffQuickActionsSection extends StatelessWidget {
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
            _StaffActionCard(
              icon: Icons.queue_outlined,
              label: 'Manage\nQueue',
              color: ThemeColors.primary(context),
              onTap: () => context.push(Routes.staffQueue),
            ),
            _StaffActionCard(
              icon: Icons.calendar_month_outlined,
              label: 'View\nAppointments',
              color: ThemeColors.primary(context),
              onTap: () => context.push(Routes.staffAppointments),
            ),
            _StaffActionCard(
              icon: Icons.inventory_2_outlined,
              label: 'Check\nInventory',
              color: ThemeColors.primary(context),
              onTap: () => context.push(Routes.staffInventory),
            ),
            _StaffActionCard(
              icon: Icons.scanner_outlined,
              label: 'Scan\nMedicine',
              color: ThemeColors.primary(context),
              onTap: () => context.push(Routes.staffScanning),
            ),
            _StaffActionCard(
              icon: Icons.add_circle_outline,
              label: 'Add\nAppointment',
              color: ThemeColors.primary(context),
              onTap: () =>
                  context.push(Routes.staffAppointments), // Will open add mode
            ),
            _StaffActionCard(
              icon: Icons.assignment_outlined,
              label: 'Daily\nReport',
              color: ThemeColors.primary(context),
              onTap: () => _showComingSoon(context, 'Daily Report'),
            ),
            _StaffActionCard(
              icon: Icons.people_outlined,
              label: 'Walk-in\nCheck-in',
              color: ThemeColors.primary(context),
              onTap: () => _showComingSoon(context, 'Walk-in Check-in'),
            ),
            _StaffActionCard(
              icon: Icons.print_outlined,
              label: 'Print\nQueue',
              color: ThemeColors.primary(context),
              onTap: () => _showComingSoon(context, 'Print Queue'),
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

class _StaffActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StaffActionCard({
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

/// Queue preview section
class _StaffQueuePreviewSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QueueBloc, QueueState>(
      builder: (context, state) {
        if (state is! QueueStaffLoaded || state.queueEntries.isEmpty) {
          return _EmptyQueuePreview();
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
                  'Live Queue',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push(Routes.staffQueue),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (waitingEntries.isNotEmpty) ...[
              Text(
                'Waiting / Called',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.warningOnDark
                      : AppColors.warning,
                ),
              ),
              const SizedBox(height: 8),
              ...waitingEntries
                  .take(3)
                  .map(
                    (entry) =>
                        _StaffQueuePreviewItem(entry: entry, isWaiting: true),
                  ),
            ],
            if (inRoomEntries.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'In Room',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.primary(context),
                ),
              ),
              const SizedBox(height: 8),
              ...inRoomEntries
                  .take(3)
                  .map(
                    (entry) =>
                        _StaffQueuePreviewItem(entry: entry, isWaiting: false),
                  ),
            ],
            if (waitingEntries.length > 3 || inRoomEntries.length > 3) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.push(Routes.staffQueue),
                  child: Text(
                    '+ ${state.queueEntries.length - 6} more entries',
                  ),
                ),
              ),
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = isWaiting
        ? (isDark ? AppColors.warningOnDark : AppColors.warning)
        : ThemeColors.primary(context);

    return NeuCard(
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${entry.queueEntry.position}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                Text(
                  '${entry.pet.species.displayName} • ${entry.appointment.reason ?? 'Checkup'}',
                  style: AppTextStyles.bodySmall.subtleOf(
                    Theme.of(context).brightness,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              entry.queueEntry.status.displayName,
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
  @override
  Widget build(BuildContext context) {
    return NeuCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          NeuContainer(
            borderRadius: 48,
            padding: const EdgeInsets.all(20),
            color: AppColors.primary,
            boxShadow: NeuShadow.color(
              context,
              AppColors.primary,
              blur: 24,
              opacity: 0.32,
            ),
            child: const Icon(
              Icons.queue_outlined,
              size: 48,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Queue is Empty',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No patients checked in yet.\nAppointments will appear here when patients arrive.',
            style: AppTextStyles.bodyMedium
                .subtleOf(Theme.of(context).brightness)
                .copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Quick links section
class _StaffQuickLinksSection extends StatelessWidget {
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
                subtitle: 'View patient health history',
                onTap: () => _showComingSoon(context, 'Medical Records'),
              ),
              const Divider(height: 1, indent: 56),
              _LinkTile(
                icon: Icons.inventory_2_outlined,
                title: 'Low Stock Alerts',
                subtitle: 'Medicines needing restock',
                onTap: () => _showComingSoon(context, 'Low Stock Alerts'),
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
