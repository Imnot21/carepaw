import 'package:flutter/material.dart';

export 'theme_colors.dart' show ThemeColors;

/// CarePaw palette — cool clinic canvas, PILA VET HUB indigo primary, caduceus
/// cyan secondary, cool slate dark mode. Brand colours are sampled from the
/// clinic logo (`assets/images/pilavethub_logo.png`).
///
/// Depth is expressed with **token-driven dual extrusion** — a top-left light
/// and a bottom-right tinted depth shadow per plane (`NeuShadow`; see
/// `DESIGN.md` "How depth works now"). Hairlines survive only where an edge
/// carries data — queue position, batch expiry — because a hairline and a
/// highlight fight over the same edge.
///
/// Design principles:
/// - Cool clinic canvas keeps the app fresh, calm, and trustworthy
/// - Indigo primary matches the clinic's logo and reads as clinical care
/// - Cyan secondary (the logo's caduceus) marks progress and highlights
/// - Tinted surface levels carry hierarchy; the light/depth pair carries the edges
/// - One accent per screen; everything else stays quiet
/// - Dark mode is a deep cool slate, never a quick invert
class AppColors {
  AppColors._();

  static const Color transparent = Color(0x00000000);

  // ============ Light canvas ============
  static const Color background = Color(0xFFF4F6FB);

  /// Top plane — cards, sheets, dialogs. The brightest surface.
  static const Color surface = Color(0xFFFFFFFF);

  /// Recessed plane — fields, tracks, wells. One step *below* the canvas so a
  /// filled input reads as a well rather than a plate.
  static const Color surfaceInset = Color(0xFFE9EDF5);

  /// Muted plane — quiet groupings, table headers, skeletons.
  static const Color surfaceMuted = Color(0xFFF7F9FC);

  // ============ Dark canvas (cool slate) ============
  static const Color backgroundDark = Color(0xFF15171F);
  static const Color surfaceDarkMode = Color(0xFF1F2230);
  static const Color surfaceInsetDark = Color(0xFF191B25);
  static const Color surfaceMutedDark = Color(0xFF1B1D28);

  // ============ Brand — PILA VET HUB indigo ============
  static const Color primary = Color(0xFF2E3192);
  static const Color primaryLight = Color(0xFF8C93E8);
  static const Color primaryDark = Color(0xFF23267A);
  static const Color primaryOnDark = Color(0xFF8C93E8);
  static const Color primaryTint = Color(0xFFE6E7F6);
  static const Color primaryTintOnDark = Color(0xFF262A4A);

  // ============ Brand — caduceus cyan (secondary) ============
  //
  // The logo cyan (#0098C8) is 3.0:1 on white: fine for icons and large
  // shapes, too faint for small text. `brandCyanText` is the deepened version
  // for anything read on a light plane.
  static const Color brandCyan = Color(0xFF0098C8);
  static const Color brandCyanText = Color(0xFF00739A);
  static const Color brandCyanOnDark = Color(0xFF4CC9F0);

  // ============ Accent ink — contrast-safe ============
  //
  // Fill and ink are separate jobs. `primary` is the indigo fill for buttons,
  // FABs, and tints; `primaryText` is the accent wherever it must be *read*
  // on the canvas. Text on an indigo fill is white in light mode
  // (`textOnPrimary`, 10.7:1) and `primaryInk` on the lightened dark-mode fill
  // (6.3:1). Verified ratios: primaryText 9.9:1 on canvas, 8.7:1 on tint;
  // primaryOnDark 6.4:1 on the dark canvas, 5.6:1 on dark cards.

  /// Accent for text and icons read on the canvas (light mode).
  static const Color primaryText = Color(0xFF2E3192);

  /// Cool near-black for text and glyphs on the dark-mode accent fill.
  static const Color primaryInk = Color(0xFF15172B);

  // ============ Extrusion shadows ============
  //
  // The light source and the depth shadow. Both are tinted to the canvas hue —
  // a neutral gray shadow on `#F4F6FB` reads as dirt rather than as depth.

