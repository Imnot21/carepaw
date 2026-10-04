import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/app/theme/theme_colors.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';

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
          const SizedBox(height: NeuTokens.spaceMd),
          Text(
            'Loading\u2026',
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
        padding: const EdgeInsets.all(NeuTokens.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuContainer(
              variant: NeuVariant.inset,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(NeuTokens.spaceLg),
              child: Icon(
                Icons.block_rounded,
                size: 48,
                color: ThemeColors.error(context),
              ),
            ),
            const SizedBox(height: NeuTokens.spaceLg),
            Text(
              'Access denied',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NeuTokens.spaceXs),
            Text(
              'This area is for administrators only.',
              style: AppTextStyles.bodyMedium.subtleOf(
                Theme.of(context).brightness,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NeuTokens.spaceLg),
            NeuContainer(
              variant: NeuVariant.pressed,
              shape: StadiumBorder(),
              padding: EdgeInsets.symmetric(
                horizontal: NeuTokens.spaceLg,
                vertical: NeuTokens.spaceSm,
              ),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  'Go back',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: ThemeColors.textPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
    final userName = user.fullName
        .split(' ')
        .firstWhere((w) => w.isNotEmpty, orElse: () => 'Admin');

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: NeuTokens.pagePadding,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_getGreeting()}, $userName',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Administration',
                style: AppTextStyles.bodySmall.subtleOf(
                  Theme.of(context).brightness,
                ),
              ),
            ],
          ),
          actions: [
            NeuIconButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Notifications',
              onPressed: () => context.push(Routes.notifications),
            ),
            const SizedBox(width: NeuTokens.spaceXs),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              NeuTokens.pagePadding,
              NeuTokens.spaceMd,
              NeuTokens.pagePadding,
              NeuTokens.spaceXl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_AdminQuickActionsSection()],
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

class _AdminQuickActionsSection extends StatelessWidget {
  const _AdminQuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColors.primary(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin actions',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: NeuTokens.tightGap),
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
            const SizedBox(width: NeuTokens.tightGap),
            Expanded(
              child: _AdminActionCard(
                icon: Icons.receipt_long_outlined,
                label: 'Audit logs',
                color: accent,
                onTap: () => context.push(Routes.adminAudit),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NeuContainer(
            variant: NeuVariant.pressed,
            borderRadius: NeuTokens.radiusSm,
            padding: const EdgeInsets.all(NeuTokens.spaceXs),
            child: Icon(icon, color: color, size: NeuTokens.iconLg - 4),
          ),
          const SizedBox(height: NeuTokens.spaceXs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
