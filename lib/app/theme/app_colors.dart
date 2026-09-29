import 'package:flutter/material.dart';

export 'theme_colors.dart' show ThemeColors;

/// Soft Clinic palette — warm bone canvas, terracotta primary, warm charcoal
/// dark mode.
///
/// Design principles (Soft Clinic direction):
/// - Warm bone canvas keeps the app fresh, calm, and trustworthy
/// - Terracotta primary feels organic and caring without looking generic
/// - Achromatic content fields carry data; color lives at hairline edges
/// - One warm accent per screen; everything else stays quiet
/// - Dark mode is a deep warm charcoal, never a quick invert
class AppColors {
  AppColors._();

  static const Color transparent = Color(0x00000000);

  // ============ Light canvas ============
  static const Color background = Color(0xFFF7F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceInset = Color(0xFFEDE9E2);

  // ============ Dark canvas (warm charcoal) ============
  static const Color backgroundDark = Color(0xFF1C1917);
  static const Color surfaceDarkMode = Color(0xFF292524);
  static const Color surfaceInsetDark = Color(0xFF3A3532);

  // ============ Brand — terracotta ============
  static const Color primary = Color(0xFFE27D60);
  static const Color primaryLight = Color(0xFFF4A988);
  static const Color primaryDark = Color(0xFFC86A4E);
  static const Color primaryOnDark = Color(0xFFF0927A);
  static const Color primaryTint = Color(0xFFF5E8E0);
  static const Color primaryTintOnDark = Color(0xFF3A2A26);

  // ============ Neumorphic shadow colors ============
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark = Color(0xFFDDD8D0);
  static const Color shadowLightOnDark = Color(0xFF4A4540);
  static const Color shadowDarkOnDark = Color(0xFF0A0908);

  // ============ Text ============
  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textTertiary = Color(0xFFA8A29E);
  static const Color textPrimaryOnDark = Color(0xFFFAFAF9);
  static const Color textSecondaryOnDark = Color(0xFFD6D3D1);
  static const Color textTertiaryOnDark = Color(0xFFA8A29E);

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

  static const Color surfaceContainer = Color(0xFFEDE9E2);
  static const Color surfaceVariant = Color(0xFFE7E2DA);
  static const Color surfaceVariantDark = Color(0xFF3A3532);
  static const Color borderStrong = Color(0xFFD6D0C8);
  static const Color borderStrongDark = Color(0xFF4A4540);
  static const Color categoryFood = Color(0xFF9C7BA8);
  static const Color warningDark = Color(0xFFB45309);
  static const Color tertiaryDark = Color(0xFF0D9488);
  static const Color surfaceContainerHighest = Color(0xFFE7E2DA);
  static const Color surfaceContainerDark = Color(0xFF3A3532);
  static const Color border = Color(0xFFE7E2DA);
  static const Color borderDark = Color(0xFF3A3532);
  static const Color divider = border;
  static const Color dividerDark = borderDark;

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