  /// Top-left light source. White, so it lifts a surface off the cool canvas
  /// without shifting its hue.
  static const Color shadowLight = Color(0xFFFFFFFF);

  /// Bottom-right depth shadow. The canvas darkened toward slate, so the
  /// shadow belongs to the surface instead of sitting on top of it.
  static const Color shadowDepth = Color(0xFFA9B1C7);

  /// Single drop shadow for floating chrome, tinted further toward the canvas.
  static const Color shadowFloating = Color(0xFF5E6782);

  // ============ Extrusion shadows (dark) ============
  //
  // Dark mode has no white light source — the highlight would describe a light
  // that does not exist. The top-left rim borrows the surface's own hue and the
  // depth shadow becomes near-black.

  /// Faint top-left rim, in the cool-slate family.
  static const Color shadowLightDark = Color(0xFF2E3243);

  /// Depth shadow on charcoal.
  static const Color shadowDepthDark = Color(0xFF000000);

  // ============ Hairlines ============
  //
  // NOT part of the extrusion system. A hairline and a highlight fight each
  // other, so edges on ordinary cards come from the shadow pair alone.
  // `border` survives for data-critical rows — queue position, batch expiry —
  // where the edge carries data rather than decoration.

  /// Default hairline on any surface (light). Cool gray, never neutral gray.
  static const Color border = Color(0xFFDDE2EC);

  /// Emphasized hairline — focused fields, selected chips, active outlines.
  static const Color borderStrong = Color(0xFFC9D0DE);

  /// Interior separator — table rows, list dividers.
  static const Color divider = Color(0xFFE6EAF1);

  // ============ Hairlines (dark) ============

  static const Color borderDark = Color(0xFF2E3243);
  static const Color borderStrongDark = Color(0xFF3D4257);
  static const Color dividerDark = Color(0xFF272A38);

  // ============ Placeholder blocks ============

  /// Skeleton block fill. Reads as content-shaped absence, not a surface.
  static const Color skeleton = Color(0xFFE6EAF1);
  static const Color skeletonDark = Color(0xFF272A38);

  // ============ Text ============
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF2B2B2B);
  static const Color textTertiary = Color(0xFF4A4A4A);
  static const Color textPrimaryOnDark = Color(0xFFFFFFFF);
  static const Color textSecondaryOnDark = Color(0xFFE5E7EB);
  static const Color textTertiaryOnDark = Color(0xFFD1D5DB);

  // ============ Status ============
  //
  // Deepened for AA: these double as text colours on light planes and as
  // fills under white text — all three clear 4.5:1 in both roles (e.g.
  // #B91C1C on bone 5.5:1, white on #B91C1C 5.9:1).
  static const Color error = Color(0xFFB91C1C);
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFB45309);
  static const Color errorOnDark = Color(0xFFF87171);
  static const Color successOnDark = Color(0xFF4ADE80);
  static const Color warningOnDark = Color(0xFFFBBF24);

  /// Caduceus cyan for "progress" tones — scans, in-progress visits.
  /// 5.4:1 on white, 5.0:1 on the canvas; 9.3:1 on the dark canvas.
  static const Color progress = brandCyanText;
  static const Color progressOnDark = brandCyanOnDark;

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
  static const Color surfaceVariantDark = Color(0xFF1F2230);
  static const Color categoryFood = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFB45309);
  static const Color tertiaryDark = brandCyanText;
  static const Color surfaceContainerHighest = Color(0xFFFFFFFF);
  static const Color surfaceContainerDark = Color(0xFF1F2230);
  /// Status blue for info text, icons, and timestamps. Steel blue clears
  /// 4.7:1 on the canvas and white; the dark-mode variant clears 8.2:1.
  static const Color info = Color(0xFF4A6FA5);
  static const Color infoDark = Color(0xFF93B4E4);

  static const Color secondary = textSecondary;
  static const Color tertiary = brandCyan;
  static const Color quaternary = warning;

  static const Color categoryMedicine = Color(0xFF16A34A);
  static const Color categoryVaccine = primaryLight;
  static const Color categorySupply = Color(0xFF718096);
  static const Color categoryEquipment = Color(0xFF6366F1);

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
