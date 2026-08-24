import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

/// Premium shadow system with layered depth.
///
/// Provides consistent elevation shadows across the app with:
/// - Multiple shadow layers for depth
/// - Colored shadows for premium elements
/// - Consistent elevation scale
class PremiumShadows {
  PremiumShadows._();

  // ============ Light Theme Shadows ============

  /// Level 1 - Barely visible (inputs, badges)
  static List<BoxShadow> get level1 => [
        BoxShadow(
          color: AppColors.shadow1,
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// Level 2 - Subtle (cards, buttons)
  static List<BoxShadow> get level2 => [
        BoxShadow(
          color: AppColors.shadow1,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: AppColors.shadow2,
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Level 3 - Medium (modals, dropdowns, floating cards)
  static List<BoxShadow> get level3 => [
        BoxShadow(
          color: AppColors.shadow1,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: AppColors.shadow2,
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.shadow3,
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];

  /// Level 4 - High (tooltips, popovers, sheets)
  static List<BoxShadow> get level4 => [
        BoxShadow(
          color: AppColors.shadow1,
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.shadow3,
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: AppColors.shadow4,
          blurRadius: 48,
          offset: const Offset(0, 24),
        ),
      ];

  /// Level 5 - Maximum (drawers, full-screen modals)
  static List<BoxShadow> get level5 => [
        BoxShadow(
          color: AppColors.shadow2,
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: AppColors.shadow4,
          blurRadius: 48,
          offset: const Offset(0, 24),
        ),
        BoxShadow(
          color: AppColors.shadow5,
          blurRadius: 64,
          offset: const Offset(0, 32),
        ),
      ];

  // ============ Dark Theme Shadows ============

  /// Level 1 - Dark theme
  static List<BoxShadow> get level1Dark => [
        BoxShadow(
          color: AppColors.shadowDark1,
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// Level 2 - Dark theme
  static List<BoxShadow> get level2Dark => [
        BoxShadow(
          color: AppColors.shadowDark1,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: AppColors.shadowDark2,
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Level 3 - Dark theme
  static List<BoxShadow> get level3Dark => [
        BoxShadow(
          color: AppColors.shadowDark1,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: AppColors.shadowDark2,
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.shadowDark3,
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];

  /// Level 4 - Dark theme
  static List<BoxShadow> get level4Dark => [
        BoxShadow(
          color: AppColors.shadowDark1,
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.shadowDark3,
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: AppColors.shadowDark4,
          blurRadius: 48,
          offset: const Offset(0, 24),
        ),
      ];

  /// Level 5 - Dark theme
  static List<BoxShadow> get level5Dark => [
        BoxShadow(
          color: AppColors.shadowDark2,
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: AppColors.shadowDark4,
          blurRadius: 48,
          offset: const Offset(0, 24),
        ),
        BoxShadow(
          color: AppColors.shadowDark5,
          blurRadius: 64,
          offset: const Offset(0, 32),
        ),
      ];

  // ============ Colored Shadows ============

  /// Primary colored shadow for primary buttons/cards
  static List<BoxShadow> get primary => [
        BoxShadow(
          color: AppColors.shadowPrimary,
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.1),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];

  /// Success colored shadow
  static List<BoxShadow> get success => [
        BoxShadow(
          color: AppColors.shadowSuccess,
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.success.withValues(alpha: 0.1),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];

  /// Warning colored shadow
  static List<BoxShadow> get warning => [
        BoxShadow(
          color: AppColors.shadowWarning,
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.warning.withValues(alpha: 0.1),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];

  /// Error colored shadow
  static List<BoxShadow> get error => [
        BoxShadow(
          color: AppColors.shadowError,
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.error.withValues(alpha: 0.1),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];

  // ============ Helper Methods ============

  /// Get shadow level for theme
  static List<BoxShadow> level(BuildContext context, int level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (level) {
      case 1:
        return isDark ? level1Dark : level1;
      case 2:
        return isDark ? level2Dark : level2;
      case 3:
        return isDark ? level3Dark : level3;
      case 4:
        return isDark ? level4Dark : level4;
      case 5:
        return isDark ? level5Dark : level5;
      default:
        return isDark ? level2Dark : level2;
    }
  }

  /// Get colored shadow
  static List<BoxShadow> coloredShadow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.3),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.1),
        blurRadius: 32,
        offset: const Offset(0, 16),
      ),
    ];
  }

  /// Glow shadow for premium elements (logo, featured items)
  static List<BoxShadow> glow(BuildContext context, Color color, {double intensity = 0.3}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseAlpha = isDark ? 0.4 : 0.3;
    return [
      BoxShadow(
        color: color.withValues( alpha: baseAlpha * intensity),
        blurRadius: 20,
        offset: const Offset(0, 10),
        spreadRadius: 2,
      ),
      BoxShadow(
        color: color.withValues( alpha: baseAlpha * intensity * 0.5),
        blurRadius: 40,
        offset: const Offset(0, 20),
        spreadRadius: 4,
      ),
      BoxShadow(
        color: color.withValues( alpha: baseAlpha * intensity * 0.25),
        blurRadius: 60,
        offset: const Offset(0, 30),
        spreadRadius: 6,
      ),
    ];
  }

  /// Custom shadow with configurable parameters
  static List<BoxShadow> custom({
    required Color color,
    double blurRadius = 16,
    double spreadRadius = 0,
    Offset offset = const Offset(0, 8),
    double opacity = 0.3,
  }) {
    return [
      BoxShadow(
        color: color.withValues( alpha: opacity),
        blurRadius: blurRadius,
        offset: offset,
        spreadRadius: spreadRadius,
      ),
    ];
  }
}

/// Premium card with elevated shadow.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final int elevation;
  final Color? color;
  final List<BoxShadow>? customShadow;
  final Border? border;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20,
    this.elevation = 2,
    this.color,
    this.customShadow,
    this.border,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ?? (isDark ? AppColors.surfaceDark : AppColors.surface);

    Widget card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: gradient == null ? bgColor : null,
        gradient: gradient,
        boxShadow: customShadow ?? PremiumShadows.level(context, elevation),
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Premium elevated button with shadow.
class PremiumElevatedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final List<BoxShadow>? shadow;
  final Gradient? gradient;
  final bool isLoading;
  final double? width;

  const PremiumElevatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.backgroundColor,
    this.foregroundColor,
    this.shadow,
    this.gradient,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final fgColor = foregroundColor ?? AppColors.textOnPrimary;

    Widget buttonChild = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        : child;

    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient,
        boxShadow: shadow ??
            (gradient != null
                ? PremiumShadows.coloredShadow(
                    gradient!.colors.first)
                : PremiumShadows.primary),
      ),
      child: Material(
        color: gradient != null ? Colors.transparent : bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            alignment: Alignment.center,
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              child: buttonChild,
            ),
          ),
        ),
      ),
    );
  }
}