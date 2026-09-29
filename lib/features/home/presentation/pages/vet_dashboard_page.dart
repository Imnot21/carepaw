import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';

/// Veterinarian Dashboard - Clinical features for veterinarians
/// Only accessible by VETERINARIAN and ADMIN roles
class VetDashboardPage extends StatefulWidget {
  const VetDashboardPage({super.key});

  @override
  State<VetDashboardPage> createState() => _VetDashboardPageState();
}

class _VetDashboardPageState extends State<VetDashboardPage> {
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
          final isVetOrAdmin =
              user.role == UserRole.veterinarian || user.role == UserRole.admin;

          if (!isVetOrAdmin) {
            return const _AccessDeniedView();
          }

          return _VetDashboardContent(user: user);
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const NeuCircularProgress(),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: AppTextStyles.bodyMedium.subtleOf(
              Theme.of(context).brightness,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuContainer(
              borderRadius: 80,
              padding: const EdgeInsets.all(28),
              color: AppColors.error,
              boxShadow: NeuShadow.color(
                context,
                AppColors.error,
                blur: 24,
                opacity: 0.32,
              ),
              child: const Icon(
                Icons.block_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Access Denied',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: ThemeColors.error(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This area is for veterinarians only.\n\nUse the appropriate dashboard for your role.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            NeuButton(
              text: 'Go Back',
              onPressed: () => context.pop(),
              icon: Icons.arrow_back_rounded,
              variant: NeuButtonVariant.secondary,
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Main veterinarian dashboard content
class _VetDashboardContent extends StatelessWidget {
  final dynamic user;

  const _VetDashboardContent({required this.user});

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
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Veterinarian Dashboard',
                    style: AppTextStyles.bodySmall.subtleOf(
                      Theme.of(context).brightness,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push(Routes.notifications),
                  tooltip: 'Notifications',
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
                    // Quick Actions
                    _VetQuickActionsSection(),
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

/// Quick actions for veterinarian
class _VetQuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clinical Actions',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
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
              color: ThemeColors.primary(context),
              onTap: () => _showComingSoon(context, 'New Visit Record'),
            ),
            _VetActionCard(
              icon: Icons.medication_outlined,
              label: 'Prescribe\nMedication',
              color: ThemeColors.primary(context),
              onTap: () => _showComingSoon(context, 'Prescribe Medication'),
            ),
            _VetActionCard(
              icon: Icons.vaccines_outlined,
              label: 'Add\nVaccination',
              color: ThemeColors.primary(context),
              onTap: () => _showComingSoon(context, 'Add Vaccination'),
            ),
            _VetActionCard(
              icon: Icons.science_outlined,
              label: 'Order\nLab Tests',
              color: ThemeColors.primary(context),
              onTap: () => _showComingSoon(context, 'Order Lab Tests'),
            ),
            _VetActionCard(
              icon: Icons.note_add_outlined,
              label: 'Clinical\nNotes',
              color: ThemeColors.primary(context),
              onTap: () => _showComingSoon(context, 'Clinical Notes'),
            ),
            _VetActionCard(
              icon: Icons.attach_file_outlined,
              label: 'Attach\nResults',
              color: ThemeColors.primary(context),
              onTap: () => _showComingSoon(context, 'Attach Results'),
            ),
            _VetActionCard(
              icon: Icons.history_outlined,
              label: 'Patient\nHistory',
              color: ThemeColors.primary(context),
              onTap: () => context.push(Routes.vetPatients),
            ),
            _VetActionCard(
              icon: Icons.print_outlined,
              label: 'Generate\nSummary',
              color: ThemeColors.primary(context),
              onTap: () => _showComingSoon(context, 'Generate Summary'),
            ),
          ],
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
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
    return NeuCard(
      onTap: onTap,
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick links for vet
class _VetQuickLinksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        NeuCard(
          borderRadius: 20,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _LinkTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Lab results & alerts',
                onTap: () => context.push(Routes.notifications),
              ),
              const Divider(height: 1, indent: 56),
              _LinkTile(
                icon: Icons.medical_services_outlined,
                title: 'Medical Records',
                subtitle: 'Full patient history access',
                onTap: () => context.push(Routes.medicalRecords),
              ),
              const Divider(height: 1, indent: 56),
              _LinkTile(
                icon: Icons.inventory_2_outlined,
                title: 'Medicine Catalog',
                subtitle: 'Available medications & dosages',
                onTap: () => _showComingSoon(context, 'Medicine Catalog'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: NeuContainer(
          borderRadius: 12,
          padding: const EdgeInsets.all(8),
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.16)
              : AppColors.primaryTint,
          child: Icon(icon, color: ThemeColors.primary(context), size: 22),
        ),
        title: Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.subtleOf(Theme.of(context).brightness),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: ThemeColors.textTertiary(context),
        ),
        onTap: onTap,
      ),
    );
  }
}
