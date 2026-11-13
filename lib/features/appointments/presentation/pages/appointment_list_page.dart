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
import 'package:carepaw/core/widgets/neomorphism/neu_state.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
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
    return BlocListener<AppointmentBloc, AppointmentState>(
      listenWhen: (_, state) => state is AppointmentStatusUpdated,
      listener: (context, state) =>
          NeuToast.success(context, 'Booking updated.'),
      child: Scaffold(
        backgroundColor: ThemeColors.background(context),
        appBar: _buildAppBar(),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: NeuTokens.maxContentWidth,
            ),
            child: Column(
              children: [
                const SizedBox(height: NeuTokens.spaceXs),
                // Search bar
                _buildSearchBar(),
                const SizedBox(height: NeuTokens.spaceMd),
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
                                padding: const EdgeInsets.fromLTRB(
                                  NeuTokens.pagePadding,
                                  0,
                                  NeuTokens.pagePadding,
                                  NeuTokens.spaceMd,
                                ),
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
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _isVetOrStaff ? 'All bookings' : 'Appointments',
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
      padding: const EdgeInsets.symmetric(horizontal: NeuTokens.pagePadding),
      child: NeuTextField(
        controller: _searchController,
        hint: 'Search by pet or service',
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
    final chips = [
      NeuChip(
        label: 'Upcoming',
        selected: _tabController.index == 0,
        selectedColor: ThemeColors.primary(context),
        onTap: () => _tabController.animateTo(0),
      ),
      NeuChip(
        label: 'Past',
        selected: _tabController.index == 1,
        selectedColor: ThemeColors.primary(context),
        onTap: () => _tabController.animateTo(1),
      ),
    ];
    // At large text sizes the two chips no longer fit in equal halves, so
    // they take their natural width and wrap instead.
    final wrap = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NeuTokens.pagePadding),
      child: wrap
          ? Wrap(
              spacing: NeuTokens.tightGap,
              runSpacing: NeuTokens.spaceXs,
              children: chips,
            )
          : Row(
              children: [
                Expanded(child: chips[0]),
                const SizedBox(width: NeuTokens.tightGap),
                Expanded(child: chips[1]),
              ],
            ),
    );
  }

  Widget _buildNewAppointmentButton() {
    // Primary, medium, leading + icon. Full width so it fits both the centered
    // empty-state CTA and the bottom footer.
    return NeuButton(
      text: 'Book a visit',
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
          return _buildErrorState(isUpcoming);
        }

        if (state is AppointmentLoaded) {
          final appointments = isUpcoming
              ? state.upcomingAppointments
              : state.pastAppointments;
          final appointmentsWithPetDetails = isUpcoming
              ? state.upcomingWithPetDetails
              : state.pastWithPetDetails;

          // Apply search filter
          // Map of appointment ID to pet details for quick lookup
          final petDetailsMap = _petMap(appointmentsWithPetDetails);
          final filtered = _filterAppointments(appointments, petDetailsMap);

          if (filtered.isEmpty) {
            return _searchActive && appointments.isNotEmpty
                ? const NeuEmptyState(
                    icon: Icons.search_off_rounded,
                    svgAsset: SvgIcons.searchOff,
                    title: 'No matches',
                    message: 'Try a different pet name or service.',
                  )
                : _buildEmptyState(isUpcoming);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AppointmentBloc>().add(
                AppointmentRefreshRequested(),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                NeuTokens.pagePadding,
                0,
                NeuTokens.pagePadding,
                96,
              ),
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

  bool get _searchActive => _searchController.text.trim().isNotEmpty;

  Map<int, Pet> _petMap(List<AppointmentWithPetDetails> details) => {
    for (final d in details)
      if (d.appointment.id != null) d.appointment.id!: d.pet,
  };

  List<Appointment> _filterAppointments(
    List<Appointment> appointments,
    Map<int, Pet> pets,
  ) {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return appointments;

    bool has(String? text) => text?.toLowerCase().contains(query) ?? false;
    return appointments
        .where(
          (a) =>
              has(pets[a.id]?.name) ||
              has(a.service) ||
              has(a.reason) ||
              has(a.notes),
        )
        .toList();
  }

  Widget _buildEmptyState(bool isUpcoming) {
    // One empty-state treatment app-wide (NeuEmptyState): a recessed disc,
    // a sentence-case title, one line on what goes here.
    final ownerCanBook = isUpcoming && !_isVetOrStaff;
    return NeuEmptyState(
      icon: isUpcoming ? Icons.calendar_today_outlined : Icons.history,
      svgAsset: SvgIcons.calendar,
      title: isUpcoming ? 'Nothing booked yet' : 'No past visits',
      message: isUpcoming
          ? (_isVetOrStaff
                ? 'New bookings from pet owners show up here.'
                : 'Your next visit to PILA VET HUB will show up here.')
          : 'Finished and cancelled visits are kept here.',
      actionLabel: ownerCanBook ? 'Book a visit' : null,
      onAction: ownerCanBook ? _navigateToCreateAppointment : null,
    );
  }

  Widget _buildErrorState(bool isUpcoming) {
    return NeuErrorState(
      title: "Couldn't load bookings",
      message: 'Check your connection and try again.',
      svgAsset: SvgIcons.error,
      onRetry: () =>
          context.read<AppointmentBloc>().add(AppointmentRefreshRequested()),
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
    final isUpcoming = _tabController.index == 0;
    final list = isUpcoming
        ? state.upcomingAppointments
        : state.pastAppointments;
    final pets = _petMap(
      isUpcoming ? state.upcomingWithPetDetails : state.pastWithPetDetails,
    );
    return _filterAppointments(list, pets).isEmpty;
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
      cancelText: 'Not now',
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
          text: 'Keep booking',
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
    ).whenComplete(reasonController.dispose);
  }
}
