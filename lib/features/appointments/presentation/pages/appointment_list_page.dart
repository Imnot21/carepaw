import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_medallion.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/features/appointments/presentation/widgets/appointment_list_widgets.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';

/// Appointment list page showing upcoming and past appointments with
/// the CarePaw surface system.
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
      _isVetOrStaff = authState.user.isOwnerAdmin;
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
        prefixIcon: ClayIconOrMaterial(
          'search_rounded',
          fallback: Icons.search_rounded,
          size: 24,
          color: ThemeColors.textSecondary(context),
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? NeuIconButton(
                icon: Icons.clear_rounded,
                svgAsset: SvgIcons.close,
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
      child: Row(
        children: [
          Expanded(
            child: NeuChip(
              label: 'Upcoming',
              selected: _tabController.index == 0,
              selectedColor: AppColors.primary,
              onTap: () => _tabController.animateTo(0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: NeuChip(
              label: 'Past',
              selected: _tabController.index == 1,
              selectedColor: AppColors.primary,
              onTap: () => _tabController.animateTo(1),
            ),
          ),
        ],
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
      svgAsset: SvgIcons.add,
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
              context.read<AppointmentBloc>().add(
                AppointmentRefreshRequested(),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final appointment = filtered[index];
                final pet = petDetailsMap[appointment.id!];
                return AppointmentCard(
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
            NeuMedallion(
              radius: 70,
              color: accent,
              child: ClayIconOrMaterial(
                isUpcoming ? 'calendar_today_outlined' : 'history_outlined',
                fallback: isUpcoming
                    ? Icons.calendar_today_outlined
                    : Icons.history_outlined,
                size: 56,
                color: accent,
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
              style: AppTextStyles.bodyLarge
                  .subtleOf(Theme.of(context).brightness)
                  .copyWith(height: 1.6),
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
            NeuMedallion(
              radius: 70,
              color: ThemeColors.error(context),
              child: ClayIconOrMaterial(
                'error_outline_rounded',
                fallback: Icons.error_outline_rounded,
                size: 56,
                color: ThemeColors.error(context),
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
              style: AppTextStyles.bodyMedium.subtleOf(
                Theme.of(context).brightness,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: NeuButton(
                text: 'Retry',
                onPressed: () {
                  context.read<AppointmentBloc>().add(
                    AppointmentRefreshRequested(),
                  );
                },
                icon: Icons.refresh_rounded,
                svgAsset: SvgIcons.refresh,
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
    NeuConfirmDialog.show(
      context: context,
      title: 'Check In',
      message: 'Check in for ${appointment.reason ?? 'this appointment'}?',
      confirmText: 'Check In',
      cancelText: 'Cancel',
      confirmVariant: NeuButtonVariant.primary,
      onConfirm: () => context.read<AppointmentBloc>().add(
        AppointmentCheckInRequested(appointment.id!),
      ),
    );
  }

  void _showCancelDialog(Appointment appointment) {
    final reasonController = TextEditingController();
    NeuDialog.show(
      context: context,
      title: 'Cancel Appointment',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to cancel this appointment?',
            style: AppTextStyles.bodyLarge.copyWith(
              color: ThemeColors.textPrimary(context),
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
        NeuButton(
          text: 'No',
          variant: NeuButtonVariant.ghost,
          onPressed: () => context.pop(),
        ),
        NeuButton(
          text: 'Yes, Cancel',
          variant: NeuButtonVariant.destructive,
          icon: Icons.cancel_rounded,
          svgAsset: SvgIcons.error,
          onPressed: () {
            context.pop();
            context.read<AppointmentBloc>().add(
              AppointmentCancelRequested(
                appointment.id!,
                reasonController.text.trim(),
              ),
            );
          },
        ),
      ],
    );
  }
}
