import 'package:flutter/material.dart';

/// Neomorphism color palette - Blue primary + soft gray canvas.
///
/// Design principles:
/// - Soft gray background (#E0E5EC) acts as the neomorphic canvas
/// - Blue (#0066CC) provides the accent — active states, CTAs, links
/// - Raised elements cast a dual shadow: white light from upper-left,
///   muted blue-gray shadow from lower-right
/// - Dark mode inverts the shadow source for an embossed dark canvas
/// - Status colors (error / success / warning) for queues, inventory, records
class AppColors {
  AppColors._();

  /// Transparent color for cases where no color is desired
  static const Color transparent = Color(0x00000000);

  // ============ Neomorphic Canvas - Soft Gray ============
  /// Main app background - the canvas all elements sit on
  static const Color background = Color(0xFFE0E5EC);

  /// Surface color - identical to background; depth comes from shadows
  static const Color surface = Color(0xFFE0E5EC);

  /// Slightly darker variant for pressed/inset surfaces
  static const Color surfaceDark = Color(0xFFD6DBE3);

  // Dark-mode canvas
  static const Color backgroundDark = Color(0xFF2A2D32);
  static const Color surfaceDarkMode = Color(0xFF2A2D32);

  // ============ Brand - Blue Accent ============
  /// Primary brand color - professional medical blue
  static const Color primary = Color(0xFF0066CC);

  /// Lighter blue - hover / active tinted states
  static const Color primaryLight = Color(0xFF3D8FD6);

  /// Deeper blue - pressed states
  static const Color primaryDark = Color(0xFF004A99);

  /// Blue used on dark backgrounds for contrast
  static const Color primaryOnDark = Color(0xFF4D9BDE);

  /// Soft blue tint for selected chips / badges
  static const Color primaryTint = Color(0xFFE8F1FB);

  /// Blue tint plate for dark backgrounds (matches dark theme primaryContainer)
  static const Color primaryTintOnDark = Color(0xFF16324F);

  // ============ Neomorphic Shadow Colors ============
  // Light mode: white light source (upper-left) + gray-blue shadow (lower-right)
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark = Color(0xFFA3B1C6);

  // Dark mode: darker-than-bg upper-left + lighter-than-bg lower-right
  static const Color shadowLightOnDark = Color(0xFF3A3E45);
  static const Color shadowDarkOnDark = Color(0xFF1A1C20);

