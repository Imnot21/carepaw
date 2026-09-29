import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Soft Clinic typography — warm humanist display voice, quiet system body.
///
/// Display and headline styles set in Nunito (rounded, organic, friendly) to
/// carry the brand's warm character. Body, labels, and controls stay on the
/// system face (Roboto / San Francisco) for native legibility and zero cost.
/// The scale is minimalist: clear weight and size steps, generous line
/// heights, no decorative effects.
class AppTextStyles {
  AppTextStyles._();

  // ============ Display (Nunito — rounded, organic) ============

  static TextStyle get displayLarge => GoogleFonts.nunito(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get displaySmall => GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.25,
        color: AppColors.textPrimary,
      );

  // ============ Headline (Nunito) ============

  static TextStyle get headlineLarge => GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.25,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.35,
        color: AppColors.textPrimary,
      );

  // ============ Title (system face — native legibility) ============

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.45,
  );

  // ============ Body (system face) ============

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
  );

  // ============ Label (system face) ============

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.05,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.35,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.3,
  );

  // ============ Specialized ============

  static TextStyle get appBarTitle => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.5,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    height: 1.6,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.33,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static TextStyle get numberLarge => GoogleFonts.nunito(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.1,
        color: AppColors.textPrimary,
      );

  static TextStyle get numberMedium => GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  static const TextStyle numberSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.3,
  );

  static const TextStyle code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
  );

  // ============ Color helpers ============

  static TextStyle primary(TextStyle style) =>
      style.copyWith(color: AppColors.primary);

  static TextStyle secondary(TextStyle style) =>
      style.copyWith(color: AppColors.textSecondary);

  static TextStyle subtle(TextStyle style) =>
      style.copyWith(color: AppColors.textSecondary);

  static TextStyle subtleDark(TextStyle style) =>
      style.copyWith(color: AppColors.textSecondaryOnDark);

  static TextStyle muted(TextStyle style) =>
      style.copyWith(color: AppColors.textTertiary);

  static TextStyle mutedDark(TextStyle style) =>
      style.copyWith(color: AppColors.textTertiaryOnDark);

  static TextStyle highContrast(TextStyle style) => style.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      );

  static TextStyle link(TextStyle style) => style.copyWith(
        color: AppColors.primary,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.primary,
        decorationThickness: 1.5,
      );

  static TextStyle successText(TextStyle style) =>
      style.copyWith(color: AppColors.success);

  static TextStyle warningText(TextStyle style) =>
      style.copyWith(color: AppColors.warning);

  static TextStyle error(TextStyle style) =>
      style.copyWith(color: AppColors.error);

  static TextStyle info(TextStyle style) =>
      style.copyWith(color: AppColors.info);
}

extension TextStyleX on TextStyle {
  TextStyle withColor(Color color, {FontWeight? weight}) => copyWith(
        color: color,
        fontWeight: weight,
      );

  TextStyle get subtle => copyWith(color: AppColors.textSecondary);

  TextStyle subtleDark() => copyWith(color: AppColors.textSecondaryOnDark);

  TextStyle subtleOf(Brightness brightness) =>
      brightness == Brightness.dark ? subtleDark() : subtle;

  TextStyle get muted => copyWith(color: AppColors.textTertiary);

  TextStyle mutedDark() => copyWith(color: AppColors.textTertiaryOnDark);

  TextStyle mutedOf(Brightness brightness) =>
      brightness == Brightness.dark ? mutedDark() : muted;

  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);

  TextStyle get semibold => copyWith(fontWeight: FontWeight.w600);

  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);

  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  TextStyle gradient(Gradient _) => copyWith(color: AppColors.primary);

  TextStyle get primaryGradient => copyWith(color: AppColors.primary);

  TextStyle glow(Color color) => copyWith(
        shadows: [
          Shadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      );

  TextStyle get primaryGlow => glow(AppColors.primary);

  TextStyle get underline => copyWith(
        decoration: TextDecoration.underline,
        decorationColor: color,
        decorationThickness: 1.5,
      );

  TextStyle get wide => copyWith(letterSpacing: (letterSpacing ?? 0) + 0.5);

  TextStyle get tight => copyWith(letterSpacing: (letterSpacing ?? 0) - 0.25);
}
