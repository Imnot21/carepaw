import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/users/presentation/pages/admin_user_management_page.dart';
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

/// Admin Dashboard - Full system administration
/// Only accessible by ADMIN role
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

  final List<_AdminNavItem> _navItems = const [
    _AdminNavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Dashboard', route: Routes.adminDashboard),
    _AdminNavItem(icon: Icons.people_outlined, selectedIcon: Icons.people, label: 'Users', route: Routes.adminUsers),
    _AdminNavItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings', route: Routes.adminSettings),
    _AdminNavItem(icon: Icons.security_outlined, selectedIcon: Icons.security, label: 'Audit Logs', route: Routes.adminAudit),
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
          final isAdmin = user.role == UserRole.admin;

          if (!isAdmin) {
            return const _AccessDeniedView();
          }

          return AnimatedGradientBackground(
            colors: [
              AppColors.error.withValues(alpha: 0.05),
              AppColors.warning.withValues(alpha: 0.03),
            ],
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              body: IndexedStack(
                index: _currentIndex,
                children: [
                  _AdminDashboardContent(user: user, onExportDatabase: _exportDatabase),
                  _AdminUsersTab(),
                  _AdminSettingsTab(),
                  _AdminAuditTab(),
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
                Text('This area is for administrators only.', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
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

class _AdminNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const _AdminNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}

/// Main admin dashboard content
class _AdminDashboardContent extends StatelessWidget {
  final dynamic user;
  final VoidCallback onExportDatabase;

  const _AdminDashboardContent({required this.user, required this.onExportDatabase});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userName = user?.fullName?.split(' ')?.first ?? 'Admin';

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
                    'Administration Dashboard',
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
                    // System Stats
                    _AdminStatsSection(),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _AdminQuickActionsSection(),
                    const SizedBox(height: 24),

                    // System Health
                    _AdminSystemHealthSection(),
                    const SizedBox(height: 24),

                    // Quick Links
                    _AdminQuickLinksSection(),
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

/// System stats cards for admin
class _AdminStatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Get real data from repositories
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Overview', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _AdminStatCard(label: 'Total Users', value: '156', icon: Icons.people_outlined, color: AppColors.primary, subtitle: '+12 this week')),
            const SizedBox(width: 12),
            Expanded(child: _AdminStatCard(label: 'Active Pets', value: '342', icon: Icons.pets_outlined, color: AppColors.success, subtitle: '289 owners')),
            const SizedBox(width: 12),
            Expanded(child: _AdminStatCard(label: 'Today\'s Appts', value: '24', icon: Icons.calendar_today_outlined, color: AppColors.secondary, subtitle: '8 completed')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _AdminStatCard(label: 'Queue Length', value: '7', icon: Icons.queue_outlined, color: AppColors.warning, subtitle: '2 in room')),
            const SizedBox(width: 12),
            Expanded(child: _AdminStatCard(label: 'Low Stock', value: '5', icon: Icons.inventory_2_outlined, color: AppColors.error, subtitle: 'needs reorder')),
            const SizedBox(width: 12),
            Expanded(child: _AdminStatCard(label: 'Storage Used', value: '2.4 GB', icon: Icons.storage_outlined, color: AppColors.info, subtitle: 'of 10 GB')),
          ],
        ),
      ],
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _AdminStatCard({
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

/// Quick actions for admin
class _AdminQuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Admin Actions', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            _AdminActionCard(
              icon: Icons.person_add_outlined,
              label: 'Add\nUser',
              color: AppColors.primary,
              onTap: () => context.push(Routes.adminUsers),
            ),
            _AdminActionCard(
              icon: Icons.manage_accounts_outlined,
              label: 'Manage\nRoles',
              color: AppColors.secondary,
              onTap: () => _showComingSoon(context, 'Manage Roles'),
            ),
            _AdminActionCard(
              icon: Icons.tune_outlined,
              label: 'Clinic\nSettings',
              color: AppColors.success,
              onTap: () => context.push(Routes.adminSettings),
            ),
            _AdminActionCard(
              icon: Icons.security_outlined,
              label: 'View\nAudit Logs',
              color: AppColors.warning,
              onTap: () => context.push(Routes.adminAudit),
            ),
            _AdminActionCard(
              icon: Icons.backup_outlined,
              label: 'Backup\nDatabase',
              color: Colors.purple,
              onTap: () => _showComingSoon(context, 'Backup Database'),
            ),
            _AdminActionCard(
              icon: Icons.restore_outlined,
              label: 'Restore\nBackup',
              color: Colors.teal,
              onTap: () => _showComingSoon(context, 'Restore Backup'),
            ),
            _AdminActionCard(
              icon: Icons.analytics_outlined,
              label: 'System\nAnalytics',
              color: Colors.orange,
              onTap: () => _showComingSoon(context, 'System Analytics'),
            ),
            _AdminActionCard(
              icon: Icons.bug_report_outlined,
              label: 'Debug\nTools',
              color: Colors.indigo,
              onTap: () => _showComingSoon(context, 'Debug Tools'),
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

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
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

/// System health section
class _AdminSystemHealthSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final healthItems = [
      _HealthItem(title: 'Database', status: 'Healthy', subtitle: 'SQLite - 2.4 GB used', icon: Icons.storage, color: AppColors.success),
      _HealthItem(title: 'Authentication', status: 'Active', subtitle: 'JWT tokens valid', icon: Icons.security, color: AppColors.success),
      _HealthItem(title: 'Background Sync', status: 'Running', subtitle: 'Last sync 2 min ago', icon: Icons.sync, color: AppColors.success),
      _HealthItem(title: 'Notifications', status: 'Enabled', subtitle: 'FCM connected', icon: Icons.notifications_active, color: AppColors.success),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Health', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GlassContainer(
          borderRadius: 20,
          blur: 15,
          padding: EdgeInsets.zero,
          borderColor: Theme.of(context).brightness == Brightness.dark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
          child: Column(
            children: healthItems.map((item) => _HealthTile(item: item)).toList(),
          ),
        ),
      ],
    );
  }
}

