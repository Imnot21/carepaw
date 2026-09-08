import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_bottom_nav.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'role_tabs.dart';

/// The primary application shell.
///
/// Renders the active feature page (provided by the router as [child]) inside
/// a [Scaffold] whose bottom bar is a neumorphic [`NeuBottomNav`]. The tab set
/// adapts to the signed-in user's role, and the active slot tracks the current
/// route so nested screens keep their section highlighted.
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthBloc, UserRole>(
      (bloc) => bloc.state is AuthAuthenticated
          ? (bloc.state as AuthAuthenticated).user.role
          : UserRole.petOwner,
    );

    final tabs = RoleTabs.forRole(role);
    // Derive active tab from the current location (exact or nested prefix).
    final currentIndex = tabs.indexFor(GoRouterState.of(context).uri.path);

    return Scaffold(
      body: child,
      bottomNavigationBar: NeuBottomNav(
        items: [
          for (final tab in tabs.tabs)
            NeuNavItem(
              icon: tab.icon,
              activeIcon: tab.activeIcon,
              label: tab.label,
              onSelected: () => context.go(tab.location),
            ),
        ],
        currentIndex: currentIndex,
        onTap: (index) => context.go(tabs.tabs[index].location),
      ),
    );
  }
}