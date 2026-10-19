import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_divider.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';

/// Stats bar showing queue overview
class StatsBar extends StatelessWidget {
  final int currentServing;
  final int totalWaiting;
  final int totalInRoom;

  const StatsBar({
    super.key,
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
              svgAsset: SvgIcons.person,
              label: 'Waiting',
              value: '$totalWaiting',
              color: ThemeColors.warning(context),
            ),
          ),
          Container(width: 1, height: 44, color: ThemeColors.border(context)),
          Expanded(
            child: _StatItem(
              svgAsset: SvgIcons.door,
              label: 'In Room',
              value: '$totalInRoom',
              color: ThemeColors.primaryText(context),
            ),
          ),
          Container(width: 1, height: 44, color: ThemeColors.border(context)),
          Expanded(
            child: _StatItem(
              svgAsset: SvgIcons.volume,
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
  final String? svgAsset;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    this.svgAsset,
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
          child: svgAsset != null
              ? NeuSvgIcon(svgAsset!, size: 22)
              : const SizedBox(width: 22, height: 22),
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
class StaffQueueEntryCard extends StatelessWidget {
  final QueueEntryWithDetails entry;
  final VoidCallback? onCall;
  final VoidCallback? onMoveToRoom;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onCancel;
  final ValueChanged<QueuePriority>? onPriorityChanged;

  const StaffQueueEntryCard({
    super.key,
    required this.entry,
    this.onCall,
    this.onMoveToRoom,
    this.onComplete,
    this.onSkip,
    this.onCancel,
    this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, entry.queueEntry.status);
    final isCurrentServing =
        entry.queueEntry.position == 1 &&
        (entry.queueEntry.status == QueueStatus.waiting ||
            entry.queueEntry.status == QueueStatus.called);

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
                    ? NeuShadow.color(
                        context,
                        statusColor,
                        blur: 16,
                        opacity: 0.4,
                      )
                    : null,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Text(
                      '#${entry.queueEntry.position}',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isCurrentServing
                            ? ThemeColors.onStatus(context)
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
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
              if (onPriorityChanged != null && entry.queueEntry.id != null) ...[
                _PriorityControl(
                  priority: entry.queueEntry.priority,
                  onChanged: onPriorityChanged,
                ),
                const SizedBox(width: 8),
              ],

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
                NeuContainer(
                  borderRadius: 10,
                  padding: const EdgeInsets.all(8),
                  variant: NeuVariant.flat,
                  color: ThemeColors.primary(context).withValues(alpha: 0.12),
                  child: NeuSvgIcon(SvgIcons.visit, size: 18),
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
                    child: NeuSvgIcon(SvgIcons.schedule, size: 18),
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
                  backgroundColor: ThemeColors.primary(
                    context,
                  ).withValues(alpha: 0.15),
                  foregroundColor: ThemeColors.primaryText(context),
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
              NeuSvgIcon(SvgIcons.schedule, size: 14),
              const SizedBox(width: 6),
              Text(
                'Checked in: ${_formatTime(entry.queueEntry.checkedInAt)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
              ),
              if (entry.queueEntry.calledAt != null) ...[
                const SizedBox(width: 16),
                NeuSvgIcon(SvgIcons.volume, size: 14),
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
                NeuSvgIcon(SvgIcons.door, size: 14),
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
          NeuDivider(thickness: 1),
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
            svgAsset: SvgIcons.volume,
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
            svgAsset: SvgIcons.door,
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
            svgAsset: SvgIcons.check,
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
            svgAsset: SvgIcons.skipNext,
            variant: NeuButtonVariant.destructive,
            size: NeuButtonSize.medium,
            expanded: true,
          ),
        ),
      );
    }

    if (onCancel != null) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: NeuButton(
            text: 'Cancel',
            onPressed: onCancel!,
            icon: Icons.cancel_outlined,
            svgAsset: SvgIcons.error,
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
        return ThemeColors.primaryText(context);
      case QueueStatus.completed:
        return ThemeColors.success(context);
      case QueueStatus.cancelled:
        return ThemeColors.error(context);
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

/// Triage control: a color-coded priority chip that opens a menu to change the
/// entry's clinical priority (Routine / Urgent / Emergency).
class _PriorityControl extends StatelessWidget {
  final QueuePriority priority;
  final ValueChanged<QueuePriority>? onChanged;

  const _PriorityControl({required this.priority, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: QueuePriority.values.map((p) {
        final isSelected = priority == p;
        final color = _priorityColor(context, p);
        return NeuChip(
          label: p.displayName,
          svgAsset: _svgFor(p),
          selected: isSelected,
          selectedColor: color,
          onTap: () => onChanged?.call(p),
          unselectedVariant: NeuVariant.raised,
        );
      }).toList(),
    );
  }

  static String _svgFor(QueuePriority p) {
    switch (p) {
      case QueuePriority.emergency:
        return SvgIcons.alert;
      case QueuePriority.urgent:
        return SvgIcons.alert;
      case QueuePriority.routine:
        return SvgIcons.success;
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

/// Not logged in view
class StaffNotLoggedInView extends StatelessWidget {
  const StaffNotLoggedInView({super.key});

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
                boxShadow: NeuShadow.color(
                  context,
                  ThemeColors.primary(context),
                  blur: 24,
                  opacity: 0.32,
                ),
                child: NeuSvgIcon(SvgIcons.people, size: 80),
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
                svgAsset: SvgIcons.login,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Access denied view for pet owners
class StaffAccessDeniedView extends StatelessWidget {
  const StaffAccessDeniedView({super.key});

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
                boxShadow: NeuShadow.color(
                  context,
                  ThemeColors.error(context),
                  blur: 24,
                  opacity: 0.32,
                ),
                child: NeuSvgIcon(SvgIcons.block, size: 80),
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
                svgAsset: SvgIcons.back,
                variant: NeuButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
