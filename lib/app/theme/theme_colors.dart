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

  static Color onPrimary(BuildContext context) => AppColors.textOnPrimary;
}
