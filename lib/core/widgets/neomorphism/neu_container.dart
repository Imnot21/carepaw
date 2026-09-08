import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import 'neu_shadows.dart';

/// Variant controlling how a neumorphic surface presents depth.
enum NeuVariant { raised, pressed, inset, flat, transparent }

/// Base neomorphism surface.
///
/// Every elevated element in CarePaw sits on this primitive: a rounded surface
/// tinted to match the canvas, casting a dual light/dark shadow. Setting
/// [pressed] is the raised active-plate look; [inset] renders the recessed
/// sunken field used for inputs. Use this directly for arbitrary layouts, or
/// the specialized [`NeuCard`]/[`NeuButton`] wrappers for common cases.
class NeuContainer extends StatelessWidget {
  final Widget child;
  final NeuVariant variant;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const NeuContainer({
    super.key,
    required this.child,
    this.variant = NeuVariant.raised,
    this.borderRadius = 20,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderColor,
    this.borderWidth = 0,
    this.boxShadow,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _resolveSurface(context);

    if (variant == NeuVariant.inset) {
      return _buildInset(context, effectiveColor);
    }

    final decoration = BoxDecoration(
      color: gradient == null ? effectiveColor : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderColor != null
          ? Border.all(color: borderColor!, width: borderWidth)
          : null,
      boxShadow: boxShadow ?? _resolveShadow(context, variant),
    );

    return Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }

  /// Sunken field: surface color + inset edge shadows painted on top.
  Widget _buildInset(BuildContext context, Color surfaceColor) {
    return CustomPaint(
      foregroundPainter: NeuInsetPainter(
        shadows: NeuShadow.inset(context),
        borderRadius: borderRadius,
      ),
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: borderWidth)
              : null,
        ),
        child: child,
      ),
    );
  }

  Color _resolveSurface(BuildContext context) {
    switch (variant) {
      case NeuVariant.transparent:
        return Colors.transparent;
      case NeuVariant.inset:
        return Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceDark;
      default:
        return Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDarkMode
            : AppColors.surface;
    }
  }

  List<BoxShadow>? _resolveShadow(BuildContext context, NeuVariant variant) {
    switch (variant) {
      case NeuVariant.raised:
        return NeuShadow.raised(context);
      case NeuVariant.pressed:
        return NeuShadow.pressed(context);
      case NeuVariant.inset:
        return NeuShadow.none;
      case NeuVariant.flat:
        return NeuShadow.flat(context);
      case NeuVariant.transparent:
        return NeuShadow.none;
    }
  }
}