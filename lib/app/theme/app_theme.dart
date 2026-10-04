import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'design_tokens.dart';

/// CarePaw theme — warm bone canvas, terracotta primary, warm charcoal dark
/// mode.
///
/// The Material theme is the base for standard widgets; the visual identity is
/// carried by the `Neu*` widget set, which reads
/// `Theme.of(context).brightness` and [`AppColors`] to resolve its hairline
/// border and surface tint system. Every Material component here is themed to
/// match that system, so a stray `TextField` or `Switch` on a feature page
/// still looks like it belongs.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const brightness = Brightness.light;
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primaryTint,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.textSecondary,
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: AppColors.surfaceContainer,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.success,
      onTertiary: AppColors.textOnPrimary,
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF991B1B),
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerLowest: AppColors.background,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHighest,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      shadow: const Color(0xFF7A6E5E),
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.background,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.comfortable,
      fontFamily: null,
      textTheme: _baseTextTheme(AppColors.textPrimary, AppColors.textSecondary),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.appBarTitle.copyWith(
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        toolbarHeight: 64,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceInset,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: TextStyle(
          color: brightness == Brightness.light
              ? AppColors.textPrimary
              : AppColors.textPrimaryOnDark,
        ),
        hintStyle: TextStyle(
          color: brightness == Brightness.light
              ? AppColors.textSecondary
              : AppColors.textSecondaryOnDark,
        ),
        errorStyle: TextStyle(
          color: brightness == Brightness.light
              ? AppColors.error
              : AppColors.errorOnDark,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryTint,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return AppTextStyles.labelMedium.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryTint,
        disabledColor: AppColors.surfaceContainerHighest,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.border,
        ),
        thumbColor: WidgetStateProperty.all(AppColors.textOnPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.background,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusLg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryTint,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    );
  }

  static ThemeData get darkTheme {
    const brightness = Brightness.dark;
    const scheme = ColorScheme.dark(
      primary: AppColors.primaryOnDark,
      onPrimary: Color(0xFF1C1917),
      primaryContainer: Color(0xFF3A2A26),
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.textSecondaryOnDark,
      onSecondary: Color(0xFF1C1917),
      secondaryContainer: AppColors.surfaceContainerDark,
      onSecondaryContainer: AppColors.textPrimaryOnDark,
      tertiary: AppColors.successOnDark,
      onTertiary: Color(0xFF1C1917),
      error: AppColors.errorOnDark,
      onError: Color(0xFF2A0A0A),
      errorContainer: Color(0xFF4C1D1D),
      onErrorContainer: Color(0xFFFEB2B2),
      surface: AppColors.surfaceDarkMode,
      onSurface: AppColors.textPrimaryOnDark,
      surfaceContainerLowest: AppColors.backgroundDark,
      surfaceContainer: AppColors.surfaceContainerDark,
      surfaceContainerHigh: Color(0xFF3A3532),
      surfaceContainerHighest: Color(0xFF3D3937),
      outline: AppColors.borderDark,
      outlineVariant: AppColors.dividerDark,
      shadow: const Color(0xFF000000),
      inverseSurface: AppColors.textPrimaryOnDark,
      onInverseSurface: AppColors.backgroundDark,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.comfortable,
      fontFamily: null,
      textTheme: _baseTextTheme(
        AppColors.textPrimaryOnDark,
        AppColors.textSecondaryOnDark,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryOnDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.appBarTitle.copyWith(
          color: AppColors.textPrimaryOnDark,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnDark),
        toolbarHeight: 64,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceDarkMode,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOnDark,
          foregroundColor: const Color(0xFF1C1917),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryOnDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          ),
          side: const BorderSide(color: AppColors.primaryOnDark, width: 1),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryOnDark,
          textStyle: AppTextStyles.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceInsetDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.primaryOnDark,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.errorOnDark,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.errorOnDark,
            width: 1.5,
          ),
        ),
        labelStyle: TextStyle(
          color: brightness == Brightness.light
              ? AppColors.textPrimary
              : AppColors.textPrimaryOnDark,
        ),
        hintStyle: TextStyle(
          color: brightness == Brightness.light
              ? AppColors.textSecondary
              : AppColors.textSecondaryOnDark,
        ),
        errorStyle: TextStyle(
          color: brightness == Brightness.light
              ? AppColors.error
              : AppColors.errorOnDark,
        ),
        prefixIconColor: AppColors.textSecondaryOnDark,
        suffixIconColor: AppColors.textSecondaryOnDark,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDarkMode,
        selectedItemColor: AppColors.primaryOnDark,
        unselectedItemColor: AppColors.textSecondaryOnDark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDarkMode,
        indicatorColor: AppColors.primaryDark,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return AppTextStyles.labelMedium.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryOnDark
                : AppColors.textSecondaryOnDark,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDarkMode,
        selectedColor: AppColors.primaryDark,
        disabledColor: AppColors.surfaceContainerHighest,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textPrimaryOnDark,
        ),
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryOnDark
              : AppColors.borderDark,
        ),
        thumbColor: WidgetStateProperty.all(AppColors.textPrimaryOnDark),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryOnDark,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.backgroundDark,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDarkMode,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuTokens.radiusLg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDarkMode,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryOnDark,
        linearTrackColor: AppColors.primaryDark,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimaryOnDark),
    );
  }

  static TextTheme _baseTextTheme(Color primary, Color secondary) {
    return const TextTheme()
        .apply(bodyColor: primary, displayColor: primary)
        .copyWith(
          displayLarge: AppTextStyles.displayLarge.copyWith(color: primary),
          displayMedium: AppTextStyles.displayMedium.copyWith(color: primary),
          displaySmall: AppTextStyles.displaySmall.copyWith(color: primary),
          headlineLarge: AppTextStyles.headlineLarge.copyWith(color: primary),
          headlineMedium: AppTextStyles.headlineMedium.copyWith(color: primary),
          headlineSmall: AppTextStyles.headlineSmall.copyWith(color: primary),
          titleLarge: AppTextStyles.titleLarge.copyWith(color: primary),
          titleMedium: AppTextStyles.titleMedium.copyWith(color: primary),
          titleSmall: AppTextStyles.titleSmall.copyWith(color: primary),
          bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
          bodyMedium: AppTextStyles.bodyMedium.copyWith(color: primary),
          bodySmall: AppTextStyles.bodySmall.copyWith(color: primary),
          labelLarge: AppTextStyles.labelLarge.copyWith(color: primary),
          labelMedium: AppTextStyles.labelMedium.copyWith(color: secondary),
          labelSmall: AppTextStyles.labelSmall.copyWith(color: secondary),
        );
  }
}
