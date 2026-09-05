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
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/floating_animation.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Queue page for pet owners - shows their position and wait time with premium design
class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Load queue when page initializes
    context.read<QueueBloc>().add(QueueLoadRequested());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const _NotLoggedInView();
        }

        // Check if user is a pet owner - only pet owners can access this page
        final user = authState.user;
        final isPetOwner = user.role == UserRole.petOwner;

        if (!isPetOwner) {
          return const _AccessDeniedView();
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Queue Status'),
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CpIconButton(
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    context.read<QueueBloc>().add(QueueLoadRequested());
                  },
                  tooltip: 'Refresh',
                ),
              ),
            ],
          ),
          body: AnimatedGradientBackground(
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.tertiary.withValues(alpha: 0.03),
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
                } else if (state is QueueError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is QueueLoading) {
                  return const Center(child: CpLoader());
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
          PulsingGlow(
            glowColor: AppColors.primary,
            maxRadius: 40,
            duration: const Duration(seconds: 3),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(70),
                boxShadow: PremiumShadows.primary,
              ),
              child: Icon(
                Icons.queue,
                size: 70,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
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
            style: AppTextStyles.bodyLarge.subtle.copyWith(
              height: 1.5,
            ),
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

    // Calculate estimated wait time
    final estimatedWait = _calculateEstimatedWait(state);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<QueueBloc>().add(QueueLoadRequested());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 88, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Position Card
            if (userPosition != null && userPosition > 0) ...[
              _PositionCard(
                position: userPosition,
                petsAhead: petsAhead,
                estimatedWaitMinutes: estimatedWait,
                pulseAnimation: _pulseAnimation,
              ),
              const SizedBox(height: 24),
            ] else if (!hasQueueEntries) ...[
              _EmptyQueueCard(),
              const SizedBox(height: 24),
            ] else ...[
              _NotInQueueCard(),
              const SizedBox(height: 24),
            ],

            // Your Pets in Queue
            if (hasQueueEntries) ...[
              Text(
                'Your Pets in Queue',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...state.queueEntries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _QueueEntryCard(
                      entry: entry,
                      isCurrentUser: true,
                    ),
                  )),
              const SizedBox(height: 24),
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
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: AppColors.gradientError,
                borderRadius: BorderRadius.circular(70),
                boxShadow: PremiumShadows.error,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 70,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Queue',
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.subtle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CpButton(
              text: 'Retry',
              onPressed: () {
                context.read<QueueBloc>().add(QueueLoadRequested());
              },
              icon: Icons.refresh_rounded,
              variant: ButtonVariant.primary,
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

/// Position card showing user's queue position
class _PositionCard extends StatelessWidget {
  final int position;
  final int? petsAhead;
  final int? estimatedWaitMinutes;
  final Animation<double> pulseAnimation;

  const _PositionCard({
    required this.position,
    this.petsAhead,
    this.estimatedWaitMinutes,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: pulseAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: PremiumShadows.primary,
            ),
            child: Column(
              children: [
                Text(
                  'Your Position',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$position',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  petsAhead != null && petsAhead! > 0
                      ? '$petsAhead ${petsAhead == 1 ? 'pet' : 'pets'} ahead of you'
                      : 'You\'re next!',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                  ),
                ),
                if (estimatedWaitMinutes != null && estimatedWaitMinutes! > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
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
      },
    );
  }
}

/// Card shown when user has no pets in queue
class _EmptyQueueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      blur: 15,
      gradient: LinearGradient(
        colors: [
          isDark ? AppColors.surfaceDark.withValues(alpha: 0.8) : AppColors.surface.withValues(alpha: 0.8),
          isDark ? AppColors.surfaceDark.withValues(alpha: 0.6) : AppColors.surface.withValues(alpha: 0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
      child: Column(
        children: [
          PulsingGlow(
            glowColor: AppColors.primary,
            maxRadius: 30,
            duration: const Duration(seconds: 3),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(48),
              ),
              child: Icon(
                Icons.queue_outlined,
                size: 48,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Pets in Queue',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any pets currently checked in.\nBook an appointment and check in when you arrive.',
            style: AppTextStyles.bodyMedium.subtle.copyWith(
              height: 1.5,
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      blur: 15,
      gradient: LinearGradient(
        colors: [
          isDark ? AppColors.surfaceDark.withValues(alpha: 0.8) : AppColors.surface.withValues(alpha: 0.8),
          isDark ? AppColors.surfaceDark.withValues(alpha: 0.6) : AppColors.surface.withValues(alpha: 0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: AppColors.warning.withValues(alpha: 0.3),
      borderWidth: 2,
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(48),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 48,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Not Currently in Queue',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your pets have upcoming appointments but aren\'t checked in yet.\nCheck in when you arrive at the clinic.',
            style: AppTextStyles.bodyMedium.subtle.copyWith(
              height: 1.5,
            ),
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

  const _QueueEntryCard({
    required this.entry,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(entry.queueEntry.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FloatingAnimation(
      amplitude: 3,
      duration: const Duration(seconds: 4),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        blur: 12,
        gradient: LinearGradient(
          colors: [
            isDark ? AppColors.surfaceDark.withValues(alpha: 0.85) : AppColors.surface.withValues(alpha: 0.85),
            isDark ? AppColors.surfaceDark.withValues(alpha: 0.65) : AppColors.surface.withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderColor: isCurrentUser
            ? statusColor.withValues(alpha: 0.4)
            : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
        borderWidth: isCurrentUser ? 2 : 1,
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
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: PremiumShadows.coloredShadow(statusColor),
                  ),
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
                const SizedBox(width: 12),
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
                      Text(
                        '${entry.pet.species.displayName} • ${entry.pet.breed}',
                        style: AppTextStyles.bodySmall.subtle,
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appointment',
                          style: AppTextStyles.labelSmall.subtle,
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
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.queueEntry.estimatedWaitMinutes} min',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
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
                    radius: 16,
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
                    style: AppTextStyles.bodyMedium.subtle,
                  ),
                ],
              ),
            ],

            // Check-in time
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Checked in at ${_formatTime(entry.queueEntry.checkedInAt)}',
                      style: AppTextStyles.bodySmall.muted,
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
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Called at ${_formatTime(entry.queueEntry.calledAt!)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.info,
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
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
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

/// Queue info card with helpful information
class _QueueInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      blur: 12,
      gradient: LinearGradient(
        colors: [
          isDark ? AppColors.surfaceDark.withValues(alpha: 0.8) : AppColors.surface.withValues(alpha: 0.8),
          isDark ? AppColors.surfaceDark.withValues(alpha: 0.6) : AppColors.surface.withValues(alpha: 0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'How It Works',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.check_circle_outline_rounded,
            title: 'Check In',
            description: 'Arrive at the clinic and check in at the front desk',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.queue_outlined,
            title: 'Wait',
            description: 'Monitor your position here - you\'ll get a notification when called',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.volume_up_outlined,
            title: 'Called',
            description: 'Listen for your name or check the screen for your room number',
          ),
          const SizedBox(height: 8),
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
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary.scale(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
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
              Text(
                description,
                style: AppTextStyles.bodySmall.subtle,
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
      body: AnimatedGradientBackground(
        colors: [
          AppColors.primary.withValues(alpha: 0.05),
          AppColors.tertiary.withValues(alpha: 0.03),
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
                      Icons.queue_outlined,
                      size: 80,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
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

/// Access denied view for non-pet-owners
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
                  'This page is for pet owners only.\n\nUse the staff queue management page instead.',
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