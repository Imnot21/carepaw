import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/app/theme/theme_colors.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shapes.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_divider.dart';

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
    context.read<AppointmentBloc>().add(
      AppointmentDetailLoadRequested(widget.appointmentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      appBar: AppBar(
        title: Text(
          'Appointment details',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: ThemeColors.surface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: NeuIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
        actions: [
          NeuIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit',
            onPressed: _navigateToEdit,
          ),
          NeuIconButton(
            icon: Icons.delete_outline_rounded,
            color: ThemeColors.error(context),
            tooltip: 'Delete',
            onPressed: _showDeleteConfirmation,
          ),
          const SizedBox(width: NeuTokens.spaceXs),
        ],
      ),
      body: BlocBuilder<AppointmentBloc, AppointmentState>(
        builder: (context, state) {
          if (state is AppointmentLoading) {
            return const Center(child: NeuCircularProgress(size: 32));
          } else if (state is AppointmentDetailLoaded) {
            return _buildAppointmentDetail(state.appointmentWithDetails);
          } else if (state is AppointmentError) {
            return _buildError(state.message);
          }
          return const Center(child: NeuCircularProgress(size: 32));
        },
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
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStatusBadge(statusInfo),
                const SizedBox(height: 24),
                NeuAvatar(
                  radius: 50,
                  icon: PetUtils.getSpeciesIcon(pet.species),
                  backgroundColor: PetUtils.getSpeciesColor(
                    pet.species,
                  ).withValues(alpha: 0.2),
                  foregroundColor: PetUtils.getSpeciesColor(pet.species),
                ),
                const SizedBox(height: 16),
                Text(
                  pet.name,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.species.displayName}${pet.breed != null ? ' - ${pet.breed}' : ''}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                ),
                if (pet.ageInYears != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${pet.ageInYears} years old',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ThemeColors.textSecondary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.separated(
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) =>
                _buildSectionCard(context, index, appointment, speciesColor),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          sliver: SliverToBoxAdapter(
            child: _buildActionButtons(appointment.appointment),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(_StatusInfo statusInfo) {
    return NeuContainer(
      borderRadius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: statusInfo.color.withValues(alpha: 0.15),
      boxShadow: NeuShadow.none,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo.icon, color: statusInfo.color, size: 20),
          const SizedBox(width: 8),
          Text(
            statusInfo.label,
            style: AppTextStyles.titleMedium.copyWith(
              color: statusInfo.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(AppointmentStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case AppointmentStatus.requested:
        final color = isDark ? AppColors.warningOnDark : AppColors.warning;
        return _StatusInfo(
          label: 'Requested',
          icon: Icons.pending_outlined,
          color: color,
          isActive: false,
        );
      case AppointmentStatus.confirmed:
        final color = isDark ? AppColors.infoDark : AppColors.info;
        return _StatusInfo(
          label: 'Confirmed',
          icon: Icons.check_circle_outline_rounded,
          color: color,
          isActive: true,
        );
      case AppointmentStatus.checkedIn:
        final color = ThemeColors.primary(context);
        return _StatusInfo(
          label: 'Checked In',
          icon: Icons.login_outlined,
          color: color,
          isActive: true,
        );
      case AppointmentStatus.inProgress:
        final color = isDark ? AppColors.primaryOnDark : AppColors.primaryLight;
        return _StatusInfo(
          label: 'In Progress',
          icon: Icons.medical_services_outlined,
          color: color,
          isActive: true,
        );
      case AppointmentStatus.completed:
        final color = isDark ? AppColors.successOnDark : AppColors.success;
        return _StatusInfo(
          label: 'Completed',
          icon: Icons.task_alt_outlined,
          color: color,
          isActive: false,
        );
      case AppointmentStatus.cancelled:
        final color = isDark ? AppColors.errorOnDark : AppColors.error;
        return _StatusInfo(
          label: 'Cancelled',
          icon: Icons.cancel_outlined,
          color: color,
          isActive: false,
        );
      case AppointmentStatus.noShow:
        return _StatusInfo(
          label: 'No Show',
          icon: Icons.person_off_outlined,
          color: ThemeColors.textSecondary(context),
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
        return _buildVeterinarianCard(
          context,
          appointment.veterinarian,
          speciesColor,
        );
      case 1:
        return _buildDetailCard(context, appointment.appointment, speciesColor);
      case 2:
        if ((appointment.appointment.reason?.isNotEmpty ?? false)) {
          return _buildInfoCard(
            context,
            'Reason for Visit',
            appointment.appointment.reason!,
            Icons.description_rounded,
            ThemeColors.success(context),
          );
        }
        return const SizedBox.shrink();
      case 3:
        if ((appointment.appointment.notes?.isNotEmpty ?? false)) {
          return _buildInfoCard(
            context,
            'Notes',
            appointment.appointment.notes!,
            Icons.note_alt_rounded,
            ThemeColors.textSecondary(context),
          );
        }
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildVeterinarianCard(
    BuildContext context,
    User vet,
    Color speciesColor,
  ) {
    return NeuCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: NeuShape.card),
      child: Row(
        children: [
          NeuContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(12),
            variant: NeuVariant.flat,
            color: ThemeColors.primary(context).withValues(alpha: 0.15),
            child: Icon(
              Icons.medical_services_rounded,
              size: 28,
              color: ThemeColors.primary(context),
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
                    color: ThemeColors.textSecondary(context),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dr. ${vet.fullName}',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (vet.phone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: ThemeColors.textSecondary(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vet.phone!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: ThemeColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: ThemeColors.textSecondary(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      vet.email,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: ThemeColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    Appointment appointment,
    Color speciesColor,
  ) {
    return NeuCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _formatDate(appointment.scheduledAt),
            iconColor: speciesColor,
          ),
          NeuDivider(thickness: 1, indent: 0, endIndent: 0),
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: _formatTime(appointment.scheduledAt),
            iconColor: speciesColor,
          ),
          NeuDivider(thickness: 1, indent: 0, endIndent: 0),
          _buildDetailRow(
            icon: Icons.timer_rounded,
            label: 'Duration',
            value: '${appointment.durationMinutes} minutes',
            iconColor: speciesColor,
          ),
          NeuDivider(thickness: 1, indent: 0, endIndent: 0),
          _buildDetailRow(
            icon: Icons.event_rounded,
            label: 'Created',
            value: _formatDateTime(appointment.createdAt),
            iconColor: speciesColor,
          ),
          if (appointment.updatedAt != appointment.createdAt) ...[
            NeuDivider(thickness: 1, indent: 0, endIndent: 0),
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
        NeuContainer(
          padding: const EdgeInsets.all(10),
          borderRadius: 12,
          variant: NeuVariant.flat,
          color: iconColor.withValues(alpha: 0.15),
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
                  color: ThemeColors.textSecondary(context),
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

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color iconColor,
  ) {
    return NeuCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: NeuShape.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(10),
                borderRadius: 12,
                variant: NeuVariant.flat,
                color: iconColor.withValues(alpha: 0.15),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(content, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Appointment appointment) {
    final canEdit = !appointment.isTerminal;
    final canCheckIn = appointment.status == AppointmentStatus.confirmed;
    final canStart = appointment.status == AppointmentStatus.checkedIn;
    final canComplete = appointment.status == AppointmentStatus.inProgress;
    final canCancel =
        !appointment.isTerminal &&
        appointment.status != AppointmentStatus.cancelled;

    return Column(
      children: [
        if (canEdit) ...[
          NeuButton(
            text: 'Edit Appointment',
            onPressed: _navigateToEdit,
            expanded: true,
            icon: Icons.edit_rounded,
            variant: NeuButtonVariant.primary,
            size: NeuButtonSize.medium,
          ),
          const SizedBox(height: 10),
        ],
        if (canCheckIn) ...[
          NeuButton(
            text: 'Check In',
            onPressed: () => _updateStatus(AppointmentStatus.checkedIn),
            expanded: true,
            icon: Icons.login_rounded,
            variant: NeuButtonVariant.secondary,
            size: NeuButtonSize.medium,
          ),
          const SizedBox(height: 10),
        ],
        if (canStart) ...[
          NeuButton(
            text: 'Start Consultation',
            onPressed: () => _updateStatus(AppointmentStatus.inProgress),
            expanded: true,
            icon: Icons.medical_services_rounded,
            variant: NeuButtonVariant.primary,
            size: NeuButtonSize.medium,
          ),
          const SizedBox(height: 10),
        ],
        if (canComplete) ...[
          NeuButton(
            text: 'Complete Appointment',
            onPressed: () => _updateStatus(AppointmentStatus.completed),
            expanded: true,
            icon: Icons.task_alt_rounded,
            variant: NeuButtonVariant.primary,
            size: NeuButtonSize.medium,
          ),
          const SizedBox(height: 10),
        ],
        if (canCancel)
          NeuButton(
            text: 'Cancel Appointment',
            onPressed: _showCancelDialog,
            expanded: true,
            icon: Icons.cancel_rounded,
            variant: NeuButtonVariant.destructive,
            size: NeuButtonSize.medium,
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
    NeuDialog.show(
      context: context,
      title: 'Cancel Appointment',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please provide a reason for cancellation:'),
          const SizedBox(height: 16),
          NeuTextField(
            controller: reasonController,
            label: 'Reason for cancellation',
            hint: 'Reason for cancellation...',
            maxLines: 3,
            minLines: 2,
          ),
        ],
      ),
      actions: [
        NeuButton(
          text: 'Cancel',
          variant: NeuButtonVariant.ghost,
          onPressed: () => context.pop(),
        ),
        NeuButton(
          text: 'Confirm Cancellation',
          variant: NeuButtonVariant.destructive,
          onPressed: () {
            context.pop();
            context.read<AppointmentBloc>().add(
              AppointmentCancelRequested(
                widget.appointmentId,
                reasonController.text.trim(),
              ),
            );
          },
        ),
      ],
    );
  }

  void _navigateToEdit() {
    context.go('/appointments/${widget.appointmentId}/edit');
  }

  void _showDeleteConfirmation() {
    NeuConfirmDialog.show(
      context: context,
      title: 'Delete Appointment',
      message:
          'Are you sure you want to delete this appointment? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmVariant: NeuButtonVariant.destructive,
      onConfirm: () {
        context.read<AppointmentBloc>().add(
          AppointmentDeleteRequested(widget.appointmentId),
        );
        context.pop();
      },
    );
  }

  Widget _buildError(String message) {
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
                Icons.error_outline_rounded,
                size: 48,
                color: ThemeColors.error(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error loading appointment',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            NeuButton(
              text: 'Retry',
              onPressed: () => context.read<AppointmentBloc>().add(
                AppointmentDetailLoadRequested(widget.appointmentId),
              ),
              icon: Icons.refresh_rounded,
              variant: NeuButtonVariant.primary,
            ),
            const SizedBox(height: 12),
            NeuButton(
              text: 'Back',
              onPressed: () => context.pop(),
              icon: Icons.arrow_back_rounded,
              variant: NeuButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDateTime(DateTime date) =>
      '${_formatDate(date)} at ${_formatTime(date)}';
}

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;

  const _StatusInfo({
    required this.label,
    required this.icon,
    required this.color,
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
        repository: getIt<AppointmentRepository>(),
        authBloc: context.read<AuthBloc>(),
      )..add(AppointmentDetailLoadRequested(appointmentId)),
      child: AppointmentDetailPage(appointmentId: appointmentId),
    );
  }
}