class _HealthItem {
  final String title;
  final String status;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _HealthItem({
    required this.title,
    required this.status,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _HealthTile extends StatelessWidget {
  final _HealthItem item;

  const _HealthTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [item.color.withValues(alpha: 0.2), item.color.withValues(alpha: 0.05)]), borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(item.subtitle, style: AppTextStyles.bodySmall.subtle),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: item.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: item.color.withValues(alpha: 0.3))),
            child: Text(item.status, style: AppTextStyles.labelSmall.copyWith(color: item.color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Quick links for admin
class _AdminQuickLinksSection extends StatelessWidget {
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
              _LinkTile(icon: Icons.notifications_outlined, title: 'Notifications', subtitle: 'System alerts & announcements', onTap: () => context.push(Routes.notifications)),
              const Divider(height: 1, indent: 56),
              _LinkTile(icon: Icons.help_outline, title: 'Documentation', subtitle: 'API docs & guides', onTap: () => _showComingSoon(context, 'Documentation')),
              const Divider(height: 1, indent: 56),
              _LinkTile(icon: Icons.api_outlined, title: 'API Management', subtitle: 'Endpoints & keys', onTap: () => _showComingSoon(context, 'API Management')),
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

/// Placeholder tabs for admin
class _AdminUsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AdminUserManagementPage();
  }
}

class _AdminSettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PlaceholderTab(title: 'Clinic Settings', icon: Icons.settings_outlined, actionText: 'Open Settings', actionRoute: Routes.adminSettings);
  }
}

class _AdminAuditTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PlaceholderTab(title: 'Audit Logs', icon: Icons.security_outlined, actionText: 'View Logs', actionRoute: Routes.adminAudit);
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
            Container(width: 140, height: 140, decoration: BoxDecoration(gradient: AppColors.gradientError, borderRadius: BorderRadius.circular(70), boxShadow: PremiumShadows.coloredShadow(AppColors.error)), child: Icon(icon, size: 70, color: Colors.white)),
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