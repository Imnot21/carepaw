import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_bloc.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_event.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_state.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_loader.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/core/widgets/effects/floating_animation.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';
import 'package:carepaw/core/widgets/effects/scale_on_tap.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Staff queue page - full management view with action buttons
class StaffQueuePage extends StatefulWidget {
  const StaffQueuePage({super.key});

  @override
  State<StaffQueuePage> createState() => _StaffQueuePageState();
}

class _StaffQueuePageState extends State<StaffQueuePage> {
  @override
  void initState() {
    super.initState();
    // Load queue when page initializes
    context.read<QueueBloc>().add(QueueStaffLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const _NotLoggedInView();
        }

        // Check if user is vet, staff, or admin - only these roles can manage queue
        final user = authState.user;
        final isVetOrStaff = user.role == UserRole.veterinarian ||
            user.role == UserRole.staff ||
            user.role == UserRole.admin;

        if (!isVetOrStaff) {
          return const _AccessDeniedView();
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Queue Management'),
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: ScaleOnTap(
                  onTap: () {
                    context.read<QueueBloc>().add(QueueStaffLoadRequested());
                  },
                  child: CpIconButton(
                    icon: Icons.refresh_rounded,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurface,
                    tooltip: 'Refresh',
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: ScaleOnTap(
                  onTap: () {
                    context.read<QueueBloc>().add(const QueueRepositionRequested());
                  },
                  child: CpIconButton(
                    icon: Icons.reorder_rounded,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurface,
                    tooltip: 'Reposition Queue',
                  ),
                ),
              ),
            ],
          ),
          body: AnimatedGradientBackground(
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              Theme.of(context).colorScheme.surface,
            ],
            child: BlocConsumer<QueueBloc, QueueState>(
              listener: (context, state) {
                if (state is QueueOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                  // Reload queue after successful operation
                  context.read<QueueBloc>().add(QueueStaffLoadRequested());
                } else if (state is QueueError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is QueueLoading) {
                  return const Center(child: CpLoader(size: 32));
                }

                if (state is QueueError) {
                  return _buildErrorState(state.message);
                }

                if (state is QueueStaffLoaded) {
                  return _buildStaffQueueView(state);
                }

                return _buildInitialState();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: FloatingAnimation(
          delay: const Duration(milliseconds: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PulsingGlow(
                glowColor: AppColors.primary,
                maxRadius: 20,
                duration: const Duration(seconds: 3),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: PremiumShadows.glow(context, AppColors.primary, intensity: 0.3),
                  ),
                  child: Icon(
                    Icons.people_outline_rounded,
                    size: 60,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Queue Management',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Load the queue to see waiting patients',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(60),
                boxShadow: PremiumShadows.glow(context, AppColors.error, intensity: 0.3),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Queue',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ScaleOnTap(
              onTap: () {
                context.read<QueueBloc>().add(QueueStaffLoadRequested());
              },
              child: CpButton(
                text: 'Retry',
                onPressed: () {
                  context.read<QueueBloc>().add(QueueStaffLoadRequested());
                },
                icon: Icons.refresh_rounded,
                variant: ButtonVariant.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffQueueView(QueueStaffLoaded state) {
    final queueEntries = state.queueEntries;

    return Column(
      children: [
        // Stats bar
        _StatsBar(
          currentServing: state.currentServing,
          totalWaiting: state.totalWaiting,
          totalInRoom: state.totalInRoom,
        ),

        // Queue list
        Expanded(
          child: queueEntries.isEmpty
              ? _buildEmptyQueue()
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<QueueBloc>().add(QueueStaffLoadRequested());
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: queueEntries.length,
                    itemBuilder: (context, index) {
                      final entry = queueEntries[index];
                      return FloatingAnimation(
                        delay: Duration(milliseconds: 50 * index),
                        child: _StaffQueueEntryCard(
                          entry: entry,
                          onCall: entry.queueEntry.status == QueueStatus.waiting
                              ? () => _showCallDialog(entry)
                              : null,
                          onMoveToRoom: entry.queueEntry.status == QueueStatus.called
                              ? () => _showMoveToRoomDialog(entry)
                              : null,
                          onComplete: entry.queueEntry.status == QueueStatus.inRoom
                              ? () => _showCompleteDialog(entry)
                              : null,
                          onSkip: entry.queueEntry.status == QueueStatus.waiting ||
                              entry.queueEntry.status == QueueStatus.called
                                  ? () => _showSkipDialog(entry)
                                  : null,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyQueue() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(60),
                boxShadow: PremiumShadows.glow(context, AppColors.primary, intensity: 0.2),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 60,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Patients in Queue',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Patients will appear here when they check in.\nPull to refresh.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCallDialog(QueueEntryWithDetails entry) {
    showDialog(
      context: context,
      builder: (context) => _PremiumDialog(
        title: 'Call Patient',
        content: Text('Call ${entry.pet.name} (#${entry.queueEntry.position}) for their appointment?'),
        icon: Icons.volume_up_rounded,
        iconColor: AppColors.info,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ScaleOnTap(
            onTap: () {
              Navigator.pop(context);
              context.read<QueueBloc>().add(QueueCallNextRequested());
            },
            child: CpButton(
              text: 'Call Now',
              onPressed: () {
                Navigator.pop(context);
                context.read<QueueBloc>().add(QueueCallNextRequested());
              },
              variant: ButtonVariant.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoveToRoomDialog(QueueEntryWithDetails entry) {
    final roomController = TextEditingController(text: entry.queueEntry.room ?? '1');

    showDialog(
      context: context,
      builder: (context) => _PremiumDialog(
        title: 'Move to Room',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Move ${entry.pet.name} to a room:'),
            const SizedBox(height: 16),
            TextField(
              controller: roomController,
              decoration: const InputDecoration(
                labelText: 'Room Number',
                hintText: 'e.g., 1, 2, A, B',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        icon: Icons.door_front_door_rounded,
        iconColor: AppColors.primary,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ScaleOnTap(
            onTap: () {
              Navigator.pop(context);
              context.read<QueueBloc>().add(QueueMoveToRoomRequested(entry.queueEntry.id!, roomController.text.trim()));
            },
            child: CpButton(
              text: 'Move',
              onPressed: () {
                Navigator.pop(context);
                context.read<QueueBloc>().add(QueueMoveToRoomRequested(entry.queueEntry.id!, roomController.text.trim()));
              },
              variant: ButtonVariant.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(QueueEntryWithDetails entry) {
    showDialog(
      context: context,
      builder: (context) => _PremiumDialog(
        title: 'Complete Visit',
        content: Text('Mark ${entry.pet.name}\'s visit as completed?'),
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppColors.success,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ScaleOnTap(
            onTap: () {
              Navigator.pop(context);
              context.read<QueueBloc>().add(QueueCompleteRequested(entry.queueEntry.id!));
            },
            child: CpButton(
              text: 'Complete',
              onPressed: () {
                Navigator.pop(context);
                context.read<QueueBloc>().add(QueueCompleteRequested(entry.queueEntry.id!));
              },
              variant: ButtonVariant.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showSkipDialog(QueueEntryWithDetails entry) {
    showDialog(
      context: context,
      builder: (context) => _PremiumDialog(
        title: 'Skip Patient',
        content: Text('Skip ${entry.pet.name}? They will be removed from the queue.'),
        icon: Icons.skip_next_rounded,
        iconColor: AppColors.error,
        isDestructive: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ScaleOnTap(
            onTap: () {
              Navigator.pop(context);
              context.read<QueueBloc>().add(QueueSkipRequested(entry.queueEntry.id!));
            },
            child: CpButton(
              text: 'Skip',
              onPressed: () {
                Navigator.pop(context);
                context.read<QueueBloc>().add(QueueSkipRequested(entry.queueEntry.id!));
              },
              variant: ButtonVariant.destructive,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats bar showing queue overview
class _StatsBar extends StatelessWidget {
  final int currentServing;
  final int totalWaiting;
  final int totalInRoom;

  const _StatsBar({
    required this.currentServing,
    required this.totalWaiting,
    required this.totalInRoom,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 0,
      padding: const EdgeInsets.all(16),
      blur: 20,
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.glassBorderDark
          : AppColors.glassBorderLight,
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.person_outline_rounded,
              label: 'Waiting',
              value: '$totalWaiting',
              color: AppColors.warning,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.door_front_door_outlined,
              label: 'In Room',
              value: '$totalInRoom',
              color: AppColors.primary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.volume_up_outlined,
              label: 'Now Serving',
              value: currentServing > 0 ? '#$currentServing' : '—',
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Staff queue entry card with action buttons
class _StaffQueueEntryCard extends StatelessWidget {
  final QueueEntryWithDetails entry;
  final VoidCallback? onCall;
  final VoidCallback? onMoveToRoom;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const _StaffQueueEntryCard({
    required this.entry,
    this.onCall,
    this.onMoveToRoom,
    this.onComplete,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(entry.queueEntry.status);
    final isCurrentServing = entry.queueEntry.position == 1 &&
        (entry.queueEntry.status == QueueStatus.waiting || entry.queueEntry.status == QueueStatus.called);

    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      blur: 20,
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: isCurrentServing
          ? statusColor.withValues(alpha: 0.5)
          : (Theme.of(context).brightness == Brightness.dark
              ? AppColors.glassBorderDark
              : AppColors.glassBorderLight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with position and status
          Row(
            children: [
              // Position badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCurrentServing
                      ? statusColor
                      : statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: isCurrentServing ? PremiumShadows.glow(context, statusColor, intensity: 0.4) : null,
                ),
                child: Center(
                  child: Text(
                    '#${entry.queueEntry.position}',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isCurrentServing
                          ? AppColors.textOnPrimary
                          : statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Pet info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.pet.name,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isCurrentServing) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'NEXT',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${entry.pet.species.displayName} • ${entry.pet.breed} • Owner: ${entry.pet.ownerId}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
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

          const SizedBox(height: 12),

          // Appointment info
          GlassContainer(
            borderRadius: 12,
            padding: const EdgeInsets.all(12),
            blur: 15,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.medical_services_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        entry.appointment.reason ?? 'General checkup',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (entry.queueEntry.estimatedWaitMinutes != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.queueEntry.estimatedWaitMinutes} min',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Vet info
          if (entry.veterinarian.fullName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    entry.veterinarian.fullName.isNotEmpty
                        ? entry.veterinarian.fullName[0]
                        : 'D',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Dr. ${entry.veterinarian.fullName}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],

          // Time info
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time_outlined,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Text(
                'Checked in: ${_formatTime(entry.queueEntry.checkedInAt)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              if (entry.queueEntry.calledAt != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.volume_up_outlined,
                  size: 14,
                  color: AppColors.info,
                ),
                const SizedBox(width: 6),
                Text(
                  'Called: ${_formatTime(entry.queueEntry.calledAt!)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (entry.queueEntry.room != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.door_front_door_outlined,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'Room ${entry.queueEntry.room}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),

          // Action buttons
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final actions = <Widget>[];

    if (onCall != null) {
      actions.add(
        Expanded(
          child: CpButton(
            text: 'Call',
            onPressed: onCall!,
            icon: Icons.volume_up_rounded,
            variant: ButtonVariant.secondary,
            size: ButtonSize.small,
          ),
        ),
      );
    }

    if (onMoveToRoom != null) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: CpButton(
            text: 'Room',
            onPressed: onMoveToRoom!,
            icon: Icons.door_front_door_rounded,
            variant: ButtonVariant.primary,
            size: ButtonSize.small,
          ),
        ),
      );
    }

    if (onComplete != null) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: CpButton(
            text: 'Complete',
            onPressed: onComplete!,
            icon: Icons.check_rounded,
            variant: ButtonVariant.primary,
            size: ButtonSize.small,
          ),
        ),
      );
    }

    if (onSkip != null) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: CpButton(
            text: 'Skip',
            onPressed: onSkip!,
            icon: Icons.skip_next_rounded,
            variant: ButtonVariant.destructive,
            size: ButtonSize.small,
          ),
        ),
      );
    }

    return Row(children: actions);
  }

  Color _getStatusColor(QueueStatus status) {
    switch (status) {
      case QueueStatus.waiting:
        return AppColors.warning;
      case QueueStatus.called:
        return AppColors.info;
      case QueueStatus.inRoom:
        return AppColors.primary;
      case QueueStatus.completed:
        return AppColors.success;
      case QueueStatus.skipped:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Premium dialog wrapper
class _PremiumDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final IconData icon;
  final Color iconColor;
  final bool isDestructive;
  final List<Widget> actions;

  const _PremiumDialog({
    required this.title,
    required this.content,
    required this.icon,
    required this.iconColor,
    required this.actions,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: content,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: actions,
    );
  }
}

/// Not logged in view
class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        colors: [
          AppColors.primary.withValues(alpha: 0.05),
          AppColors.secondary.withValues(alpha: 0.03),
        ],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PulsingGlow(
                  glowColor: AppColors.primary,
                  maxRadius: 40,
                  duration: const Duration(seconds: 3),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(80),
                      boxShadow: PremiumShadows.primary,
                    ),
                    child: Icon(
                      Icons.people_outlined,
                      size: 80,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Please log in to manage queue',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in to access queue management',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CpButton(
                  text: 'Log In',
                  onPressed: () => context.go('/login'),
                  icon: Icons.login_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Access denied view for pet owners
class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        colors: [
          AppColors.error.withValues(alpha: 0.06),
          AppColors.warning.withValues(alpha: 0.04),
          AppColors.surface,
        ],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PulsingGlow(
                  glowColor: AppColors.error,
                  maxRadius: 40,
                  duration: const Duration(seconds: 3),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientError,
                      borderRadius: BorderRadius.circular(80),
                      boxShadow: PremiumShadows.glow(context, AppColors.error, intensity: 0.3),
                    ),
                    child: Icon(
                      Icons.block_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Access Denied',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Only veterinarians and clinic staff can manage the queue.\n\nThis feature is for clinic operations only.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CpButton(
                  text: 'Go Back',
                  onPressed: () => context.pop(),
                  icon: Icons.arrow_back_rounded,
                  variant: ButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}