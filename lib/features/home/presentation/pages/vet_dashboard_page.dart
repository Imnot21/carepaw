import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_loader.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart'
    show GlassContainer;
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';
import 'package:carepaw/core/widgets/effects/scale_on_tap.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Veterinarian Dashboard - Clinical features for veterinarians
/// Only accessible by VETERINARIAN and ADMIN roles
class VetDashboardPage extends StatefulWidget {
  const VetDashboardPage({super.key});

  @override
  State<VetDashboardPage> createState() => _VetDashboardPageState();
}

class _VetDashboardPageState extends State<VetDashboardPage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

  final List<_VetNavItem> _navItems = const [
    _VetNavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Dashboard', route: Routes.vetDashboard),
    _VetNavItem(icon: Icons.people_outlined, selectedIcon: Icons.people, label: 'My Patients', route: Routes.vetPatients),
    _VetNavItem(icon: Icons.medical_services_outlined, selectedIcon: Icons.medical_services, label: 'Records', route: Routes.vetRecords),
    _VetNavItem(icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today, label: 'Schedule', route: Routes.vetDashboard),
  ];

  Future<void> _exportDatabase() async {
    try {
      // Request storage permission (Android 13+)
      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          final status2 = await Permission.storage.request();
          if (!status2.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Storage permission denied')),
              );
            }
            return;
          }
        }
      }

      // Get app database
      final appDir = await getApplicationDocumentsDirectory();
      final dbFile = File('${appDir.path}/carepaw.sqlite');

      if (!await dbFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('DB not found: ${dbFile.path}')),
          );
        }
        return;
      }

      // Copy to Downloads (accessible from Windows File Explorer)
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        // Fallback for scoped storage
        final extDir = await getExternalStorageDirectory();
        final destFile = File('${extDir!.path}/carepaw_export.sqlite');
        await dbFile.copy(destFile.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Exported to: ${destFile.path}')),
          );
        }
        return;
      }

      final destFile = File('${downloadsDir.path}/carepaw_export.sqlite');
      await dbFile.copy(destFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Exported to Downloads/carepaw_export.sqlite')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(Routes.login);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const _LoadingView();
          }

          final user = authState.user;
          final isVetOrAdmin = user.role == UserRole.veterinarian || user.role == UserRole.admin;

          if (!isVetOrAdmin) {
            return const _AccessDeniedView();
          }

          return AnimatedGradientBackground(
            colors: [
              AppColors.success.withValues(alpha: 0.05),
              AppColors.primary.withValues(alpha: 0.03),
            ],
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              body: IndexedStack(
                index: _currentIndex,
                children: [
                  _VetDashboardContent(user: user, onExportDatabase: _exportDatabase),
                  _VetPatientsTab(),
                  _VetRecordsTab(),
                  _VetScheduleTab(),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() => _currentIndex = index);
                },
                destinations: _navItems.map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                )).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CpLoader(size: 32, strokeWidth: 3),
            const SizedBox(height: 16),
            Text('Loading...', style: AppTextStyles.bodyMedium.subtle),
          ],
        ),
      ),
    );
  }
}

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
                    child: const Icon(Icons.block_rounded, size: 80, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 28),
                Text('Access Denied', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.error), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text('This area is for veterinarians only.\n\nUse the appropriate dashboard for your role.', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                CpButton(text: 'Go Back', onPressed: () => context.pop(), icon: Icons.arrow_back_rounded, variant: ButtonVariant.secondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VetNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const _VetNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}

/// Main veterinarian dashboard content
class _VetDashboardContent extends StatelessWidget {
  final dynamic user;
  final VoidCallback onExportDatabase;

  const _VetDashboardContent({required this.user, required this.onExportDatabase});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userName = user?.fullName?.split(' ')?.first ?? 'Doctor';

        return CustomScrollView(
          slivers: [
            // App bar with greeting
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good ${_getGreeting()}, Dr. $userName!',
                    style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    'Veterinarian Dashboard',
                    style: AppTextStyles.bodySmall.subtle,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push(Routes.notifications),
                  tooltip: 'Notifications',
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push(Routes.settings),
                  tooltip: 'Settings',
                ),
                // Export DB button (debug)
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: onExportDatabase,
                  tooltip: 'Export Database to Downloads',
                ),
              ],
            ),

            // Main content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's Patients Stats
                    _VetStatsSection(),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _VetQuickActionsSection(),
                    const SizedBox(height: 24),

                    // Today's Schedule Preview
                    _VetSchedulePreviewSection(),
                    const SizedBox(height: 24),

                    // Quick Links
                    _VetQuickLinksSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

