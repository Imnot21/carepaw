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

  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? AppColors.textSecondaryOnDark : AppColors.textSecondary;

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

  static Color surfaceVariant(BuildContext context) =>
      _isDark(context) ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;

  static Color surfaceInset(BuildContext context) =>
      _isDark(context) ? AppColors.surfaceInsetDark : AppColors.surfaceInset;

  static Color onPrimary(BuildContext context) => AppColors.textOnPrimary;
}
