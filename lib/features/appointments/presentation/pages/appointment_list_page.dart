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
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_text_field.dart';
import 'package:carepaw/core/widgets/common/cp_loader.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/effects/index.dart';

/// Appointment list page showing upcoming and past appointments with premium design
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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isVetOrStaff = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();

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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      colors: [
        AppColors.primary.withValues(alpha: 0.05),
        AppColors.tertiary.withValues(alpha: 0.03),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Search bar
                _buildSearchBar(),
                const SizedBox(height: 16),
                // Tab bar
                _buildTabBar(),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAppointmentList(isUpcoming: true),
                      _buildAppointmentList(isUpcoming: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _isVetOrStaff ? 'All Appointments' : 'Appointments',
        style: AppTextStyles.headlineSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        GlassContainer(
          borderRadius: 14,
          padding: const EdgeInsets.all(10),
          blur: 15,
          margin: const EdgeInsets.only(right: 16),
          borderColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.glassBorderDark
              : AppColors.glassBorderLight,
          child: IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.primary, size: 22),
            onPressed: () {
              context.read<AppointmentBloc>().add(AppointmentRefreshRequested());
            },
            tooltip: 'Refresh',
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        blur: 15,
        borderColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.glassBorderDark
            : AppColors.glassBorderLight,
        child: TextField(
          controller: _searchController,
          style: AppTextStyles.bodyLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Search appointments...',
            hintStyle: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textHint,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    tooltip: 'Clear search',
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassContainer(
        borderRadius: 14,
        padding: const EdgeInsets.all(4),
        blur: 15,
        borderColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.glassBorderDark
            : AppColors.glassBorderLight,
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: PremiumShadows.coloredShadow(AppColors.primary),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w500),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    // Only pet owners can create new appointments from this page
    // Vets/Staff manage appointments from their dashboards
    if (_isVetOrStaff) return const SizedBox.shrink();

    return ScaleOnTap(
      onTap: _navigateToCreateAppointment,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: PremiumShadows.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available_rounded, size: 22, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'New Appointment',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList({required bool isUpcoming}) {
    return BlocBuilder<AppointmentBloc, AppointmentState>(
      builder: (context, state) {
        if (state is AppointmentLoading) {
          return const Center(child: CpLoader(size: 32, strokeWidth: 3));
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final appointment = filtered[index];
                final pet = petDetailsMap[appointment.id!];
                return FloatingAnimation(
                  delay: Duration(milliseconds: 80 * index),
                  child: _AppointmentCard(
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
                  ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingAnimation(
              child: PulsingGlow(
                glowColor: isUpcoming ? AppColors.primary : AppColors.tertiary,
                maxRadius: 25,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: isUpcoming ? AppColors.gradientPrimary : AppColors.gradientSuccess,
                    borderRadius: BorderRadius.circular(70),
                    boxShadow: isUpcoming ? PremiumShadows.primary : PremiumShadows.success,
                  ),
                  child: Icon(
                    isUpcoming ? Icons.calendar_today_outlined : Icons.history_outlined,
                    size: 70,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              isUpcoming
                  ? (_isVetOrStaff ? 'No Upcoming Appointments' : 'No Upcoming Appointments')
                  : 'No Past Appointments',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
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
              style: AppTextStyles.bodyLarge.subtle.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
            if (isUpcoming && !_isVetOrStaff) ...[
              const SizedBox(height: 36),
              CpButton(
                text: 'Request Appointment',
                onPressed: _navigateToCreateAppointment,
                icon: Icons.event_available_rounded,
                size: ButtonSize.large,
                expanded: true,
                variant: ButtonVariant.primary,
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
            FloatingAnimation(
              child: Container(
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
            ),
            const SizedBox(height: 28),
            Text(
              'Failed to Load Appointments',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: AppTextStyles.bodyMedium.subtle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            CpButton(
              text: 'Retry',
              onPressed: () {
                context.read<AppointmentBloc>().add(AppointmentRefreshRequested());
              },
              icon: Icons.refresh_rounded,
              variant: ButtonVariant.primary,
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateAppointment() {
    context.go(Routes.appointmentRequest);
  }

  void _navigateToDetail(Appointment appointment) {
    context.go('${Routes.appointmentDetail}/${appointment.id}');
  }

  void _showCheckInDialog(Appointment appointment) {
    showDialog(
      context: context,
      builder: (dialogContext) => _PremiumDialog(
        title: 'Check In',
        content: Text(
          'Check in for ${appointment.reason ?? 'this appointment'}?',
          style: AppTextStyles.bodyLarge,
        ),
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppColors.success,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: AppTextStyles.labelLarge),
          ),
          CpButton(
            text: 'Check In',
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AppointmentBloc>().add(AppointmentCheckInRequested(appointment.id!));
            },
            variant: ButtonVariant.primary,
            icon: Icons.check_circle_rounded,
            expanded: true,
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Appointment appointment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => _PremiumDialog(
          title: 'Cancel Appointment',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to cancel this appointment?',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CpTextField(
                controller: reasonController,
                label: 'Cancellation Reason (optional)',
                hint: 'Enter reason...',
                maxLines: 3,
                helper: 'This helps us improve our service',
              ),
            ],
          ),
          icon: Icons.cancel_outlined,
          iconColor: AppColors.error,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No', style: AppTextStyles.labelLarge),
            ),
            CpButton(
              text: 'Yes, Cancel',
              variant: ButtonVariant.destructive,
              onPressed: () {
                Navigator.pop(context);
                context.read<AppointmentBloc>().add(
                  AppointmentCancelRequested(appointment.id!, reasonController.text.trim()),
                );
              },
              icon: Icons.cancel_rounded,
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium dialog with glassmorphism styling
class _PremiumDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final IconData icon;
  final Color iconColor;
  final List<Widget> actions;

  const _PremiumDialog({
    required this.title,
    required this.content,
    required this.icon,
    required this.iconColor,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        blur: 25,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.glassBorderDark
            : AppColors.glassBorderLight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.2),
                    iconColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 24),
            Row(
              children: actions
                  .map((action) => Expanded(child: action))
                  .expand((widget) => [widget, const SizedBox(width: 12)])
                  .take(actions.length * 2 - 1)
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual appointment card - premium design
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
    final statusColor = _getStatusColor(appointment.status);
    final isUpcoming = appointment.isUpcoming;
    final speciesColor = _getSpeciesColor(pet?.species);
    final speciesIcon = _getSpeciesIcon(pet?.species);

    return ScaleOnTap(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(18),
        blur: 15,
        margin: const EdgeInsets.only(bottom: 14),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderColor: statusColor.withValues( alpha: isUpcoming ? 0.3 : 0.15),
        borderWidth: 1.5,
        boxShadow: isUpcoming
            ? [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with status and time
            Row(
              children: [
                // Status indicator dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Date & time
                Expanded(
                  child: Text(
                    _formatDateTime(appointment.scheduledAt),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withValues(alpha: 0.2),
                        statusColor.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    appointment.status.displayName,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pet info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        speciesColor.withValues(alpha: 0.25),
                        speciesColor.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                        ),
                      ),
                      if (pet != null) ...[
                        Text(
                          '${pet!.species.displayName}${pet!.breed != null ? ' • ${pet!.breed}' : ''}',
                          style: AppTextStyles.bodySmall.subtle,
                        ),
                      ] else if (appointment.veterinarianId > 0) ...[
                        Text(
                          'Dr. ID: ${appointment.veterinarianId}',
                          style: AppTextStyles.bodySmall.subtle,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            if (appointment.reason != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.medical_services_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        appointment.reason!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${appointment.durationMinutes} min',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Theme.of(context).colorScheme.outlineVariant,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isVetOrStaff) ...[
                // Vet/Staff actions: Check In, Start, Complete, Cancel, View
                Row(
                  children: [
                    if (onCheckIn != null) ...[
                      Expanded(
                        child: CpButton(
                          text: 'Check In',
                          onPressed: onCheckIn,
                          variant: ButtonVariant.outline,
                          icon: Icons.check_circle_outline_rounded,
                          size: ButtonSize.medium,
                          textStyle: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (appointment.status == AppointmentStatus.checkedIn) ...[
                      Expanded(
                        child: CpButton(
                          text: 'Start',
                          onPressed: () {
                            context.read<AppointmentBloc>().add(
                              AppointmentStartRequested(appointment.id!),
                            );
                          },
                          variant: ButtonVariant.outline,
                          icon: Icons.play_arrow_outlined,
                          size: ButtonSize.medium,
                          textStyle: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.tertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (appointment.status == AppointmentStatus.inProgress) ...[
                      Expanded(
                        child: CpButton(
                          text: 'Complete',
                          onPressed: () {
                            context.read<AppointmentBloc>().add(
                              AppointmentCompleteRequested(appointment.id!),
                            );
                          },
                          variant: ButtonVariant.outline,
                          icon: Icons.check_circle_outlined,
                          size: ButtonSize.medium,
                          textStyle: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (onCancel != null) ...[
                      Expanded(
                        child: CpButton(
                          text: 'Cancel',
                          onPressed: onCancel,
                          variant: ButtonVariant.outline,
                          icon: Icons.cancel_outlined,
                          size: ButtonSize.medium,
                          textStyle: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: CpButton(
                        text: 'View',
                        onPressed: onTap,
                        variant: ButtonVariant.ghost,
                        icon: Icons.visibility_outlined,
                        size: ButtonSize.medium,
                        textStyle: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Pet Owner actions: Cancel, View only
                Row(
                  children: [
                    if (onCancel != null) ...[
                      Expanded(
                        child: CpButton(
                          text: 'Cancel',
                          onPressed: onCancel,
                          variant: ButtonVariant.outline,
                          icon: Icons.cancel_outlined,
                          size: ButtonSize.medium,
                          textStyle: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: CpButton(
                        text: 'View',
                        onPressed: onTap,
                        variant: ButtonVariant.primary,
                        icon: Icons.visibility_outlined,
                        size: ButtonSize.medium,
                        expanded: true,
                      ),
                    ),
                  ],
                ),
              ],
            ] else if (!isUpcoming) ...[
              const SizedBox(height: 16),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Theme.of(context).colorScheme.outlineVariant,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CpButton(
                      text: 'View Details',
                      onPressed: onTap,
                      variant: ButtonVariant.primary,
                      icon: Icons.visibility_outlined,
                      size: ButtonSize.medium,
                      expanded: true,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.requested:
        return AppColors.warning;
      case AppointmentStatus.confirmed:
        return AppColors.info;
      case AppointmentStatus.checkedIn:
        return AppColors.primary;
      case AppointmentStatus.inProgress:
        return AppColors.tertiary;
      case AppointmentStatus.completed:
        return AppColors.success;
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.noShow:
        return AppColors.textSecondary;
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