/// Stats cards for vet
class _VetStatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Get real data from repository
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today\'s Patients', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _VetStatCard(label: 'Scheduled', value: '8', icon: Icons.calendar_today_outlined, color: AppColors.primary, subtitle: 'appointments')),
            const SizedBox(width: 12),
            Expanded(child: _VetStatCard(label: 'Checked In', value: '3', icon: Icons.check_circle_outlined, color: AppColors.success, subtitle: 'waiting')),
            const SizedBox(width: 12),
            Expanded(child: _VetStatCard(label: 'In Progress', value: '1', icon: Icons.medical_services_outlined, color: AppColors.warning, subtitle: 'consultation')),
          ],
        ),
      ],
    );
  }
}

class _VetStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _VetStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: () {},
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        blur: 12,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderColor: color.withValues(alpha: 0.3),
        borderWidth: 1.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(subtitle, style: AppTextStyles.bodySmall.muted),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(label, style: AppTextStyles.bodySmall.subtle),
          ],
        ),
      ),
    );
  }
}

/// Quick actions for veterinarian
class _VetQuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Clinical Actions', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            _VetActionCard(
              icon: Icons.note_add_outlined,
              label: 'New\nVisit Record',
              color: AppColors.primary,
              onTap: () => _showComingSoon(context, 'New Visit Record'),
            ),
            _VetActionCard(
              icon: Icons.medication_outlined,
              label: 'Prescribe\nMedication',
              color: AppColors.success,
              onTap: () => _showComingSoon(context, 'Prescribe Medication'),
            ),
            _VetActionCard(
              icon: Icons.vaccines_outlined,
              label: 'Add\nVaccination',
              color: AppColors.info,
              onTap: () => _showComingSoon(context, 'Add Vaccination'),
            ),
            _VetActionCard(
              icon: Icons.science_outlined,
              label: 'Order\nLab Tests',
              color: Colors.purple,
              onTap: () => _showComingSoon(context, 'Order Lab Tests'),
            ),
            _VetActionCard(
              icon: Icons.note_add_outlined,
              label: 'Clinical\nNotes',
              color: AppColors.secondary,
              onTap: () => _showComingSoon(context, 'Clinical Notes'),
            ),
            _VetActionCard(
              icon: Icons.attach_file_outlined,
              label: 'Attach\nResults',
              color: Colors.teal,
              onTap: () => _showComingSoon(context, 'Attach Results'),
            ),
            _VetActionCard(
              icon: Icons.history_outlined,
              label: 'Patient\nHistory',
              color: Colors.orange,
              onTap: () => context.push(Routes.vetPatients),
            ),
            _VetActionCard(
              icon: Icons.print_outlined,
              label: 'Generate\nSummary',
              color: Colors.indigo,
              onTap: () => _showComingSoon(context, 'Generate Summary'),
            ),
          ],
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!'), behavior: SnackBarBehavior.floating),
    );
  }
}

class _VetActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _VetActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: color, height: 1.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's schedule preview
class _VetSchedulePreviewSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Get real data from appointments repository
    final mockAppointments = [
      _MockAppointment(time: '09:00', petName: 'Buddy', species: 'Dog', owner: 'John S.', reason: 'Annual checkup', status: 'checked-in'),
      _MockAppointment(time: '10:30', petName: 'Whiskers', species: 'Cat', owner: 'Maria L.', reason: 'Vaccination', status: 'waiting'),
      _MockAppointment(time: '14:00', petName: 'Max', species: 'Dog', owner: 'Robert K.', reason: 'Follow-up', status: 'scheduled'),
      _MockAppointment(time: '15:30', petName: 'Luna', species: 'Rabbit', owner: 'Sarah M.', reason: 'Dental check', status: 'scheduled'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Today\'s Schedule', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => context.push(Routes.vetPatients),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...mockAppointments.map((appt) => _VetScheduleItem(appointment: appt)),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => context.push(Routes.vetPatients),
            child: Text('+ ${mockAppointments.length - 4} more appointments'),
          ),
        ),
      ],
    );
  }
}

class _MockAppointment {
  final String time;
  final String petName;
  final String species;
  final String owner;
  final String reason;
  final String status;

  const _MockAppointment({
    required this.time,
    required this.petName,
    required this.species,
    required this.owner,
    required this.reason,
    required this.status,
  });
}

class _VetScheduleItem extends StatelessWidget {
  final _MockAppointment appointment;

