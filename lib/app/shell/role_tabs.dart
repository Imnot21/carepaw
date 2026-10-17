import 'package:carepaw/core/widgets/neomorphism/neu_bottom_nav.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// One destination shown in the bottom navigation shell.
///
/// [location] is the route path the tab navigates to. It also serves as the
/// tab's base path for matching the current route so the active slot stays
/// highlighted while browsing that section's nested screens.
class RoleTab {
  final String svgAsset;
  final String label;
  final String location;

  const RoleTab({
    required this.svgAsset,
    required this.label,
    required this.location,
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
  /// The tab set for [role]. Only Pet Owner and Owner/Admin are active;
  /// the staff/vet/admin sets below are hidden (kept, not deleted).
  static RoleTabs forRole(UserRole role) {
    return switch (role) {
      UserRole.petOwner => const RoleTabs._(_owner),
      // Paper-aligned single clinic operator: one tab set for everything.
      UserRole.ownerAdmin => const RoleTabs._(_clinic),
    };
  }

  /// Returns the index of the tab whose base [location] matches [path]
  /// (exact or as a prefix for nested screens), or -1 when no tab matches
  /// (e.g. a pushed detail screen outside any tab).
  ///
  /// This implementation finds the longest matching base path to ensure
  /// that more specific tabs (e.g. '/staff/appointments') take precedence
  /// over their parent tabs (e.g. '/staff').
  int indexFor(String path) {
    // Normalize path by removing trailing slash if present (except for root)
    final normalizedPath = path == '/'
        ? '/'
        : path.replaceAll(RegExp(r'/+$'), '');

    int bestMatchIndex = -1;
    int bestMatchLength = -1;

    for (var i = 0; i < tabs.length; i++) {
      final base = tabs[i].location;
      // Normalize base the same way
      final normalizedBase = base == '/'
          ? '/'
          : base.replaceAll(RegExp(r'/+$'), '');

      // Check if this tab's base matches the path (exact or as prefix)
      bool isMatch = false;
      if (normalizedPath == normalizedBase) {
        isMatch = true;
      } else if (normalizedPath.startsWith('$normalizedBase/')) {
        isMatch = true;
      }

      // If it's a match and has a longer base path than our current best match,
      // update our best match
      if (isMatch && normalizedBase.length > bestMatchLength) {
        bestMatchIndex = i;
        bestMatchLength = normalizedBase.length;
      }
    }

    return bestMatchIndex;
  }

  /// Converts to `NeuNavItemSvg` for use with `NeuBottomNav.svg`.
  List<NeuNavItemSvg> toNavItems() {
    return tabs
        .map((tab) => NeuNavItemSvg(
              svgAsset: tab.svgAsset,
              label: tab.label,
            ))
        .toList();
  }

  // ---- Pet owner journey ----
  static const _owner = [
    RoleTab(
      svgAsset: SvgIcons.home,
      label: 'Home',
      location: '/home',
    ),
    RoleTab(
      svgAsset: SvgIcons.paw,
      label: 'Pets',
      location: '/pets',
    ),
    RoleTab(
      svgAsset: SvgIcons.calendar,
      label: 'Appointments',
      location: '/appointments',
    ),
    RoleTab(
      svgAsset: SvgIcons.queue,
      label: 'Queue',
      location: '/queue',
    ),
    RoleTab(
      svgAsset: SvgIcons.person,
      label: 'Profile',
      location: '/profile',
    ),
  ];

  // ---- Owner/Admin: single clinic operator (paper-aligned) ----
  // Combines bookings, line, patients, records, stock, and scan in one set.
  // (Old staff/vet/admin tab sets removed with the old roles — backup kept.)
  static const _clinic = [
    RoleTab(
      svgAsset: SvgIcons.home,
      label: 'Home',
      location: '/clinic',
    ),
    RoleTab(
      svgAsset: SvgIcons.calendar,
      label: 'Bookings',
      location: '/staff/appointments',
    ),
    RoleTab(
      svgAsset: SvgIcons.queue,
      label: 'Line',
      location: '/staff/queue',
    ),
    RoleTab(
      svgAsset: SvgIcons.paw,
      label: 'Patients',
      location: '/vet/patients',
    ),
    RoleTab(
      svgAsset: SvgIcons.inventory,
      label: 'Stock',
      location: '/staff/inventory',
    ),
    RoleTab(
      svgAsset: SvgIcons.scan,
      label: 'Scan',
      location: '/staff/scanning',
    ),
    RoleTab(
      svgAsset: SvgIcons.person,
      label: 'Profile',
      location: '/profile',
    ),
  ];
}