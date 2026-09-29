import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_bloc.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_event.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_state.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
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
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: NeuIconButton(
                  icon: Icons.reorder_rounded,
                  onPressed: () {
                    context.read<QueueBloc>().add(const QueueRepositionRequested());
                  },
                  color: ThemeColors.textPrimary(context),
                  tooltip: 'Reposition Queue',
                ),
              ),
            ],
          ),
          body: BlocConsumer<QueueBloc, QueueState>(
              listener: (context, state) {
                if (state is QueueOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: ThemeColors.success(context),
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
                      backgroundColor: ThemeColors.error(context),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is QueueLoading) {
                  return const Center(child: NeuCircularProgress());
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
        );
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuContainer(
              borderRadius: 70,
              padding: const EdgeInsets.all(30),
              color: ThemeColors.primary(context),
              boxShadow: NeuShadow.color(context, ThemeColors.primary(context), blur: 24, opacity: 0.32),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 60,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: 28),
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
                color: ThemeColors.textSecondary(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
            NeuContainer(
              borderRadius: 70,
              padding: const EdgeInsets.all(30),
              color: ThemeColors.error(context),
              boxShadow: NeuShadow.color(context, ThemeColors.error(context), blur: 24, opacity: 0.32),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Failed to Load Queue',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            NeuButton(
              text: 'Retry',
              onPressed: () {
                context.read<QueueBloc>().add(QueueStaffLoadRequested());
              },
              icon: Icons.refresh_rounded,
              variant: NeuButtonVariant.primary,
              expanded: true,
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: queueEntries.length,
                    itemBuilder: (context, index) {
                      final entry = queueEntries[index];
                      return _StaffQueueEntryCard(
                        entry: entry,
                        onPriorityChanged: (priority) {
                          context.read<QueueBloc>().add(
                                QueueSetPriorityRequested(
                                  entry.queueEntry.id!,
                                  priority,
                                ),
                              );
                        },
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
            NeuContainer(
              borderRadius: 70,
              padding: const EdgeInsets.all(30),
              color: ThemeColors.primary(context),
              boxShadow: NeuShadow.color(context, ThemeColors.primary(context), blur: 24, opacity: 0.32),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 60,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: 28),
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
                color: ThemeColors.textSecondary(context),
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
    final pageContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => _PremiumDialog(
        title: 'Call Patient',
        content: Text('Call ${entry.pet.name} (#${entry.queueEntry.position}) for their appointment?'),
        icon: Icons.volume_up_rounded,
        iconColor: ThemeColors.info(dialogContext),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          NeuButton(
            text: 'Call Now',
            onPressed: () {
              Navigator.pop(dialogContext);
              pageContext.read<QueueBloc>().add(QueueCallNextRequested());
            },
            variant: NeuButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  void _showMoveToRoomDialog(QueueEntryWithDetails entry) {
    final pageContext = context;
    final roomController = TextEditingController(text: entry.queueEntry.room ?? '1');

    showDialog(
      context: context,
      builder: (dialogContext) => _PremiumDialog(
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
        iconColor: ThemeColors.primary(dialogContext),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          NeuButton(
            text: 'Move',
            onPressed: () {
              final room = roomController.text.trim();
              Navigator.pop(dialogContext);
              pageContext.read<QueueBloc>().add(QueueMoveToRoomRequested(entry.queueEntry.id!, room));
            },
            variant: NeuButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(QueueEntryWithDetails entry) {
    final pageContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => _PremiumDialog(
        title: 'Complete Visit',
        content: Text('Mark ${entry.pet.name}\'s visit as completed?'),
        icon: Icons.check_circle_outline_rounded,
        iconColor: ThemeColors.success(dialogContext),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          NeuButton(
            text: 'Complete',
            onPressed: () {
              Navigator.pop(dialogContext);
              pageContext.read<QueueBloc>().add(QueueCompleteRequested(entry.queueEntry.id!));
            },
            variant: NeuButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  void _showSkipDialog(QueueEntryWithDetails entry) {
    final pageContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => _PremiumDialog(
        title: 'Skip Patient',
        content: Text('Skip ${entry.pet.name}? They will be removed from the queue.'),
        icon: Icons.skip_next_rounded,
        iconColor: ThemeColors.error(dialogContext),
        isDestructive: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          NeuButton(
            text: 'Skip',
            onPressed: () {
              Navigator.pop(dialogContext);
              pageContext.read<QueueBloc>().add(QueueSkipRequested(entry.queueEntry.id!));
            },
            variant: NeuButtonVariant.destructive,
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
    return NeuContainer(
      borderRadius: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      variant: NeuVariant.flat,
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.person_outline_rounded,
              label: 'Waiting',
              value: '$totalWaiting',
              color: ThemeColors.warning(context),
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: ThemeColors.border(context),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.door_front_door_outlined,
              label: 'In Room',
              value: '$totalInRoom',
              color: ThemeColors.primary(context),
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: ThemeColors.border(context),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.volume_up_outlined,
              label: 'Now Serving',
              value: currentServing > 0 ? '#$currentServing' : '-',
              color: ThemeColors.info(context),
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
        NeuContainer(
          borderRadius: 14,
          padding: const EdgeInsets.all(12),
          variant: NeuVariant.flat,
          color: color.withValues(alpha: 0.12),
          child: Icon(
            icon,
            size: 22,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: ThemeColors.textSecondary(context),
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
  final ValueChanged<QueuePriority>? onPriorityChanged;

  const _StaffQueueEntryCard({
    required this.entry,
    this.onCall,
    this.onMoveToRoom,
    this.onComplete,
    this.onSkip,
    this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, entry.queueEntry.status);
    final isCurrentServing = entry.queueEntry.position == 1 &&
        (entry.queueEntry.status == QueueStatus.waiting || entry.queueEntry.status == QueueStatus.called);

    return NeuCard(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 14),
      borderColor: isCurrentServing ? statusColor.withValues(alpha: 0.5) : null,
      borderWidth: isCurrentServing ? 1.5 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with position and status
          Row(
            children: [
              // Position badge
              NeuContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(10),
                variant: NeuVariant.raised,
                color: isCurrentServing
                    ? statusColor
                    : statusColor.withValues(alpha: 0.15),
                boxShadow: isCurrentServing
                    ? NeuShadow.color(context, statusColor, blur: 16, opacity: 0.4)
                    : null,
                child: SizedBox(
                  width: 40,
                  height: 40,
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
              ),
              const SizedBox(width: 14),
              // Pet info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.pet.name,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentServing) ...[
                          const SizedBox(width: 8),
                          NeuContainer(
                            borderRadius: 12,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            variant: NeuVariant.flat,
                            color: statusColor.withValues(alpha: 0.15),
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
                    const SizedBox(height: 2),
                    Text(
                      '${entry.pet.species.displayName} • ${entry.pet.breed} • Owner: ${entry.pet.ownerId}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: ThemeColors.textSecondary(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onPriorityChanged != null &&
                  entry.queueEntry.id != null) ...[
                _PriorityControl(
                  priority: entry.queueEntry.priority,
                  onChanged: onPriorityChanged,
                ),
                const SizedBox(width: 8),
              ],

              // Status chip
              NeuContainer(
                borderRadius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                variant: NeuVariant.flat,
                color: statusColor.withValues(alpha: 0.12),
                borderColor: statusColor.withValues(alpha: 0.3),
                borderWidth: 1,
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

          const SizedBox(height: 16),

          // Appointment info
          NeuContainer(
            borderRadius: 14,
            padding: const EdgeInsets.all(14),
            variant: NeuVariant.inset,
            child: Row(
              children: [
                NeuContainer(
                  borderRadius: 10,
                  padding: const EdgeInsets.all(8),
                  variant: NeuVariant.flat,
                  color: ThemeColors.primary(context).withValues(alpha: 0.12),
                  child: Icon(
                    Icons.medical_services_outlined,
                    size: 18,
                    color: ThemeColors.primary(context),
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
                          color: ThemeColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
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
                  NeuContainer(
                    borderRadius: 10,
                    padding: const EdgeInsets.all(8),
                    variant: NeuVariant.flat,
                    color: ThemeColors.warning(context).withValues(alpha: 0.12),
                    child: Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: ThemeColors.warning(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.queueEntry.estimatedWaitMinutes} min',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ThemeColors.warning(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Vet info
          if (entry.veterinarian.fullName.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                NeuAvatar(
                  radius: 18,
                  initials: entry.veterinarian.fullName.isNotEmpty
                      ? entry.veterinarian.fullName[0]
                      : 'D',
                  backgroundColor: ThemeColors.primary(context).withValues(alpha: 0.15),
                  foregroundColor: ThemeColors.primary(context),
                ),
                const SizedBox(width: 12),
                Text(
                  'Dr. ${entry.veterinarian.fullName}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ],

          // Time info
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time_outlined,
                size: 14,
                color: ThemeColors.textSecondary(context),
              ),
              const SizedBox(width: 6),
              Text(
                'Checked in: ${_formatTime(entry.queueEntry.checkedInAt)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
              ),
              if (entry.queueEntry.calledAt != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.volume_up_outlined,
                  size: 14,
                  color: ThemeColors.info(context),
                ),
                const SizedBox(width: 6),
                Text(
                  'Called: ${_formatTime(entry.queueEntry.calledAt!)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ThemeColors.info(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (entry.queueEntry.room != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.door_front_door_outlined,
                  size: 14,
                  color: ThemeColors.success(context),
                ),
                const SizedBox(width: 6),
                Text(
                  'Room ${entry.queueEntry.room}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ThemeColors.success(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),

          // Action buttons
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
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
          child: NeuButton(
            text: 'Call',
            onPressed: onCall!,
            icon: Icons.volume_up_rounded,
            variant: NeuButtonVariant.secondary,
            size: NeuButtonSize.medium,
            expanded: true,
          ),
        ),
      );
    }

    if (onMoveToRoom != null) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: NeuButton(
            text: 'Room',
            onPressed: onMoveToRoom!,
            icon: Icons.door_front_door_rounded,
            variant: NeuButtonVariant.primary,
            size: NeuButtonSize.medium,
            expanded: true,
          ),
        ),
      );
    }

    if (onComplete != null) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: NeuButton(
            text: 'Complete',
            onPressed: onComplete!,
            icon: Icons.check_rounded,
            variant: NeuButtonVariant.primary,
            size: NeuButtonSize.medium,
            expanded: true,
          ),
        ),
      );
    }

    if (onSkip != null) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: NeuButton(
            text: 'Skip',
            onPressed: onSkip!,
            icon: Icons.skip_next_rounded,
            variant: NeuButtonVariant.destructive,
            size: NeuButtonSize.medium,
            expanded: true,
          ),
        ),
      );
    }

    return Row(children: actions);
  }

  Color _getStatusColor(BuildContext context, QueueStatus status) {
    switch (status) {
      case QueueStatus.waiting:
        return ThemeColors.warning(context);
      case QueueStatus.called:
        return ThemeColors.info(context);
      case QueueStatus.inRoom:
        return ThemeColors.primary(context);
      case QueueStatus.completed:
        return ThemeColors.success(context);
      case QueueStatus.skipped:
        return ThemeColors.textSecondary(context);
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Triage control: a color-coded priority chip that opens a menu to change the
/// entry's clinical priority (Routine / Urgent / Emergency).
class _PriorityControl extends StatelessWidget {
  final QueuePriority priority;
  final ValueChanged<QueuePriority>? onChanged;

  const _PriorityControl({required this.priority, this.onChanged});

  Color _color(BuildContext context, QueuePriority p) =>
      _priorityColor(context, p);

  @override
  Widget build(BuildContext context) {
    final color = _color(context, priority);
    final chip = NeuContainer(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      variant: NeuVariant.flat,
      color: color.withValues(alpha: 0.12),
      borderColor: color.withValues(alpha: 0.3),
      borderWidth: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconFor(priority),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            priority.displayName,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.arrow_drop_down_rounded, size: 16, color: color),
        ],
      ),
    );

    return PopupMenuButton<QueuePriority>(
      onSelected: onChanged,
      tooltip: 'Change priority',
      itemBuilder: (context) => QueuePriority.values.map((p) {
        return PopupMenuItem<QueuePriority>(
          value: p,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _priorityColor(context, p),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(p.displayName),
            ],
          ),
        );
      }).toList(),
      child: chip,
    );
  }

  static IconData _iconFor(QueuePriority p) {
    switch (p) {
      case QueuePriority.emergency:
        return Icons.priority_high_rounded;
      case QueuePriority.urgent:
        return Icons.warning_amber_rounded;
      case QueuePriority.routine:
        return Icons.check_circle_outline_rounded;
    }
  }
}

/// Map a clinical priority to its status color (light/dark aware).
Color _priorityColor(BuildContext context, QueuePriority priority) {
  switch (priority) {
    case QueuePriority.emergency:
      return ThemeColors.error(context);
    case QueuePriority.urgent:
      return ThemeColors.warning(context);
    case QueuePriority.routine:
      return ThemeColors.textSecondary(context);
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
          NeuContainer(
            borderRadius: 12,
            padding: const EdgeInsets.all(10),
            variant: NeuVariant.flat,
            color: iconColor.withValues(alpha: 0.12),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NeuContainer(
                borderRadius: 90,
                padding: const EdgeInsets.all(40),
                color: ThemeColors.primary(context),
                boxShadow: NeuShadow.color(context, ThemeColors.primary(context), blur: 24, opacity: 0.32),
                child: const Icon(
                  Icons.people_outlined,
                  size: 80,
                  color: AppColors.textOnPrimary,
                ),
              ),
              const SizedBox(height: 32),
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
                  color: ThemeColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              NeuButton(
                text: 'Log In',
                onPressed: () => context.go('/login'),
                icon: Icons.login_rounded,
              ),
            ],
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NeuContainer(
                borderRadius: 90,
                padding: const EdgeInsets.all(40),
                color: ThemeColors.error(context),
                boxShadow: NeuShadow.color(context, ThemeColors.error(context), blur: 24, opacity: 0.32),
                child: const Icon(
                  Icons.block_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
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
                'Only veterinarians and clinic staff can manage the queue.\n\nThis feature is for clinic operations only.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              NeuButton(
                text: 'Go Back',
                onPressed: () => context.pop(),
                icon: Icons.arrow_back_rounded,
                variant: NeuButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
