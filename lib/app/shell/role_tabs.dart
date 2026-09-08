import 'package:flutter/material.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// One destination shown in the bottom navigation shell.
///
/// [location] is the route path the tab navigates to. It also serves as the
/// tab's base path for matching the current route so the active slot stays
/// highlighted while browsing that section's nested screens.
class RoleTab {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String location;

  const RoleTab({
    required this.icon,
    required this.label,
    required this.location,
    this.activeIcon,
  });
}

/// Resolves the role-appropriate set of bottom navigation tabs.
///
/// Each role sees a curated set of destinations — pet owners get their care
/// journey, staff get clinic operations, vets get patients, admins get system
/// management. All tabs render inside the shared [`AppShell`].
class RoleTabs {
  final List<RoleTab> tabs;

  const RoleTabs._(this.tabs);

  /// The tab set for [role]. Falls back to the pet owner set for unknown roles.
  static RoleTabs forRole(UserRole role) {
    return switch (role) {
      UserRole.petOwner => const RoleTabs._(_owner),
      UserRole.staff => const RoleTabs._(_staff),
      UserRole.veterinarian => const RoleTabs._(_vet),
      UserRole.admin => const RoleTabs._(_admin),
    };
  }

  /// Returns the index of the tab whose base [location] matches [path]
  /// (exact or as a prefix for nested screens), or -1 when no tab matches
  /// (e.g. a pushed detail screen outside any tab).
  int indexFor(String path) {
    for (var i = 0; i < tabs.length; i++) {
      final base = tabs[i].location;
      if (path == base || path.startsWith('$base/')) return i;
    }
    return -1;
  }

  // ---- Pet owner journey ----
  static const _owner = [
    RoleTab(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      location: '/home',
    ),
    RoleTab(
      icon: Icons.pets_outlined,
      activeIcon: Icons.pets_rounded,
      label: 'Pets',
      location: '/pets',
    ),
    RoleTab(
      icon: Icons.event_outlined,
      activeIcon: Icons.event_rounded,
      label: 'Appointments',
      location: '/appointments',
    ),
    RoleTab(
      icon: Icons.format_list_numbered_outlined,
      activeIcon: Icons.format_list_numbered_rounded,
      label: 'Queue',
      location: '/queue',
    ),
    RoleTab(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      location: '/profile',
    ),
  ];

  // ---- Staff clinic operations ----
  static const _staff = [
    RoleTab(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      location: '/staff',
    ),
    RoleTab(
      icon: Icons.event_outlined,
      activeIcon: Icons.event_rounded,
      label: 'Appointments',
      location: '/staff/appointments',
    ),
    RoleTab(
      icon: Icons.format_list_numbered_outlined,
      activeIcon: Icons.format_list_numbered_rounded,
      label: 'Queue',
      location: '/staff/queue',
    ),
    RoleTab(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Inventory',
      location: '/staff/inventory',
    ),
    RoleTab(
      icon: Icons.document_scanner_outlined,
      activeIcon: Icons.document_scanner_rounded,
      label: 'Scanning',
      location: '/staff/scanning',
    ),
  ];

  // ---- Veterinarian patient care ----
  static const _vet = [
    RoleTab(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      location: '/vet',
    ),
    RoleTab(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'Patients',
      location: '/vet/patients',
    ),
    RoleTab(
      icon: Icons.description_outlined,
      activeIcon: Icons.description_rounded,
      label: 'Records',
      location: '/vet/records',
    ),
    RoleTab(
      icon: Icons.format_list_numbered_outlined,
      activeIcon: Icons.format_list_numbered_rounded,
      label: 'Queue',
      location: '/queue',
    ),
    RoleTab(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      location: '/profile',
    ),
  ];

  // ---- Admin system management ----
  static const _admin = [
    RoleTab(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      location: '/admin',
    ),
    RoleTab(
      icon: Icons.group_outlined,
      activeIcon: Icons.group_rounded,
      label: 'Users',
      location: '/admin/users',
    ),
    RoleTab(
      icon: Icons.fact_check_outlined,
      activeIcon: Icons.fact_check_rounded,
      label: 'Audit',
      location: '/admin/audit',
    ),
    RoleTab(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      location: '/admin/settings',
    ),
    RoleTab(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      location: '/profile',
    ),
  ];
}
