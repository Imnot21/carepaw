import 'package:flutter/material.dart';

export 'theme_colors.dart' show ThemeColors;

/// CarePaw palette — warm bone canvas, terracotta primary, warm charcoal dark
/// mode.
///
/// Depth is expressed with **hairline borders and surface tints**, not
/// shadows. Every surface reads as a distinct plane because of a 1px warm
/// hairline and a small step in fill lightness — that is the whole mechanism,
/// and it stays legible on cheap panels and in bright clinic lighting.
///
/// Design principles:
/// - Warm bone canvas keeps the app fresh, calm, and trustworthy
/// - Terracotta primary feels warm and caring without looking generic
/// - Tinted surface levels carry hierarchy; hairlines carry the edges
/// - One warm accent per screen; everything else stays quiet
/// - Dark mode is a deep warm charcoal, never a quick invert
class AppColors {
  AppColors._();

  static const Color transparent = Color(0x00000000);

  // ============ Light canvas ============
  static const Color background = Color(0xFFF8F5F0);

  /// Top plane — cards, sheets, dialogs. The brightest surface.
  static const Color surface = Color(0xFFFFFFFF);

  /// Recessed plane — fields, tracks, wells. One step *below* the canvas so a
  /// filled input reads as a well rather than a plate.
  static const Color surfaceInset = Color(0xFFF1ECE3);

  /// Muted plane — quiet groupings, table headers, skeletons.
  static const Color surfaceMuted = Color(0xFFFAF7F2);

  // ============ Dark canvas (warm charcoal) ============
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color surfaceDarkMode = Color(0xFF262423);
  static const Color surfaceInsetDark = Color(0xFF1F1E1D);
  static const Color surfaceMutedDark = Color(0xFF211F1E);

  // ============ Brand — terracotta ============
  static const Color primary = Color(0xFFE27D60);
  static const Color primaryLight = Color(0xFFF4A988);
  static const Color primaryDark = Color(0xFFC86A4E);
  static const Color primaryOnDark = Color(0xFFF0927A);
  static const Color primaryTint = Color(0xFFF5E8E0);
  static const Color primaryTintOnDark = Color(0xFF3A2A26);

  // ============ Extrusion shadows ============
  //
  // The light source and the depth shadow. Both are tinted to the canvas hue —
  // a neutral gray shadow on `#F8F5F0` reads as dirt rather than as depth.

  /// Top-left light source. White, so it lifts a surface off the warm canvas
  /// without shifting its hue.
  static const Color shadowLight = Color(0xFFFFFFFF);

  /// Bottom-right depth shadow. The bone canvas darkened and warmed, so the
  /// shadow belongs to the surface instead of sitting on top of it.
  static const Color shadowDepth = Color(0xFFB8AE9E);

  /// Single drop shadow for floating chrome, tinted further toward the canvas.
  static const Color shadowFloating = Color(0xFF7A6E5E);

  // ============ Extrusion shadows (dark) ============
  //
  // Dark mode has no white light source — the highlight would describe a light
  // that does not exist. The top-left rim borrows the surface's own hue and the
  // depth shadow becomes near-black.

  /// Faint top-left rim, in the warm-charcoal family.
  static const Color shadowLightDark = Color(0xFF3A3735);

  /// Depth shadow on charcoal.
  static const Color shadowDepthDark = Color(0xFF000000);

  // ============ Hairlines ============
  //
  // NOT part of the extrusion system. A hairline and a highlight fight each
  // other, so edges on ordinary cards come from the shadow pair alone.
  // `border` survives for data-critical rows — queue position, batch expiry —
  // where the edge carries data rather than decoration.

  /// Default hairline on any surface (light). Warm gray, never neutral gray.
  static const Color border = Color(0xFFE7E0D5);

  /// Emphasized hairline — focused fields, selected chips, active outlines.
  static const Color borderStrong = Color(0xFFD6CCBD);

  /// Interior separator — table rows, list dividers.
  static const Color divider = Color(0xFFEDE7DC);

  // ============ Hairlines (dark) ============

  static const Color borderDark = Color(0xFF3A3735);
  static const Color borderStrongDark = Color(0xFF4A4643);
  static const Color dividerDark = Color(0xFF322F2E);

  // ============ Placeholder blocks ============

  /// Skeleton block fill. Reads as content-shaped absence, not a surface.
  static const Color skeleton = Color(0xFFEDE7DC);
  static const Color skeletonDark = Color(0xFF322F2E);

  // ============ Text ============
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF2B2B2B);
  static const Color textTertiary = Color(0xFF4A4A4A);
  static const Color textPrimaryOnDark = Color(0xFFFFFFFF);
  static const Color textSecondaryOnDark = Color(0xFFE5E7EB);
  static const Color textTertiaryOnDark = Color(0xFFD1D5DB);

  // ============ Status ============
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color errorOnDark = Color(0xFFF87171);
  static const Color successOnDark = Color(0xFF4ADE80);
  static const Color warningOnDark = Color(0xFFFBBF24);

  // ============ Pet species accents ============
  static const Color accentCat = Color(0xFF8B7D5B);
  static const Color accentDog = Color(0xFF7A6C5D);
  static const Color accentBird = Color(0xFF4A8B6E);
  static const Color accentRabbit = Color(0xFF9C7BA8);
  static const Color accentReptile = Color(0xFF5C8A6E);
  static const Color accentDefault = Color(0xFF5B8BC0);
  static const Color accentSageGreen = Color(0xFF8FBC8F);

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

  // ============ Legacy compatibility aliases ============
  static const Color textPrimaryDark = textPrimaryOnDark;
  static const Color textHint = textSecondary;
  static const Color textHintDark = textSecondaryOnDark;
  static const Color textSecondaryDark = textSecondaryOnDark;
  static const Color textTertiaryDark = textTertiaryOnDark;
  static const Color disabled = textTertiary;
  static const Color disabledDark = textTertiaryOnDark;
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color surfaceContainer = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFFFFFF);
  static const Color surfaceVariantDark = Color(0xFF262423);
  static const Color categoryFood = Color(0xFF9C7BA8);
  static const Color warningDark = Color(0xFFB45309);
  static const Color tertiaryDark = Color(0xFF0D9488);
  static const Color surfaceContainerHighest = Color(0xFFFFFFFF);
  static const Color surfaceContainerDark = Color(0xFF262423);
  static const Color info = primaryLight;
  static const Color infoDark = primaryOnDark;

  static const Color secondary = textSecondary;
  static const Color tertiary = Color(0xFF14B8A6);
  static const Color quaternary = warning;

  static const Color categoryMedicine = Color(0xFF16A34A);
  static const Color categoryVaccine = primaryLight;
  static const Color categorySupply = Color(0xFF718096);
  static const Color categoryEquipment = Color(0xFF6B7280);

  static const Color dogAccent = accentDog;
  static const Color catAccent = accentCat;
  static const Color birdAccent = accentBird;
  static const Color rabbitAccent = accentRabbit;
  static const Color reptileAccent = accentReptile;
  static const Color otherAccent = accentDefault;
}

extension ColorScale on Color {
  Color scale(double factor) {
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness * factor).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Color lighten([double amount = 0.1]) =>
      Color.lerp(this, Colors.white, amount) ?? this;

  Color darken([double amount = 0.1]) =>
      Color.lerp(this, Colors.black, amount) ?? this;
}