  const _VetScheduleItem({required this.appointment});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'checked-in':
        return AppColors.success;
      case 'waiting':
        return AppColors.warning;
      case 'in-progress':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'checked-in':
        return Icons.check_circle_outlined;
      case 'waiting':
        return Icons.schedule_outlined;
      case 'in-progress':
        return Icons.medical_services_outlined;
      default:
        return Icons.calendar_today_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(appointment.status);
    final statusIcon = _getStatusIcon(appointment.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final speciesIcon = _getSpeciesIcon(appointment.species);
    final speciesColor = _getSpeciesColor(appointment.species);

    return ScaleOnTap(
      onTap: () => _showComingSoon(context, 'Open Patient Record'),
      child: GlassContainer(
        borderRadius: 12,
        padding: const EdgeInsets.all(14),
        blur: 10,
        gradient: LinearGradient(
          colors: [
            isDark ? AppColors.surfaceDark.withValues(alpha: 0.85) : AppColors.surface.withValues(alpha: 0.85),
            isDark ? AppColors.surfaceDark.withValues(alpha: 0.65) : AppColors.surface.withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderColor: statusColor.withValues(alpha: 0.3),
        borderWidth: 1,
        child: Row(
          children: [
            // Time
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                appointment.time,
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            // Pet avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [speciesColor.withValues(alpha: 0.2), speciesColor.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(speciesIcon, color: speciesColor, size: 24),
            ),
            const SizedBox(width: 12),
            // Pet info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appointment.petName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  Text('${appointment.species} • Owner: ${appointment.owner}', style: AppTextStyles.bodySmall.subtle),
                  Text(appointment.reason, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            // Status
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(_formatStatus(appointment.status), style: AppTextStyles.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'checked-in':
        return 'Checked In';
      case 'waiting':
        return 'Waiting';
      case 'in-progress':
        return 'In Progress';
      default:
        return 'Scheduled';
    }
  }

  IconData _getSpeciesIcon(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets_outlined;
      case 'bird':
        return Icons.flutter_dash;
      case 'rabbit':
        return Icons.landscape_outlined;
      case 'reptile':
        return Icons.eco_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _getSpeciesColor(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return AppColors.dogAccent;
      case 'cat':
        return AppColors.catAccent;
      case 'bird':
        return AppColors.birdAccent;
      case 'rabbit':
        return AppColors.rabbitAccent;
      case 'reptile':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature coming soon!'), behavior: SnackBarBehavior.floating));
  }
}

/// Quick links for vet
class _VetQuickLinksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('More', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GlassContainer(
          borderRadius: 20,
          blur: 15,
          padding: EdgeInsets.zero,
          borderColor: Theme.of(context).brightness == Brightness.dark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
          child: Column(
            children: [
              _LinkTile(icon: Icons.notifications_outlined, title: 'Notifications', subtitle: 'Lab results & alerts', onTap: () => context.push(Routes.notifications)),
              const Divider(height: 1, indent: 56),
              _LinkTile(icon: Icons.medical_services_outlined, title: 'Medical Records', subtitle: 'Full patient history access', onTap: () => context.push(Routes.medicalRecords)),
              const Divider(height: 1, indent: 56),
              _LinkTile(icon: Icons.inventory_2_outlined, title: 'Medicine Catalog', subtitle: 'Available medications & dosages', onTap: () => _showComingSoon(context, 'Medicine Catalog')),
              const Divider(height: 1, indent: 56),
              _LinkTile(icon: Icons.settings_outlined, title: 'Settings', subtitle: 'App preferences', onTap: () => context.push(Routes.settings)),
            ],
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature coming soon!'), behavior: SnackBarBehavior.floating));
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(gradient: AppColors.gradientPrimary.scale(0.2), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall.subtle),
      trailing: Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}

/// Placeholder tabs for vet
class _VetPatientsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PlaceholderTab(title: 'My Patients', icon: Icons.people_outlined, actionText: 'View Patients', actionRoute: Routes.vetPatients);
  }
}

class _VetRecordsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PlaceholderTab(title: 'Medical Records', icon: Icons.medical_services_outlined, actionText: 'Open Records', actionRoute: Routes.medicalRecords);
  }
}

class _VetScheduleTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PlaceholderTab(title: 'Schedule', icon: Icons.calendar_today_outlined, actionText: 'View Schedule', actionRoute: Routes.vetDashboard);
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final String actionText;
  final String actionRoute;

  const _PlaceholderTab({required this.title, required this.icon, required this.actionText, required this.actionRoute});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true, elevation: 0, scrolledUnderElevation: 0, backgroundColor: Colors.transparent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 140, height: 140, decoration: BoxDecoration(gradient: AppColors.gradientSuccess, borderRadius: BorderRadius.circular(70), boxShadow: PremiumShadows.coloredShadow(AppColors.success)), child: Icon(icon, size: 70, color: Colors.white)),
            const SizedBox(height: 24),
            Text(title, style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Coming soon!', style: AppTextStyles.bodyMedium.subtle),
            const SizedBox(height: 16),
            CpButton(text: actionText, onPressed: () => context.push(actionRoute), variant: ButtonVariant.primary, icon: Icons.add),
          ],
        ),
      ),
    );
  }
}