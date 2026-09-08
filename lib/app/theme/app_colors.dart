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

  // ============ Neomorphic Shadow Colors ============
  // Light mode: white light source (upper-left) + gray-blue shadow (lower-right)
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark = Color(0xFFA3B1C6);

  // Dark mode: darker-than-bg upper-left + lighter-than-bg lower-right
  static const Color shadowLightOnDark = Color(0xFF3A3E45);
  static const Color shadowDarkOnDark = Color(0xFF1A1C20);

  // ============ Text Colors ============
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textTertiary = Color(0xFFA0AEC0);

  static const Color textPrimaryOnDark = Color(0xFFE8ECF1);
  static const Color textSecondaryOnDark = Color(0xFFA7B0BC);
  static const Color textTertiaryOnDark = Color(0xFF6E7682);

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

  // Glass (legacy effect system)
  static const Color glassBorderLight = Color(0x66FFFFFF);
  static const Color glassBorderDark = Color(0x33000000);
  static const Color glassLight = Color(0x190066CC);
  static const Color glassDark = Color(0x330050A5);
  static const Color glassHighlightLight = Color(0x99FFFFFF);
  static const Color glassHighlightDark = Color(0x26000000);

  // Legacy premium-shadow colors (used by premium_shadows.dart, being removed)
  static const Color shadow1 = Color(0x14000000);
  static const Color shadow2 = Color(0x1A000000);
  static const Color shadow3 = Color(0x22000000);
  static const Color shadow4 = Color(0x2E000000);
  static const Color shadow5 = Color(0x3D000000);
  static const Color shadowDark1 = Color(0x52FFFFFF);
  static const Color shadowDark2 = Color(0x40FFFFFF);
  static const Color shadowDark3 = Color(0x33FFFFFF);
  static const Color shadowDark4 = Color(0x2BFFFFFF);
  static const Color shadowDark5 = Color(0x21FFFFFF);
  static const Color shadowPrimary = Color(0x330066CC);
  static const Color shadowError = Color(0x33E53E3E);
  static const Color shadowSuccess = Color(0x3338A169);
  static const Color shadowWarning = Color(0x33DD6B20);

  // Gradients (legacy) — flat blue/gray neumorphic gradients
  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  static const LinearGradient gradientError = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [error, Color(0xFFF87171)],
  );
  static const LinearGradient gradientSuccess = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF6EE7B7)],
  );
  static const LinearGradient gradientWarning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning, Color(0xFFFDBA74)],
  );

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
  static const Color categorySupplyDark = Color(0xFF4A5568);
  static const Color categoryEquipment = Color(0xFF6B7280);
  static const Color categoryEquipmentDark = Color(0xFF374151);

  // Pet accent aliases (species color helper)
  static const Color dogAccent = accentDog;
  static const Color catAccent = accentCat;
  static const Color birdAccent = accentBird;
  static const Color rabbitAccent = accentRabbit;
  static const Color reptileAccent = accentReptile;
  static const Color otherAccent = accentDefault;
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