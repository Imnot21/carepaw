import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_bloc.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_event.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_state.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/app/theme/theme_colors.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Queue page for pet owners - shows their position and wait time
class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  @override
  void initState() {
    super.initState();

    // Load queue when page initializes
    context.read<QueueBloc>().add(QueueLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const _NotLoggedInView();
        }

        final user = authState.user;
        final isPetOwner = user.role == UserRole.petOwner;

        if (!isPetOwner) {
          return const _AccessDeniedView();
        }

        return Scaffold(
          backgroundColor: ThemeColors.background(context),
          appBar: AppBar(
            title: Text(
              'Queue status',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            // Reload happens via pull-to-refresh (RefreshIndicator) instead of a button.
          ),
          body: BlocConsumer<QueueBloc, QueueState>(
            listener: (context, state) {
              if (state is QueueOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: ThemeColors.success(context),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              } else if (state is QueueError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: ThemeColors.error(context),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is QueueLoading) {
                return const NeuSkeletonList();
              }

              if (state is QueueError) {
                return _buildErrorState(state.message);
              }

              if (state is QueueLoaded) {
                return _buildQueueView(state);
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NeuContainer(
            variant: NeuVariant.inset,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(NeuTokens.spaceLg),
            child: Icon(
              Icons.queue_rounded,
              size: 48,
              color: ThemeColors.primary(context),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Queue Status',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Pull to refresh or wait for updates',
            style: AppTextStyles.bodyLarge
                .subtleOf(Theme.of(context).brightness)
                .copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQueueView(QueueLoaded state) {
    final hasQueueEntries = state.queueEntries.isNotEmpty;
    final userPosition = state.userPosition;
    final petsAhead = state.petsAhead;
    final isInQueue = userPosition != null && userPosition > 0;

    // Calculate estimated wait time
    final estimatedWait = _calculateEstimatedWait(state);

    Future<void> refresh() async {
      context.read<QueueBloc>().add(QueueLoadRequested());
    }

    // No pets in the queue (and the user isn't currently queued): center the
    // empty state vertically, consistent with the other pages, instead of
    // pinning it under the app bar. Still scrollable + pull-to-refresh.
    if (!hasQueueEntries && !isInQueue) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 96, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _EmptyQueueCard(),
                      const SizedBox(height: 28),
                      _UpcomingCheckInSection(queueEntries: state.queueEntries),
                      const SizedBox(height: 28),
                      _QueueInfoCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 96, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Position Card
            if (isInQueue) ...[
              _PositionCard(
                position: userPosition,
                petsAhead: petsAhead,
                estimatedWaitMinutes: estimatedWait,
              ),
              const SizedBox(height: 28),
            ] else ...[
              _NotInQueueCard(),
              const SizedBox(height: 28),
            ],

            // Your Pets in Queue
            if (hasQueueEntries) ...[
              Text(
                'Your Pets in Queue',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...state.queueEntries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _QueueEntryCard(entry: entry, isCurrentUser: true),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Queue Info
            _QueueInfoCard(),
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
              padding: const EdgeInsets.all(28),
              color: ThemeColors.error(context),
              boxShadow: NeuShadow.color(
                context,
                ThemeColors.error(context),
                blur: 24,
                opacity: 0.32,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 70,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Failed to Load Queue',
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodyMedium.subtleOf(
                Theme.of(context).brightness,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            NeuButton(
              text: 'Retry',
              onPressed: () {
                context.read<QueueBloc>().add(QueueLoadRequested());
              },
              icon: Icons.refresh_rounded,
              variant: NeuButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  int? _calculateEstimatedWait(QueueLoaded state) {
    if (state.petsAhead == null || state.petsAhead! <= 0) {
      return null;
    }
    // Rough estimate: 15 minutes per pet ahead
    return state.petsAhead! * 15;
  }
}

/// Upcoming non-terminal appointments not yet queued, each with a Check In action.
/// Provided its own filtering because the appointment list still contains
/// checked-in items that may not have appeared in the queue yet.
class _UpcomingCheckInSection extends StatelessWidget {
  final List<QueueEntryWithDetails> queueEntries;

  const _UpcomingCheckInSection({required this.queueEntries});

  @override
  Widget build(BuildContext context) {
    final queuedAppointmentIds = queueEntries
        .map((e) => e.appointment.id)
        .whereType<int>()
        .toSet();

    return BlocBuilder<AppointmentBloc, AppointmentState>(
      builder: (context, appointmentState) {
        if (appointmentState is! AppointmentLoaded)
          return const SizedBox.shrink();

        final upcoming = appointmentState.upcomingWithPetDetails
            .where(
              (detail) =>
                  detail.appointment.id != null &&
                  !queuedAppointmentIds.contains(detail.appointment.id) &&
                  !detail.appointment.isTerminal,
            )
            .toList();

        if (upcoming.isEmpty) return const SizedBox.shrink();

        return NeuCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NeuContainer(
                    borderRadius: 12,
                    padding: const EdgeInsets.all(10),
                    variant: NeuVariant.flat,
                    color: ThemeColors.primary(context).withValues(alpha: 0.12),
                    child: Icon(
                      Icons.event_available_rounded,
                      size: 20,
                      color: ThemeColors.primary(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check In',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "You're not in the queue yet. Check in when you arrive at the clinic.",
                          style: AppTextStyles.bodySmall.subtleOf(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...upcoming.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _UpcomingCheckInTile(detail: detail),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UpcomingCheckInTile extends StatelessWidget {
  final AppointmentWithPetDetails detail;

  const _UpcomingCheckInTile({required this.detail});

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final appointment = detail.appointment;
    final pet = detail.pet;

    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          PetUtils.buildAvatar(species: pet.species, radius: 22, iconSize: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(appointment.scheduledAt)} · ${_formatTime(appointment.scheduledAt)}',
                  style: AppTextStyles.bodySmall.subtleOf(
                    Theme.of(context).brightness,
                  ),
                ),
                if (appointment.reason != null &&
                    appointment.reason!.trim().isNotEmpty)
                  Text(
                    appointment.reason!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ThemeColors.textSecondary(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          NeuButton(
            text: 'Check In',
            icon: Icons.check_circle_outline_rounded,
            variant: NeuButtonVariant.primary,
            size: NeuButtonSize.small,
            onPressed: () {
              context.read<QueueBloc>().add(
                QueueCheckInRequested(appointment.id!),
              );
              context.read<AppointmentBloc>().add(
                AppointmentRefreshRequested(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Position card showing user's queue position
class _PositionCard extends StatelessWidget {
  final int position;
  final int? petsAhead;
  final int? estimatedWaitMinutes;

  const _PositionCard({
    required this.position,
    this.petsAhead,
    this.estimatedWaitMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: NeuContainer(
        padding: const EdgeInsets.all(28),
        borderRadius: 28,
        color: ThemeColors.primary(context),
        boxShadow: NeuShadow.color(
          context,
          ThemeColors.primary(context),
          blur: 24,
          opacity: 0.32,
        ),
        child: Column(
          children: [
            Text(
              'Your Position',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textOnPrimary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$position',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              petsAhead != null && petsAhead! > 0
                  ? '$petsAhead ${petsAhead == 1 ? 'pet' : 'pets'} ahead of you'
                  : 'You\'re next!',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textOnPrimary.withValues(alpha: 0.9),
              ),
            ),
            if (estimatedWaitMinutes != null && estimatedWaitMinutes! > 0) ...[
              const SizedBox(height: 20),
              NeuContainer(
                borderRadius: 20,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                variant: NeuVariant.flat,
                color: AppColors.textOnPrimary.withValues(alpha: 0.15),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: AppColors.textOnPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Est. wait: $estimatedWaitMinutes min',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card shown when user has no pets in queue
class _EmptyQueueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          NeuContainer(
            borderRadius: 48,
            padding: const EdgeInsets.all(22),
            color: ThemeColors.primary(context),
            boxShadow: NeuShadow.color(
              context,
              ThemeColors.primary(context),
              blur: 24,
              opacity: 0.32,
            ),
            child: const Icon(
              Icons.queue_outlined,
              size: 48,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Pets in Queue',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'You don\'t have any pets currently checked in.\nBook an appointment and check in when you arrive.',
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

/// Card shown when user has pets but not in current queue
class _NotInQueueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          NeuContainer(
            borderRadius: 48,
            padding: const EdgeInsets.all(24),
            variant: NeuVariant.flat,
            color: ThemeColors.warning(context).withValues(alpha: 0.12),
            child: Icon(
              Icons.info_outline_rounded,
              size: 48,
              color: ThemeColors.warning(context),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Not Currently in Queue',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your pets have upcoming appointments but aren\'t checked in yet.\nCheck in when you arrive at the clinic.',
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

/// Individual queue entry card
class _QueueEntryCard extends StatelessWidget {
  final QueueEntryWithDetails entry;
  final bool isCurrentUser;

  const _QueueEntryCard({required this.entry, this.isCurrentUser = false});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, entry.queueEntry.status);

    return NeuCard(
      padding: const EdgeInsets.all(20),
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
                color: statusColor,
                boxShadow: NeuShadow.color(
                  context,
                  statusColor,
                  blur: 12,
                  opacity: 0.3,
                ),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Text(
                      '#${entry.queueEntry.position}',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textOnPrimary,
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
                    Text(
                      entry.pet.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.pet.species.displayName} • ${entry.pet.breed}',
                      style: AppTextStyles.bodySmall.subtleOf(
                        Theme.of(context).brightness,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Status chip
              NeuContainer(
                borderRadius: 20,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
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
                Icon(
                  Icons.medical_services_outlined,
                  size: 18,
                  color: ThemeColors.textSecondary(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment',
                        style: AppTextStyles.labelSmall.subtleOf(
                          Theme.of(context).brightness,
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
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: ThemeColors.textSecondary(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.queueEntry.estimatedWaitMinutes} min',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ThemeColors.textSecondary(context),
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
                  backgroundColor: ThemeColors.primary(
                    context,
                  ).withValues(alpha: 0.15),
                  foregroundColor: ThemeColors.primary(context),
                ),
                const SizedBox(width: 12),
                Text(
                  'Dr. ${entry.veterinarian.fullName}',
                  style: AppTextStyles.bodyMedium.subtleOf(
                    Theme.of(context).brightness,
                  ),
                ),
              ],
            ),
          ],

          // Check-in time
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 14,
                    color: ThemeColors.textSecondary(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Checked in at ${_formatTime(entry.queueEntry.checkedInAt)}',
                    style: AppTextStyles.bodySmall.mutedOf(
                      Theme.of(context).brightness,
                    ),
                  ),
                ],
              ),
              if (entry.queueEntry.calledAt != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up_outlined,
                      size: 14,
                      color: ThemeColors.info(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Called at ${_formatTime(entry.queueEntry.calledAt!)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: ThemeColors.info(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              if (entry.queueEntry.room != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                ),
              ],
            ],
          ),
        ],
      ),
    );
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
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Queue info card with helpful information
class _QueueInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: ThemeColors.primary(context),
              ),
              const SizedBox(width: 10),
              Text(
                'How It Works',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.primary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.check_circle_outline_rounded,
            title: 'Check In',
            description: 'Arrive at the clinic and check in at the front desk',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.queue_outlined,
            title: 'Wait',
            description:
                'Monitor your position here - you\'ll get a notification when called',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.volume_up_outlined,
            title: 'Called',
            description:
                'Listen for your name or check the screen for your room number',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.door_front_door_outlined,
            title: 'Visit',
            description: 'Proceed to the assigned room for your appointment',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NeuContainer(
          variant: NeuVariant.pressed,
          borderRadius: NeuTokens.radiusSm,
          padding: const EdgeInsets.all(NeuTokens.spaceXs),
          child: Icon(icon, size: 16, color: ThemeColors.primary(context)),
        ),
        const SizedBox(width: 14),
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
                description,
                style: AppTextStyles.bodySmall.subtleOf(
                  Theme.of(context).brightness,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Not logged in view
class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      body: Center(
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
                  Icons.queue_outlined,
                  size: 48,
                  color: ThemeColors.primary(context),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Please log in to view queue',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to check your queue position',
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

/// Access denied view for non-pet-owners
class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      body: Center(
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
                'This page is for pet owners only.\n\nUse the staff queue management page instead.',
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
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