  // ============ Text Colors ============
  // Light mode keeps core typography near-black for strong readability instead
  // of washed gray text. Dark mode uses near-white primary text with soft white
  // grayscale values for secondary labels.
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF2B2B2B);
  static const Color textTertiary = Color(0xFF4A4A4A);

  static const Color textPrimaryOnDark = Color(0xFFFFFFFF);
  static const Color textSecondaryOnDark = Color(0xFFE5E7EB);
  static const Color textTertiaryOnDark = Color(0xFFD1D5DB);

  // ============ Status Colors ============
  static const Color error = Color(0xFFE53E3E);
  static const Color success = Color(0xFF38A169);
  static const Color warning = Color(0xFFDD6B20);

  static const Color errorOnDark = Color(0xFFF56565);
  static const Color successOnDark = Color(0xFF48BB78);
  static const Color warningOnDark = Color(0xFFED8936);

  // ============ Pet-Themed Accents ============
  /// Species-tinted avatar accents
  static const Color accentCat = Color(0xFF8B7D5B);
  static const Color accentDog = Color(0xFF7A6C5D);
  static const Color accentBird = Color(0xFF4A8B6E);
  static const Color accentRabbit = Color(0xFF9C7BA8);
  static const Color accentReptile = Color(0xFF5C8A6E);
  static const Color accentDefault = Color(0xFF5B8BC0);

  /// Map a pet species to a tinted accent color (for avatars/chips).
  static Color accentForSpecies(String? species) {
    if (species == null) return accentDefault;
    switch (species.trim().toLowerCase()) {
      case 'cat':
      case 'feline':
        return accentCat;
      case 'dog':
      case 'canine':
        return accentDog;
      case 'bird':
      case 'avian':
        return accentBird;
      case 'rabbit':
        return accentRabbit;
      case 'reptile':
      case 'lizard':
      case 'snake':
      case 'turtle':
        return accentReptile;
      default:
        return accentDefault;
    }
  }

  // ============ Legacy Compatibility Aliases ============
  // Old token names mapped to the neomorphism palette so files that are not
  // yet rewritten continue to compile. These will collapse as each page is
  // migrated to the neomorphic widget set.

  // Text
  static const Color textPrimaryDark = textPrimaryOnDark;
  static const Color textHint = textSecondary;
  static const Color textHintDark = textSecondaryOnDark;
  static const Color textSecondaryDark = textSecondaryOnDark;
  static const Color textTertiaryDark = textTertiaryOnDark;
  static const Color disabled = textTertiary;
  static const Color disabledDark = textTertiaryOnDark;
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Surfaces & borders
  static const Color surfaceContainer = Color(0xFFE7EBF1);
  static const Color surfaceVariant = Color(0xFFD9DEE6);
  static const Color surfaceVariantDark = Color(0xFF3A3E45);
  static const Color borderStrong = Color(0xFFB3C0D1);
  static const Color borderStrongDark = Color(0xFF4A5058);
  static const Color categoryFood = Color(0xFF9C7BA8);
  static const Color warningDark = Color(0xFFB25E12);
  static const Color tertiaryDark = Color(0xFF0D9488);
  static const Color surfaceContainerHighest = Color(0xFFD9DEE6);
  static const Color surfaceContainerDark = Color(0xFF34373D);
  static const Color border = Color(0xFFC9D1DC);
  static const Color borderDark = Color(0xFF3A3E45);
  static const Color divider = border;
  static const Color dividerDark = borderDark;

  // Status
  static const Color info = primaryLight;
  static const Color infoDark = primaryOnDark;

  // Semantic/tertiary legacy
  static const Color secondary = textSecondary;
  static const Color tertiary = Color(0xFF14B8A6);
  static const Color quaternary = warning;

  // Inventory category colors
  static const Color categoryMedicine = Color(0xFF38A169);
  static const Color categoryVaccine = primaryLight;
  static const Color categorySupply = Color(0xFF718096);
  static const Color categoryEquipment = Color(0xFF6B7280);

  // Pet accent aliases (species color helper)
  static const Color dogAccent = accentDog;
  static const Color catAccent = accentCat;
  static const Color birdAccent = accentBird;
  static const Color rabbitAccent = accentRabbit;
  static const Color reptileAccent = accentReptile;
  static const Color otherAccent = accentDefault;
}

// ============ Theme-aware helpers ============

/// Convenience helpers that resolve the correct light/dark color based on the
/// current [BuildContext]'s brightness. Use these everywhere instead of
/// hardcoding `AppColors.textPrimary` or `AppColors.textSecondary`.
extension ThemeColors on AppColors {
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.textPrimaryOnDark
          : AppColors.textPrimary;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.textSecondaryOnDark
          : AppColors.textSecondary;

  static Color textTertiary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.textTertiaryOnDark
          : AppColors.textTertiary;

  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.primaryOnDark
          : AppColors.primary;

  // ---- Status colors (semantic) ----
  static Color error(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.errorOnDark
          : AppColors.error;

  static Color success(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.successOnDark
          : AppColors.success;

  static Color warning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.warningOnDark
          : AppColors.warning;

  static Color info(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.infoDark
          : AppColors.info;

  // ---- Borders & surfaces ----
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.borderDark
          : AppColors.border;

  static Color borderStrong(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.borderStrongDark
          : AppColors.borderStrong;

  static Color surfaceContainer(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceContainerDark
          : AppColors.surfaceContainer;

  static Color surfaceVariant(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceVariantDark
          : AppColors.surfaceVariant;

  static Color primaryTint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.primaryTintOnDark
          : AppColors.primaryTint;
}

/// Legacy color helpers — scale a color's luminance. Used by a few not-yet-
/// rewritten pages; collapses as those pages adopt the neomorphic widget set.
extension ColorScale on Color {
  /// Scale the color's luminance by [factor] (0..2). Values <1 darken,
  /// >1 lighten. Kept for backward compatibility with the old palette.
  Color scale(double factor) {
    final color = this;
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness * factor).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Lighten by [amount] (0..1).
  Color lighten([double amount = 0.1]) =>
      Color.lerp(this, Colors.white, amount) ?? this;

  /// Darken by [amount] (0..1).
  Color darken([double amount = 0.1]) =>
      Color.lerp(this, Colors.black, amount) ?? this;
}