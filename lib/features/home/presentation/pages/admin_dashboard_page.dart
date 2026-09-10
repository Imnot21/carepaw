import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';

/// Admin Dashboard — Firestore-backed clinic administration.
///
/// Only accessible by the ADMIN role. Surface is intentionally lean:
/// the three live admin destinations (users, audit, settings). No fabricated
/// stats and no placeholder "coming soon" tiles — nothing is shown that
/// isn't either a real route or backed by real data.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) return const _LoadingView();
        final user = authState.user;
        if (user.role != UserRole.admin) return const _AccessDeniedView();
        return _AdminDashboardContent(user: user);
      },
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
            style: AppTextStyles.bodyMedium.subtleOf(Theme.of(context).brightness),
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
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(80),
              ),
              child: const Icon(Icons.block_rounded, size: 72, color: Colors.white),
            ),
            const SizedBox(height: 28),
            Text(
              'Access Denied',
              style: AppTextStyles.headlineSmall
                  .copyWith(fontWeight: FontWeight.w600, color: ThemeColors.error(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This area is for administrators only.',
              style: AppTextStyles.bodyLarge.copyWith(color: ThemeColors.textSecondary(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AdminDashboardContent extends StatelessWidget {
  final User user;

  const _AdminDashboardContent({required this.user});

  @override
  Widget build(BuildContext context) {
    final userName = user.fullName.split(' ').firstWhere((w) => w.isNotEmpty, orElse: () => 'Admin');

    return CustomScrollView(
      slivers: [
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
                style:
                    AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              Text(
                'Administration',
                style: AppTextStyles.bodySmall.subtleOf(Theme.of(context).brightness),
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminQuickActionsSection(),
                SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions — only the three destinations that actually route somewhere.
// ─────────────────────────────────────────────────────────────────────────────

class _AdminQuickActionsSection extends StatelessWidget {
  const _AdminQuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColors.primary(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Admin Actions', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AdminActionCard(
                icon: Icons.manage_accounts_outlined,
                label: 'Users',
                color: accent,
                onTap: () => context.push(Routes.adminUsers),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AdminActionCard(
                icon: Icons.receipt_long_outlined,
                label: 'Audit Logs',
                color: accent,
                onTap: () => context.push(Routes.adminAudit),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AdminActionCard(
                icon: Icons.tune_outlined,
                label: 'Settings',
                color: accent,
                onTap: () => context.push(Routes.adminSettings),
              ),
            ),
          ],
        ),
      ],
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
    return NeuCard(
      onTap: onTap,
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(label, textAlign: TextAlign.center, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
