import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shapes.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';

/// Appointment list page showing upcoming and past appointments with
/// neumorphic design.
/// Role-based UI: Pet owners see their appointments, Vets/Staff see all/assigned
class AppointmentListPage extends StatefulWidget {
  const AppointmentListPage({super.key});

  @override
  State<AppointmentListPage> createState() => _AppointmentListPageState();
}

class _AppointmentListPageState extends State<AppointmentListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  bool _isVetOrStaff = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Re-evaluate whether the active tab is empty when the user switches tabs,
    // so the create button shows in the right place.
    _tabController.addListener(_onTabChanged);

    // Determine user role from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _isVetOrStaff = authState.user.role == UserRole.veterinarian ||
          authState.user.role == UserRole.staff ||
          authState.user.role == UserRole.admin;
    }

    // Load appointments when page initializes
    context.read<AppointmentBloc>().add(AppointmentLoadRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Search bar
          _buildSearchBar(),
          const SizedBox(height: 16),
          // Tab bar
          _buildTabBar(),
          // Tab content
          Expanded(
            child: Stack(
              children: [
                TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppointmentList(isUpcoming: true),
                    _buildAppointmentList(isUpcoming: false),
                  ],
                ),
                // Create footer (owners only), shown when the active tab has
                // items. Empty tabs show the button inside the empty state
                // instead, so it reads as a centered call to action. A
                // BlocBuilder keeps this in sync with the live appointment state.
                if (!_isVetOrStaff)
                  BlocBuilder<AppointmentBloc, AppointmentState>(
                    builder: (context, state) {
                      if (_isCurrentTabEmpty(state)) {
                        return const SizedBox.shrink();
                      }
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: _buildNewAppointmentButton(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _isVetOrStaff ? 'All Appointments' : 'Appointments',
        style: AppTextStyles.headlineSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: ThemeColors.textPrimary(context),
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      // Reload happens via pull-to-refresh (RefreshIndicator) instead of a button.
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: NeuTextField(
        controller: _searchController,
        hint: 'Search appointments...',
        prefixIcon: Icon(
          Icons.search_rounded,
          color: ThemeColors.textSecondary(context),
          size: 24,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? NeuIconButton(
                icon: Icons.clear_rounded,
                size: 22,
                color: ThemeColors.textSecondary(context),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                tooltip: 'Clear search',
              )
            : null,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: NeuContainer(
        padding: const EdgeInsets.all(4),
        borderRadius: 14,
        variant: NeuVariant.raised,
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: NeuShadow.color(
              context,
              AppColors.primary,
              blur: 10,
              opacity: 0.3,
            ),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: ThemeColors.textSecondary(context),
          labelStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w500),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
    );
  }

  Widget _buildNewAppointmentButton() {
    // Primary, medium, leading + icon. Full width so it fits both the centered
    // empty-state CTA and the bottom footer.
    return NeuButton(
      text: 'New Appointment',
      onPressed: _navigateToCreateAppointment,
      icon: Icons.add,
      variant: NeuButtonVariant.primary,
      size: NeuButtonSize.medium,
      expanded: true,
    );
  }

  Widget _buildAppointmentList({required bool isUpcoming}) {
    return BlocBuilder<AppointmentBloc, AppointmentState>(
      builder: (context, state) {
        if (state is AppointmentLoading) {
          return const NeuSkeletonList();
        }

        if (state is AppointmentError) {
          return _buildErrorState(state.message, isUpcoming);
        }

        if (state is AppointmentLoaded) {
          final appointments = isUpcoming
              ? state.upcomingAppointments
              : state.pastAppointments;
          final appointmentsWithPetDetails = isUpcoming
              ? state.upcomingWithPetDetails
              : state.pastWithPetDetails;

          // Apply search filter
          final filtered = _filterAppointments(appointments);

          if (filtered.isEmpty) {
            return _buildEmptyState(isUpcoming);
          }

          // Create a map of appointment ID to pet details for quick lookup
          final petDetailsMap = <int, Pet>{};
          for (final detail in appointmentsWithPetDetails) {
            petDetailsMap[detail.appointment.id!] = detail.pet;
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AppointmentBloc>().add(AppointmentRefreshRequested());
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final appointment = filtered[index];
                final pet = petDetailsMap[appointment.id!];
                return _AppointmentCard(
                  appointment: appointment,
                  pet: pet,
                  onTap: () => _navigateToDetail(appointment),
                  onCheckIn: appointment.canCheckIn
                      ? () => _showCheckInDialog(appointment)
                      : null,
                  onCancel: appointment.canCancel
                      ? () => _showCancelDialog(appointment)
                      : null,
                  isVetOrStaff: _isVetOrStaff,
                );
              },
            ),
          );
        }

        return _buildEmptyState(isUpcoming);
      },
    );
  }

  List<Appointment> _filterAppointments(List<Appointment> appointments) {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return appointments;

    return appointments.where((a) {
      // We need pet info for searching - for now just search by reason/notes
      return (a.reason?.toLowerCase().contains(query) ?? false) ||
          (a.notes?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Widget _buildEmptyState(bool isUpcoming) {
    final accent = isUpcoming ? AppColors.primary : AppColors.success;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: NeuContainer(
                borderRadius: 70,
                variant: NeuVariant.raised,
                color: accent,
                boxShadow: NeuShadow.color(
                  context,
                  accent,
                  blur: 24,
                  opacity: 0.32,
                ),
                child: Icon(
                  isUpcoming ? Icons.calendar_today_outlined : Icons.history_outlined,
                  size: 70,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              isUpcoming ? 'No Upcoming Appointments' : 'No Past Appointments',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: ThemeColors.textPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              isUpcoming
                  ? (_isVetOrStaff
                      ? 'No upcoming appointments found. Appointments will appear here as they are scheduled.'
                      : 'Request your first appointment to get started.\nYour upcoming visits will appear here.')
                  : 'Completed and cancelled appointments will appear here.',
              style: AppTextStyles.bodyLarge.subtleOf(Theme.of(context).brightness).copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
            // Owners get a centered create button here (this whole column is
            // vertically centered, so the button reads as the center CTA).
            if (!_isVetOrStaff) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: _buildNewAppointmentButton(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, bool isUpcoming) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: NeuContainer(
                borderRadius: 70,
                variant: NeuVariant.raised,
                color: AppColors.error,
                boxShadow: NeuShadow.color(
                  context,
                  AppColors.error,
                  blur: 24,
                  opacity: 0.32,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 70,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Failed to Load Appointments',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: ThemeColors.textPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: AppTextStyles.bodyMedium.subtleOf(Theme.of(context).brightness),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: NeuButton(
                text: 'Retry',
                onPressed: () {
                  context.read<AppointmentBloc>().add(AppointmentRefreshRequested());
                },
                icon: Icons.refresh_rounded,
                variant: NeuButtonVariant.primary,
                expanded: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  /// Whether the currently selected tab has no appointments (after search),
  /// so the create button lives in the centered empty state rather than at the
  /// bottom footer.
  bool _isCurrentTabEmpty(AppointmentState state) {
    if (state is! AppointmentLoaded) return false;
    final list = _tabController.index == 0
        ? state.upcomingAppointments
        : state.pastAppointments;
    return _filterAppointments(list).isEmpty;
  }

  void _navigateToCreateAppointment() {
    context.go(Routes.appointmentRequest);
  }

  void _navigateToDetail(Appointment appointment) {
    context.go('/appointments/${appointment.id}');
  }

  void _showCheckInDialog(Appointment appointment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ThemeColors.background(dialogContext),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            NeuContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: 12,
              variant: NeuVariant.flat,
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: ThemeColors.success(dialogContext),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Check In',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: ThemeColors.textPrimary(dialogContext),
              ),
            ),
          ],
        ),
        content: Text(
          'Check in for ${appointment.reason ?? 'this appointment'}?',
          style: AppTextStyles.bodyLarge.copyWith(
            color: ThemeColors.textPrimary(dialogContext),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(
                color: ThemeColors.textSecondary(dialogContext),
              ),
            ),
          ),
          NeuButton(
            text: 'Check In',
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AppointmentBloc>().add(
                AppointmentCheckInRequested(appointment.id!),
              );
            },
            variant: NeuButtonVariant.primary,
            icon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Appointment appointment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ThemeColors.background(dialogContext),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            NeuContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: 12,
              variant: NeuVariant.flat,
              child: Icon(Icons.cancel_outlined, color: ThemeColors.error(dialogContext), size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Cancel Appointment',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: ThemeColors.textPrimary(dialogContext),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this appointment?',
              style: AppTextStyles.bodyLarge.copyWith(
                color: ThemeColors.textPrimary(dialogContext),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            NeuTextField(
              controller: reasonController,
              label: 'Cancellation Reason (optional)',
              hint: 'Enter reason...',
              maxLines: 3,
              helper: 'This helps us improve our service',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'No',
              style: AppTextStyles.labelLarge.copyWith(
                color: ThemeColors.textSecondary(dialogContext),
              ),
            ),
          ),
          NeuButton(
            text: 'Yes, Cancel',
            variant: NeuButtonVariant.destructive,
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AppointmentBloc>().add(
                AppointmentCancelRequested(
                  appointment.id!,
                  reasonController.text.trim(),
                ),
              );
            },
            icon: Icons.cancel_rounded,
          ),
        ],
      ),
    );
  }
}

/// Individual appointment card - neumorphic design
class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final Pet? pet;
  final VoidCallback onTap;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCancel;
  final bool isVetOrStaff;

  const _AppointmentCard({
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
    final speciesColor = _getSpeciesColor(pet?.species);
    final speciesIcon = _getSpeciesIcon(pet?.species);
    final textPrimary = ThemeColors.textPrimary(context);
    final textSecondary = ThemeColors.textSecondary(context);

    return NeuCard(
      onTap: onTap,
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      borderColor: statusColor.withValues(alpha: isUpcoming ? 0.35 : 0.2),
      borderWidth: 1.5,
      shape: RoundedRectangleBorder(borderRadius: NeuShape.cardFlow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with status and time
          Row(
            children: [
              // Status indicator dot
              NeuContainer(
                borderRadius: 8,
                variant: NeuVariant.raised,
                color: statusColor,
                padding: const EdgeInsets.all(4),
                boxShadow: NeuShadow.color(context, statusColor, blur: 8, opacity: 0.4),
                child: const SizedBox(width: 8, height: 8),
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
                padding: const EdgeInsets.all(12),
                borderRadius: 14,
                variant: NeuVariant.flat,
                child: Icon(speciesIcon, color: speciesColor, size: 24),
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
                        style: AppTextStyles.bodySmall.subtleOf(Theme.of(context).brightness),
                      ),
                    ] else if (appointment.veterinarianId > 0) ...[
                      Text(
                        'Dr. ID: ${appointment.veterinarianId}',
                        style: AppTextStyles.bodySmall.subtleOf(Theme.of(context).brightness),
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
              padding: const EdgeInsets.all(14),
              borderRadius: 14,
              variant: NeuVariant.flat,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NeuContainer(
                    padding: const EdgeInsets.all(8),
                    borderRadius: 10,
                    variant: NeuVariant.flat,
                    color: ThemeColors.primary(context).withValues(alpha: 0.15),
                    child: Icon(
                      Icons.medical_services_outlined,
                      size: 18,
                      color: ThemeColors.primary(context),
                    ),
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
                  padding: const EdgeInsets.all(6),
                  borderRadius: 8,
                  variant: NeuVariant.flat,
                  child: Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: ThemeColors.textSecondary(context),
                  ),
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
                      size: NeuButtonSize.medium,
                      expanded: true,
                    ),
                  if (onCancel != null)
                    NeuButton(
                      text: 'Cancel',
                      onPressed: onCancel,
                      variant: NeuButtonVariant.ghost,
                      icon: Icons.cancel_outlined,
                      size: NeuButtonSize.medium,
                      expanded: true,
                    ),
                  NeuButton(
                    text: 'View',
                    onPressed: onTap,
                    variant: NeuButtonVariant.ghost,
                    icon: Icons.visibility_outlined,
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
        return ThemeColors.primaryLight(context);
      case AppointmentStatus.checkedIn:
        return ThemeColors.primary(context);
      case AppointmentStatus.inProgress:
        return AppColors.tertiary;
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
    final isToday = dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;

    if (isToday) {
      return 'Today at ${DateFormat.jm().format(dateTime)}';
    }

    final isTomorrow = dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day + 1;

    if (isTomorrow) {
      return 'Tomorrow at ${DateFormat.jm().format(dateTime)}';
    }

    return DateFormat('MMM d, y \'at\' jm').format(dateTime);
  }

  Color _getSpeciesColor(PetSpecies? species) {
    switch (species) {
      case PetSpecies.dog:
        return AppColors.dogAccent;
      case PetSpecies.cat:
        return AppColors.catAccent;
      case PetSpecies.bird:
        return AppColors.birdAccent;
      case PetSpecies.rabbit:
        return AppColors.rabbitAccent;
      case PetSpecies.reptile:
        return Colors.green;
      case PetSpecies.other:
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  IconData _getSpeciesIcon(PetSpecies? species) {
    switch (species) {
      case PetSpecies.dog:
        return Icons.pets;
      case PetSpecies.cat:
        return Icons.pets_outlined;
      case PetSpecies.bird:
        return Icons.flutter_dash;
      case PetSpecies.rabbit:
        return Icons.landscape_outlined;
      case PetSpecies.reptile:
        return Icons.eco_outlined;
      case PetSpecies.other:
        return Icons.help_outline;
      default:
        return Icons.pets;
    }
  }
}