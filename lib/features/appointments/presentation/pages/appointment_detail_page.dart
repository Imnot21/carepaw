import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_loader.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/core/widgets/effects/floating_animation.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';
import 'package:carepaw/core/widgets/effects/scale_on_tap.dart';

/// Appointment detail page showing full appointment information
class AppointmentDetailPage extends StatefulWidget {
  final int appointmentId;

  const AppointmentDetailPage({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  @override
  void initState() {
    super.initState();
    // Trigger loading the appointment detail
    context.read<AppointmentBloc>().add(AppointmentDetailLoadRequested(widget.appointmentId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Appointment Details'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            boxShadow: PremiumShadows.level(context, 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ScaleOnTap(
              onTap: _navigateToEdit,
              child: CpIconButton(
                icon: Icons.edit_outlined,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
                tooltip: 'Edit',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ScaleOnTap(
              onTap: _showDeleteConfirmation,
              child: CpIconButton(
                icon: Icons.delete_outline_rounded,
                size: 24,
                color: AppColors.error,
                tooltip: 'Delete',
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
        child: BlocBuilder<AppointmentBloc, AppointmentState>(
          builder: (context, state) {
            if (state is AppointmentLoading) {
              return const Center(child: CpLoader(size: 32));
            } else if (state is AppointmentDetailLoaded) {
              return _buildAppointmentDetail(state.appointmentWithDetails);
            } else if (state is AppointmentError) {
              return _buildError(state.message);
            }
            // Fallback - show loading
            return const Center(child: CpLoader(size: 32));
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentDetail(AppointmentWithDetails appointment) {
    final pet = appointment.pet;
    final status = appointment.appointment.status;
    final statusInfo = _getStatusInfo(status);
    final speciesColor = PetUtils.getSpeciesColor(pet.species);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header with status badge
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          sliver: SliverToBoxAdapter(
            child: FloatingAnimation(
              delay: const Duration(milliseconds: 100),
              child: Column(
                children: [
                  // Status badge with PulsingGlow for active states
                  statusInfo.isActive
                      ? PulsingGlow(
                          glowColor: statusInfo.color,
                          maxRadius: 20,
                          duration: const Duration(seconds: 2),
                          child: _buildStatusBadge(statusInfo),
                        )
                      : _buildStatusBadge(statusInfo),
                  const SizedBox(height: 24),
                  // Pet avatar with species color
                  PulsingGlow(
                    glowColor: speciesColor,
                    maxRadius: 25,
                    duration: const Duration(seconds: 3),
                    child: PetUtils.buildAvatar(
                      species: pet.species,
                      radius: 50,
                      iconSize: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    pet.name,
                    style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.species.displayName}${pet.breed != null ? ' • ${pet.breed}' : ''}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (pet.ageInYears != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${pet.ageInYears} years old',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Sections
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.separated(
            itemCount: 4, // Vet, Details, Reason, Notes
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return FloatingAnimation(
                delay: Duration(milliseconds: 80 * (index + 1)),
                child: _buildSectionCard(context, index, appointment, speciesColor),
              );
            },
          ),
        ),

        // Action buttons
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          sliver: SliverToBoxAdapter(
            child: FloatingAnimation(
              delay: const Duration(milliseconds: 400),
              child: _buildActionButtons(appointment.appointment),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(_StatusInfo statusInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: statusInfo.gradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: PremiumShadows.glow(context, statusInfo.color, intensity: 0.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo.icon, color: statusInfo.textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            statusInfo.label,
            style: AppTextStyles.titleMedium.copyWith(
              color: statusInfo.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.requested:
        return _StatusInfo(
          label: 'Requested',
          icon: Icons.pending_outlined,
          color: AppColors.warning,
          textColor: AppColors.warningDark,
          gradient: LinearGradient(
            colors: [AppColors.warning.withValues(alpha: 0.2), AppColors.warning.withValues(alpha: 0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          isActive: false,
        );
      case AppointmentStatus.confirmed:
        return _StatusInfo(
          label: 'Confirmed',
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.info,
          textColor: AppColors.info,
          gradient: LinearGradient(
            colors: [AppColors.info.withValues(alpha: 0.2), AppColors.info.withValues(alpha: 0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          isActive: true,
        );
      case AppointmentStatus.checkedIn:
        return _StatusInfo(
          label: 'Checked In',
          icon: Icons.login_outlined,
          color: AppColors.primary,
          textColor: AppColors.primary,
          gradient: AppColors.gradientPrimary,
          isActive: true,
        );
      case AppointmentStatus.inProgress:
        return _StatusInfo(
          label: 'In Progress',
          icon: Icons.medical_services_outlined,
          color: AppColors.primaryLight,
          textColor: AppColors.primaryLight,
          gradient: LinearGradient(
            colors: [AppColors.primaryLight.withValues(alpha: 0.2), AppColors.primaryLight.withValues(alpha: 0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          isActive: true,
        );
      case AppointmentStatus.completed:
        return _StatusInfo(
          label: 'Completed',
          icon: Icons.task_alt_outlined,
          color: AppColors.success,
          textColor: AppColors.success,
          gradient: AppColors.gradientSuccess,
          isActive: false,
        );
      case AppointmentStatus.cancelled:
        return _StatusInfo(
          label: 'Cancelled',
          icon: Icons.cancel_outlined,
          color: AppColors.error,
          textColor: AppColors.error,
          gradient: LinearGradient(
            colors: [AppColors.error.withValues(alpha: 0.2), AppColors.error.withValues(alpha: 0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          isActive: false,
        );
      case AppointmentStatus.noShow:
        return _StatusInfo(
          label: 'No Show',
          icon: Icons.person_off_outlined,
          color: AppColors.textSecondary,
          textColor: AppColors.textSecondary,
          gradient: LinearGradient(
            colors: [AppColors.textSecondary.withValues(alpha: 0.2), AppColors.textSecondary.withValues(alpha: 0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          isActive: false,
        );
    }
  }

  Widget _buildSectionCard(
    BuildContext context,
    int index,
    AppointmentWithDetails appointment,
    Color speciesColor,
  ) {
    switch (index) {
      case 0:
        return _buildVeterinarianCard(context, appointment.veterinarian, speciesColor);
      case 1:
        return _buildDetailCard(context, appointment.appointment, speciesColor);
      case 2:
        if ((appointment.appointment.reason?.isNotEmpty ?? false)) {
          return _buildInfoCard(context, 'Reason for Visit', appointment.appointment.reason!, Icons.description_rounded, AppColors.success);
        }
        return const SizedBox.shrink();
      case 3:
        if ((appointment.appointment.notes?.isNotEmpty ?? false)) {
          return _buildInfoCard(context, 'Notes', appointment.appointment.notes!, Icons.note_alt_rounded, AppColors.textSecondary);
        }
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildVeterinarianCard(BuildContext context, User vet, Color speciesColor) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      blur: 20,
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.glassBorderDark
          : AppColors.glassBorderLight,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.medical_services_rounded,
              size: 28,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Veterinarian',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dr. ${vet.fullName}',
                  style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
                ),
                if (vet.phone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        vet.phone!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      vet.email,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, Appointment appointment, Color speciesColor) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      blur: 20,
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.glassBorderDark
          : AppColors.glassBorderLight,
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _formatDate(appointment.scheduledAt),
            iconColor: speciesColor,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: _formatTime(appointment.scheduledAt),
            iconColor: speciesColor,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.timer_rounded,
            label: 'Duration',
            value: '${appointment.durationMinutes} minutes',
            iconColor: speciesColor,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.event_rounded,
            label: 'Created',
            value: _formatDateTime(appointment.createdAt),
            iconColor: speciesColor,
          ),
          if (appointment.updatedAt != appointment.createdAt) ...[
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.update_rounded,
              label: 'Last Updated',
              value: _formatDateTime(appointment.updatedAt),
              iconColor: speciesColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String content, IconData icon, Color iconColor) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      blur: 20,
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.glassBorderDark
          : AppColors.glassBorderLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Appointment appointment) {
    final canEdit = !appointment.isTerminal;
    final canCheckIn = appointment.status == AppointmentStatus.confirmed;
    final canStart = appointment.status == AppointmentStatus.checkedIn;
    final canComplete = appointment.status == AppointmentStatus.inProgress;
    final canCancel = !appointment.isTerminal && appointment.status != AppointmentStatus.cancelled;

    return Column(
      children: [
        if (canEdit)
          ScaleOnTap(
            onTap: _navigateToEdit,
            child: CpButton(
              text: 'Edit Appointment',
              onPressed: _navigateToEdit,
              expanded: true,
              icon: Icons.edit_rounded,
              variant: ButtonVariant.primary,
              size: ButtonSize.large,
            ),
          ),
        if (canEdit) const SizedBox(height: 10),
        if (canCheckIn)
          ScaleOnTap(
            onTap: () => _updateStatus(AppointmentStatus.checkedIn),
            child: CpButton(
              text: 'Check In',
              onPressed: () => _updateStatus(AppointmentStatus.checkedIn),
              expanded: true,
              icon: Icons.login_rounded,
              variant: ButtonVariant.secondary,
              size: ButtonSize.large,
            ),
          ),
        if (canCheckIn) const SizedBox(height: 10),
        if (canStart)
          ScaleOnTap(
            onTap: () => _updateStatus(AppointmentStatus.inProgress),
            child: CpButton(
              text: 'Start Consultation',
              onPressed: () => _updateStatus(AppointmentStatus.inProgress),
              expanded: true,
              icon: Icons.medical_services_rounded,
              variant: ButtonVariant.primary,
              size: ButtonSize.large,
            ),
          ),
        if (canStart) const SizedBox(height: 10),
        if (canComplete)
          ScaleOnTap(
            onTap: () => _updateStatus(AppointmentStatus.completed),
            child: CpButton(
              text: 'Complete Appointment',
              onPressed: () => _updateStatus(AppointmentStatus.completed),
              expanded: true,
              icon: Icons.task_alt_rounded,
              variant: ButtonVariant.primary,
              size: ButtonSize.large,
            ),
          ),
        if (canComplete) const SizedBox(height: 10),
        if (canCancel)
          ScaleOnTap(
            onTap: _showCancelDialog,
            child: CpButton(
              text: 'Cancel Appointment',
              onPressed: _showCancelDialog,
              expanded: true,
              icon: Icons.cancel_rounded,
              variant: ButtonVariant.destructive,
              size: ButtonSize.large,
            ),
          ),
      ],
    );
  }

  void _updateStatus(AppointmentStatus status) {
    context.read<AppointmentBloc>().add(
      AppointmentStatusUpdateRequested(widget.appointmentId, status),
    );
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_rounded, size: 22, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Text('Cancel Appointment', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason for cancellation...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ScaleOnTap(
            onTap: () {
              Navigator.pop(context);
              context.read<AppointmentBloc>().add(
                AppointmentCancelRequested(widget.appointmentId, reasonController.text.trim()),
              );
            },
            child: CpButton(
              text: 'Confirm Cancellation',
              onPressed: () {
                Navigator.pop(context);
                context.read<AppointmentBloc>().add(
                  AppointmentCancelRequested(widget.appointmentId, reasonController.text.trim()),
                );
              },
              variant: ButtonVariant.destructive,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit() {
    context.go('/appointments/${widget.appointmentId}/edit');
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Text('Delete Appointment', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text('Are you sure you want to delete this appointment? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ScaleOnTap(
            onTap: () {
              Navigator.pop(context);
              context.read<AppointmentBloc>().add(AppointmentDeleteRequested(widget.appointmentId));
              context.pop(); // Go back to list
            },
            child: CpButton(
              text: 'Delete',
              onPressed: () {
                Navigator.pop(context);
                context.read<AppointmentBloc>().add(AppointmentDeleteRequested(widget.appointmentId));
                context.pop(); // Go back to list
              },
              variant: ButtonVariant.destructive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
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
              'Error Loading Appointment',
              style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w700),
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
              onTap: () => context.read<AppointmentBloc>().add(AppointmentDetailLoadRequested(widget.appointmentId)),
              child: CpButton(
                text: 'Retry',
                onPressed: () => context.read<AppointmentBloc>().add(AppointmentDetailLoadRequested(widget.appointmentId)),
                icon: Icons.refresh_rounded,
                variant: ButtonVariant.primary,
              ),
            ),
            const SizedBox(height: 12),
            ScaleOnTap(
              onTap: () => context.pop(),
              child: CpButton(
                text: 'Back',
                onPressed: () => context.pop(),
                icon: Icons.arrow_back_rounded,
                variant: ButtonVariant.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} at ${_formatTime(date)}';
  }
}

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Gradient gradient;
  final bool isActive;

  const _StatusInfo({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.gradient,
    required this.isActive,
  });
}

/// Appointment detail page with BLoC provider for full details
class AppointmentDetailPageWithBloc extends StatelessWidget {
  final int appointmentId;

  const AppointmentDetailPageWithBloc({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppointmentBloc(
        repository: getIt<AppointmentRepositoryImpl>(),
        authBloc: context.read<AuthBloc>(),
      )..add(AppointmentDetailLoadRequested(appointmentId)),
      child: AppointmentDetailPage(appointmentId: appointmentId),
    );
  }
}