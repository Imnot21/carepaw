import 'package:flutter/material.dart';
import 'app_colors.dart';

/// CarePaw neomorphism typography scale.
///
/// Clean, readable type hierarchy that sits on the soft-gray neomorphic
/// canvas. Colors derive from the blue + soft-gray palette. The former
/// gradient & glow effects are removed in favor of flat, accessible colors —
/// visual depth now comes from neumorphic shadows, not text effects.
class AppTextStyles {
  AppTextStyles._();

  // ============ Display Styles ============
  // For large, short text like headlines, hero sections

  static const TextStyle displayLarge = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.22,
  );

  // ============ Headline Styles ============
  // For section headers, page titles

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  // ============ Title Styles ============
  // For component titles, card titles

  static const TextStyle titleLarge = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ============ Body Styles ============
  // For longer content, paragraphs

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.4,
  );

  // ============ Label Styles ============
  // For buttons, inputs, chips

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.45,
  );

  // ============ Specialized Styles ============

  /// For app bar titles
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.4,
  );

  /// For card titles
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.05,
    height: 1.5,
  );

  /// For overline text (small labels, categories)
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    height: 1.6,
  );

  /// For caption text (timestamps, metadata)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.33,
  );

  /// For button text
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.43,
  );

  /// For numbers (prices, counts, statistics)
  static const TextStyle numberLarge = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static const TextStyle numberMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle numberSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.3,
  );

  /// For code/technical text
  static const TextStyle code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
  );

  // ============ Color Text Helpers (flat, neomorphism-appropriate) ============

  /// Primary-colored text (accent blue)
  static TextStyle primary(TextStyle style) => style.copyWith(color: AppColors.primary);

  /// Secondary text (soft gray)
  static TextStyle secondary(TextStyle style) => style.copyWith(color: AppColors.textSecondary);

  /// Tertiary-text alias (kept for legacy call sites) — teal accent.
  static TextStyle tertiary(TextStyle style) => style.copyWith(color: AppColors.tertiary);

  /// Subtle text (for secondary content) - light theme
  static TextStyle subtle(TextStyle style) => style.copyWith(color: AppColors.textSecondary);

  /// Subtle text (for secondary content) - dark theme
  static TextStyle subtleDark(TextStyle style) => style.copyWith(color: AppColors.textSecondaryOnDark);

  /// Muted text (for tertiary content) - light theme
  static TextStyle muted(TextStyle style) => style.copyWith(color: AppColors.textTertiary);

  /// Muted text (for tertiary content) - dark theme
  static TextStyle mutedDark(TextStyle style) => style.copyWith(color: AppColors.textTertiaryOnDark);

  /// High contrast text (emphasis)
  static TextStyle highContrast(TextStyle style) => style.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      );

  /// Link text
  static TextStyle link(TextStyle style) => style.copyWith(
        color: AppColors.primary,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.primary,
        decorationThickness: 1.5,
      );

  /// Success text
  static TextStyle successText(TextStyle style) => style.copyWith(color: AppColors.success);

  /// Warning text
  static TextStyle warningText(TextStyle style) => style.copyWith(color: AppColors.warning);

  /// Error text
  static TextStyle error(TextStyle style) => style.copyWith(color: AppColors.error);

  /// Info text
  static TextStyle info(TextStyle style) => style.copyWith(color: AppColors.info);

  // ============ Legacy Effect API (flattened / deprioritized) ============

  /// Legacy gradient — flattened to solid primary color for neomorphism.
  static TextStyle gradient(TextStyle style, Gradient _) => style.copyWith(color: AppColors.primary);

  /// Primary gradient text — flattened to primary color.
  static TextStyle primaryGradient(TextStyle style) => style.copyWith(color: AppColors.primary);

  /// Legacy glow — replaced with a subtle soft shadow.
  static TextStyle glow(TextStyle style, Color color) => style.copyWith(
        shadows: [
          Shadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      );

  /// Primary glow text
  static TextStyle primaryGlow(TextStyle style) => glow(style, AppColors.primary);

  /// Success glow text
  static TextStyle successGlow(TextStyle style) => glow(style, AppColors.success);

  /// Warning glow text
  static TextStyle warningGlow(TextStyle style) => glow(style, AppColors.warning);

  /// Error glow text
  static TextStyle errorGlow(TextStyle style) => glow(style, AppColors.error);
}

/// Extension for easy text style modifications.
extension TextStyleX on TextStyle {
  /// Apply color with weight
  TextStyle withColor(Color color, {FontWeight? weight}) => copyWith(
        color: color,
        fontWeight: weight,
      );

  /// Make text subtle (light theme)
  TextStyle get subtle => copyWith(color: AppColors.textSecondary);

  /// Make text subtle (dark theme)
  TextStyle subtleDark() => copyWith(color: AppColors.textSecondaryOnDark);

  /// Make text subtle - theme aware (requires Brightness)
  TextStyle subtleOf(Brightness brightness) =>
      brightness == Brightness.dark ? subtleDark() : subtle;

  /// Make text muted (light theme)
  TextStyle get muted => copyWith(color: AppColors.textTertiary);

  /// Make text muted (dark theme)
  TextStyle mutedDark() => copyWith(color: AppColors.textTertiaryOnDark);

  /// Make text muted - theme aware (requires Brightness)
  TextStyle mutedOf(Brightness brightness) => brightness == Brightness.dark ? mutedDark() : muted;

  /// Make text bold
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);

  /// Make text semibold
  TextStyle get semibold => copyWith(fontWeight: FontWeight.w600);

  /// Make text medium
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// Make text regular
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);

  /// Make text light
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  /// Add gradient (flattened to primary color).
  TextStyle gradient(Gradient _) => copyWith(color: AppColors.primary);

  /// Add primary gradient (flattened to primary color).
  TextStyle get primaryGradient => copyWith(color: AppColors.primary);

  /// Add glow effect (subtle soft shadow).
  TextStyle glow(Color color) => copyWith(
        shadows: [
          Shadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      );

  /// Add primary glow
  TextStyle get primaryGlow => glow(AppColors.primary);

  /// Add underline for links
  TextStyle get underline => copyWith(
        decoration: TextDecoration.underline,
        decorationColor: color,
        decorationThickness: 1.5,
      );

  /// Increase letter spacing
  TextStyle get wide => copyWith(letterSpacing: (letterSpacing ?? 0) + 0.5);

  /// Decrease letter spacing
  TextStyle get tight => copyWith(letterSpacing: (letterSpacing ?? 0) - 0.25);
}