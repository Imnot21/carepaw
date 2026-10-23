import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shapes.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';

/// Individual appointment card - the CarePaw surface system
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final Pet? pet;
  final VoidCallback onTap;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCancel;
  final bool isVetOrStaff;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.pet,
    required this.onTap,
    this.onCheckIn,
    this.onCancel,
    this.isVetOrStaff = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, appointment.status);
    final isUpcoming = appointment.isUpcoming;
    final speciesSvg = _getSpeciesSvg(pet?.species);
    final textPrimary = ThemeColors.textPrimary(context);
    final textSecondary = ThemeColors.textSecondary(context);

    return NeuCard(
      onTap: onTap,
      padding: const EdgeInsets.all(NeuTokens.spaceMd),
      margin: const EdgeInsets.only(bottom: NeuTokens.spaceMd),
      showBorder: false,
      shape: RoundedRectangleBorder(borderRadius: NeuShape.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with status and time
          Row(
            children: [
              // Status indicator dot
              NeuContainer(
                variant: NeuVariant.pressed,
                borderRadius: NeuTokens.radiusXs,
                padding: const EdgeInsets.all(NeuTokens.spaceXxs),
                child: SizedBox(
                  width: 8,
                  height: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Date & time
              Expanded(
                child: Text(
                  _formatDateTime(appointment.scheduledAt),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              // Status chip
              NeuChip(
                label: appointment.status.displayName,
                selected: true,
                selectedColor: statusColor,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pet info
          Row(
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(NeuTokens.spaceSm),
                borderRadius: NeuTokens.radiusMd,
                variant: NeuVariant.flat,
                child: NeuSvgIcon(speciesSvg, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet != null ? pet!.name : 'Pet ID: ${appointment.petId}',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    if (pet != null) ...[
                      Text(
                        '${pet!.species.displayName}${pet!.breed != null ? ' • ${pet!.breed}' : ''}',
                        style: AppTextStyles.bodySmall.subtleOf(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ] else if (appointment.veterinarianId > 0) ...[
                      Text(
                        'Dr. ID: ${appointment.veterinarianId}',
                        style: AppTextStyles.bodySmall.subtleOf(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (appointment.reason != null) ...[
            const SizedBox(height: 16),
            NeuContainer(
              padding: const EdgeInsets.all(NeuTokens.spaceMd),
              borderRadius: NeuTokens.radiusMd,
              variant: NeuVariant.flat,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NeuContainer(
                    padding: const EdgeInsets.all(NeuTokens.spaceXs),
                    borderRadius: NeuTokens.radiusSm,
                    variant: NeuVariant.flat,
                    color: ThemeColors.primary(context).withValues(alpha: 0.15),
                    child: NeuSvgIcon(SvgIcons.visit, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      appointment.reason!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Duration - only show for vet/staff
          if (isVetOrStaff) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                NeuContainer(
                  padding: const EdgeInsets.all(NeuTokens.spaceXs - 2),
                  borderRadius: NeuTokens.radiusXs,
                  variant: NeuVariant.flat,
                  child: NeuSvgIcon(SvgIcons.schedule, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  '${appointment.durationMinutes} min',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          // Action buttons for upcoming appointments - role-based
          if (isUpcoming &&
              appointment.status != AppointmentStatus.cancelled &&
              appointment.status != AppointmentStatus.noShow) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 1,
              child: NeuContainer(
                borderRadius: 0,
                variant: NeuVariant.flat,
                color: ThemeColors.border(context),
                padding: EdgeInsets.zero,
                child: const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
            if (isVetOrStaff) ...[
              // Vet/Staff actions: Check In, Start, Complete, Cancel, View
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (onCheckIn != null)
                    NeuButton(
                      text: 'Check In',
                      onPressed: onCheckIn,
                      variant: NeuButtonVariant.outline,
                      icon: Icons.check_circle_outline_rounded,
                      svgAsset: SvgIcons.success,
                      size: NeuButtonSize.medium,
                      expanded: true,
                    ),
                  if (appointment.status == AppointmentStatus.checkedIn)
                    NeuButton(
                      text: 'Start',
                      onPressed: () {
                        context.read<AppointmentBloc>().add(
                          AppointmentStartRequested(appointment.id!),
                        );
                      },
                      variant: NeuButtonVariant.outline,
                      icon: Icons.play_arrow_outlined,
                      svgAsset: SvgIcons.play,
                      size: NeuButtonSize.medium,
                      expanded: true,
                    ),
                  if (appointment.status == AppointmentStatus.inProgress)
                    NeuButton(
                      text: 'Complete',
                      onPressed: () {
                        context.read<AppointmentBloc>().add(
                          AppointmentCompleteRequested(appointment.id!),
                        );
                      },
                      variant: NeuButtonVariant.outline,
                      icon: Icons.check_circle_outlined,
                      svgAsset: SvgIcons.success,
                      size: NeuButtonSize.medium,
                      expanded: true,
                    ),
                  if (onCancel != null)
                    NeuButton(
                      text: 'Cancel',
                      onPressed: onCancel,
                      variant: NeuButtonVariant.ghost,
                      icon: Icons.cancel_outlined,
                      svgAsset: SvgIcons.error,
                      size: NeuButtonSize.medium,
                      expanded: true,
                    ),
                  NeuButton(
                    text: 'View',
                    onPressed: onTap,
                    variant: NeuButtonVariant.ghost,
                    icon: Icons.visibility_outlined,
                    svgAsset: SvgIcons.visibility,
                    size: NeuButtonSize.medium,
                    expanded: true,
                  ),
                ],
              ),
            ] else ...[
              // Pet Owner actions: Cancel, View only
              Row(
                children: [
                  if (onCancel != null) ...[
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: NeuButton(
                          text: 'Cancel',
                          onPressed: onCancel,
                          variant: NeuButtonVariant.outline,
                          icon: Icons.cancel_outlined,
                          svgAsset: SvgIcons.error,
                          size: NeuButtonSize.medium,
                          expanded: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: NeuButton(
                        text: 'View',
                        onPressed: onTap,
                        variant: NeuButtonVariant.primary,
                        icon: Icons.visibility_outlined,
                        svgAsset: SvgIcons.visibility,
                        size: NeuButtonSize.medium,
                        expanded: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ] else if (!isUpcoming) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 1,
              child: NeuContainer(
                borderRadius: 0,
                variant: NeuVariant.flat,
                color: ThemeColors.border(context),
                padding: EdgeInsets.zero,
                child: const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: NeuButton(
                text: 'View Details',
                onPressed: onTap,
                variant: NeuButtonVariant.primary,
                icon: Icons.visibility_outlined,
                svgAsset: SvgIcons.visibility,
                size: NeuButtonSize.medium,
                expanded: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.requested:
        return ThemeColors.warning(context);
      case AppointmentStatus.confirmed:
        return ThemeColors.info(context);
      case AppointmentStatus.rescheduled:
        return ThemeColors.info(context);
      case AppointmentStatus.checkedIn:
        return ThemeColors.primaryText(context);
      case AppointmentStatus.inProgress:
        return ThemeColors.progress(context);
      case AppointmentStatus.completed:
        return ThemeColors.success(context);
      case AppointmentStatus.cancelled:
        return ThemeColors.error(context);
      case AppointmentStatus.noShow:
        return ThemeColors.textSecondary(context);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final isToday =
        dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;

    if (isToday) {
      return 'Today at ${DateFormat.jm().format(dateTime)}';
    }

    final isTomorrow =
        dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day + 1;

    if (isTomorrow) {
      return 'Tomorrow at ${DateFormat.jm().format(dateTime)}';
    }

    return '${DateFormat('MMM d, y').format(dateTime)} at '
        '${DateFormat.jm().format(dateTime)}';
  }

  String _getSpeciesSvg(PetSpecies? species) {
    if (species == null) return SvgIcons.otherPet;
    return PetUtils.getSpeciesSvg(species);
  }
}