import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_bloc.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_event.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_state.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_loader.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';
import 'package:carepaw/core/widgets/effects/scale_on_tap.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Staff Dashboard - Clinic staff management features
/// Only accessible by STAFF and ADMIN roles
class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

  final List<_StaffNavItem> _navItems = const [
    _StaffNavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Dashboard', route: Routes.staffDashboard),
    _StaffNavItem(icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today, label: 'Appointments', route: Routes.staffAppointments),
    _StaffNavItem(icon: Icons.queue_outlined, selectedIcon: Icons.queue, label: 'Queue', route: Routes.staffQueue),
    _StaffNavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: 'Inventory', route: Routes.staffInventory),
    _StaffNavItem(icon: Icons.scanner_outlined, selectedIcon: Icons.scanner, label: 'Scanning', route: Routes.staffScanning),
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
          final isStaffOrAdmin = user.role == UserRole.staff || user.role == UserRole.admin;

          if (!isStaffOrAdmin) {
            return const _AccessDeniedView();
          }

          return AnimatedGradientBackground(
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.secondary.withValues(alpha: 0.03),
            ],
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              body: IndexedStack(
                index: _currentIndex,
                children: [
                  _StaffDashboardContent(user: user, onExportDatabase: _exportDatabase),
                  _StaffAppointmentsTab(),
                  _StaffQueueTab(),
                  _StaffInventoryTab(),
                  _StaffScanningTab(),
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
                Text('This area is for clinic staff only.\n\nUse the pet owner dashboard instead.', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
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

class _StaffNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const _StaffNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}

/// Main staff dashboard content
class _StaffDashboardContent extends StatelessWidget {
  final dynamic user;
  final VoidCallback onExportDatabase;

  const _StaffDashboardContent({required this.user, required this.onExportDatabase});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QueueBloc(
        repository: context.read(),
        authBloc: context.read<AuthBloc>(),
      )..add(const QueueStaffLoadRequested()),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final userName = user?.fullName?.split(' ')?.first ?? 'Staff';

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
                      'Good ${_getGreeting()}, $userName!',
                      style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    Text(
                      'Staff Dashboard — ${user?.role?.displayName ?? 'Staff'}',
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
                      // Quick Stats
                      _StaffQuickStatsSection(),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _StaffQuickActionsSection(),
                      const SizedBox(height: 24),

                      // Today's Queue Preview
                      _StaffQueuePreviewSection(),
                      const SizedBox(height: 24),

                      // Quick Links
                      _StaffQuickLinksSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

/// Quick stats cards for staff
class _StaffQuickStatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QueueBloc, QueueState>(
      builder: (context, state) {
        int waiting = 0;
        int inRoom = 0;
        int currentServing = 0;

        if (state is QueueStaffLoaded) {
          waiting = state.totalWaiting;
          inRoom = state.totalInRoom;
          currentServing = state.currentServing;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s Overview', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Waiting', value: '$waiting', icon: Icons.schedule_outlined, color: AppColors.warning, trend: 'pets')),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'In Room', value: '$inRoom', icon: Icons.door_front_door_outlined, color: AppColors.primary, trend: 'active')),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Now Serving', value: currentServing > 0 ? '#$currentServing' : '—', icon: Icons.person_outlined, color: AppColors.success, trend: 'next')),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
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
                Text(trend, style: AppTextStyles.bodySmall.muted),
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

/// Quick actions for staff
class _StaffQuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            _StaffActionCard(
              icon: Icons.queue_outlined,
              label: 'Manage\nQueue',
              color: AppColors.primary,
              onTap: () => context.push(Routes.staffQueue),
            ),
            _StaffActionCard(
              icon: Icons.calendar_month_outlined,
              label: 'View\nAppointments',
              color: AppColors.secondary,
              onTap: () => context.push(Routes.staffAppointments),
            ),
            _StaffActionCard(
              icon: Icons.inventory_2_outlined,
              label: 'Check\nInventory',
              color: AppColors.success,
              onTap: () => context.push(Routes.staffInventory),
            ),
            _StaffActionCard(
              icon: Icons.scanner_outlined,
              label: 'Scan\nMedicine',
              color: Colors.orange,
              onTap: () => context.push(Routes.staffScanning),
            ),
            _StaffActionCard(
              icon: Icons.add_circle_outline,
              label: 'Add\nAppointment',
              color: AppColors.info,
              onTap: () => context.push(Routes.staffAppointments), // Will open add mode
            ),
            _StaffActionCard(
              icon: Icons.assignment_outlined,
              label: 'Daily\nReport',
              color: Colors.purple,
              onTap: () => _showComingSoon(context, 'Daily Report'),
            ),
            _StaffActionCard(
              icon: Icons.people_outlined,
              label: 'Walk-in\nCheck-in',
              color: Colors.teal,
              onTap: () => _showComingSoon(context, 'Walk-in Check-in'),
            ),
            _StaffActionCard(
              icon: Icons.print_outlined,
              label: 'Print\nQueue',
              color: Colors.indigo,
              onTap: () => _showComingSoon(context, 'Print Queue'),
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

class _StaffActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StaffActionCard({
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

/// Queue preview section
class _StaffQueuePreviewSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QueueBloc, QueueState>(
      builder: (context, state) {
        if (state is! QueueStaffLoaded || state.queueEntries.isEmpty) {
          return _EmptyQueuePreview();
        }

        final waitingEntries = state.queueEntries
            .where((e) => e.queueEntry.status == QueueStatus.waiting || e.queueEntry.status == QueueStatus.called)
            .toList()
          ..sort((a, b) => a.queueEntry.position.compareTo(b.queueEntry.position));

        final inRoomEntries = state.queueEntries
            .where((e) => e.queueEntry.status == QueueStatus.inRoom)
            .toList()
          ..sort((a, b) => a.queueEntry.position.compareTo(b.queueEntry.position));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Live Queue', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => context.push(Routes.staffQueue),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (waitingEntries.isNotEmpty) ...[
              Text('Waiting / Called', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.warning)),
              const SizedBox(height: 8),
              ...waitingEntries.take(3).map((entry) => _StaffQueuePreviewItem(entry: entry, isWaiting: true)),
            ],
            if (inRoomEntries.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('In Room', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
              const SizedBox(height: 8),
              ...inRoomEntries.take(3).map((entry) => _StaffQueuePreviewItem(entry: entry, isWaiting: false)),
            ],
            if (waitingEntries.length > 3 || inRoomEntries.length > 3) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.push(Routes.staffQueue),
                  child: Text('+ ${state.queueEntries.length - 6} more entries'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StaffQueuePreviewItem extends StatelessWidget {
  final QueueEntryWithDetails entry;
  final bool isWaiting;

  const _StaffQueuePreviewItem({required this.entry, required this.isWaiting});

  @override
  Widget build(BuildContext context) {
    final statusColor = isWaiting ? AppColors.warning : AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [statusColor, statusColor.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${entry.queueEntry.position}',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textOnPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.pet.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text('${entry.pet.species.displayName} • ${entry.appointment.reason ?? 'Checkup'}', style: AppTextStyles.bodySmall.subtle),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
            child: Text(entry.queueEntry.status.displayName, style: AppTextStyles.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _EmptyQueuePreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: 16,
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
              decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(48)),
              child: const Icon(Icons.queue_outlined, size: 48, color: AppColors.textOnPrimary),
            ),
          ),
          const SizedBox(height: 16),
          Text('Queue is Empty', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('No patients checked in yet.\nAppointments will appear here when patients arrive.', style: AppTextStyles.bodyMedium.subtle.copyWith(height: 1.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Quick links section
class _StaffQuickLinksSection extends StatelessWidget {
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
              _LinkTile(icon: Icons.notifications_outlined, title: 'Notifications', subtitle: 'Appointment reminders & updates', onTap: () => context.push(Routes.notifications)),
              const Divider(height: 1, indent: 56),
              _LinkTile(icon: Icons.medical_services_outlined, title: 'Medical Records', subtitle: 'View patient health history', onTap: () => _showComingSoon(context, 'Medical Records')),
              const Divider(height: 1, indent: 56),
              _LinkTile(icon: Icons.inventory_2_outlined, title: 'Low Stock Alerts', subtitle: 'Medicines needing restock', onTap: () => _showComingSoon(context, 'Low Stock Alerts')),
              const Divider(height: 1, indent: 56),
              _LinkTile(icon: Icons.settings_outlined, title: 'Settings', subtitle: 'App preferences & clinic config', onTap: () => context.push(Routes.settings)),
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

/// Placeholder tabs for staff
class _StaffAppointmentsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PlaceholderTab(title: 'Appointments', icon: Icons.calendar_today_outlined, actionText: 'Manage Appointments', actionRoute: Routes.staffAppointments);
  }
}

class _StaffQueueTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PlaceholderTab(title: 'Queue', icon: Icons.queue_outlined, actionText: 'Manage Queue', actionRoute: Routes.staffQueue);
  }
}

class _StaffInventoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PlaceholderTab(title: 'Inventory', icon: Icons.inventory_2_outlined, actionText: 'Manage Inventory', actionRoute: Routes.staffInventory);
  }
}

class _StaffScanningTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PlaceholderTab(title: 'Scanning', icon: Icons.scanner_outlined, actionText: 'Start Scan', actionRoute: Routes.staffScanning);
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
            Container(width: 140, height: 140, decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(70), boxShadow: PremiumShadows.primary), child: Icon(icon, size: 70, color: AppColors.textOnPrimary)),
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