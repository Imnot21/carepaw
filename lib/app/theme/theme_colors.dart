import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware color resolver.
///
/// Provides colors that automatically adapt to light/dark brightness. Used
/// across the app instead of raw [AppColors] constants so every surface
/// resolves correctly in both modes.
class ThemeColors {
  ThemeColors._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primary(BuildContext context) =>
      _isDark(context) ? AppColors.primaryOnDark : AppColors.primary;

  /// Accent for text/icons on the canvas.
  ///
  /// Deeper than the fill accent in light mode so labels, links, and glyphs
  /// pass 4.5:1 on the bone canvas, white cards, and accent tints. In dark
  /// mode the lightened accent already passes, so both return `primaryOnDark`.
  static Color primaryText(BuildContext context) =>
      _isDark(context) ? AppColors.primaryOnDark : AppColors.primaryText;

  static Color primaryLight(BuildContext context) =>
      _isDark(context) ? AppColors.primaryLight : AppColors.primaryLight;

  static Color primaryDark(BuildContext context) =>
      _isDark(context) ? AppColors.primaryDark : AppColors.primaryDark;

  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? AppColors.textPrimaryOnDark : AppColors.textPrimary;

  static Color textSecondary(BuildContext context) => _isDark(context)
      ? AppColors.textSecondaryOnDark
      : AppColors.textSecondary;

  static Color textTertiary(BuildContext context) =>
      _isDark(context) ? AppColors.textTertiaryOnDark : AppColors.textTertiary;

  static Color success(BuildContext context) =>
      _isDark(context) ? AppColors.successOnDark : AppColors.success;

  static Color error(BuildContext context) =>
      _isDark(context) ? AppColors.errorOnDark : AppColors.error;

  static Color warning(BuildContext context) =>
      _isDark(context) ? AppColors.warningOnDark : AppColors.warning;

  static Color info(BuildContext context) =>
      _isDark(context) ? AppColors.infoDark : AppColors.info;

  /// Teal for "progress" tones — scan states, in-progress visits.
  static Color progress(BuildContext context) =>
      _isDark(context) ? AppColors.progressOnDark : AppColors.progress;

  /// Text/glyph colour **on** a full-strength status-tone fill: white on the
  /// deep light-mode tones, warm ink on their lightened dark-mode versions.
  static Color onStatus(BuildContext context) =>
      _isDark(context) ? AppColors.primaryInk : AppColors.textOnPrimary;

  static Color surface(BuildContext context) =>
      _isDark(context) ? AppColors.surfaceDarkMode : AppColors.surface;

  static Color background(BuildContext context) =>
      _isDark(context) ? AppColors.backgroundDark : AppColors.background;

  static Color border(BuildContext context) =>
      _isDark(context) ? AppColors.borderDark : AppColors.border;

  static Color surfaceVariant(BuildContext context) => _isDark(context)
      ? AppColors.surfaceVariantDark
      : AppColors.surfaceVariant;

  static Color surfaceInset(BuildContext context) =>
      _isDark(context) ? AppColors.surfaceInsetDark : AppColors.surfaceInset;

  static Color surfaceMuted(BuildContext context) =>
      _isDark(context) ? AppColors.surfaceMutedDark : AppColors.surfaceMuted;

  /// Emphasized hairline — focused fields, selected chips, active outlines.
  static Color borderStrong(BuildContext context) =>
      _isDark(context) ? AppColors.borderStrongDark : AppColors.borderStrong;

  static Color surfaceContainer(BuildContext context) => _isDark(context)
      ? AppColors.surfaceContainerDark
      : AppColors.surfaceContainer;

  static Color divider(BuildContext context) =>
      _isDark(context) ? AppColors.dividerDark : AppColors.divider;

  /// Top-left light source for extruded surfaces.
  static Color shadowLight(BuildContext context) =>
      _isDark(context) ? AppColors.shadowLightDark : AppColors.shadowLight;

  /// Bottom-right depth shadow for extruded surfaces.
  static Color shadowDepth(BuildContext context) =>
      _isDark(context) ? AppColors.shadowDepthDark : AppColors.shadowDepth;

  /// Drop shadow for floating chrome — nav bar, FAB, dialog, sheet.
  static Color shadowFloating(BuildContext context) =>
      _isDark(context) ? AppColors.shadowDepthDark : AppColors.shadowFloating;

  /// Text/glyph colour **on** an accent fill.
  ///
  /// Both modes use the warm near-black: white fails on the terracotta fill
  /// (2.9:1 light) and on the lightened dark-mode fill (2.3:1), while the
  /// ink clears 5.5:1 and 6.8:1 respectively.
  static Color onPrimary(BuildContext context) => AppColors.primaryInk;
}
