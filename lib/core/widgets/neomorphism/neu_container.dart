import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import 'neu_shadows.dart';
import 'neu_shapes.dart';

enum NeuVariant { raised, pressed, inset, flat, transparent }

/// Base neumorphic surface with organic shape support.
///
/// The material layer of Soft Clinic: every surface is a soft-extruded plate
/// with dual light/dark shadows. Organic shapes (flowing radii, squircle
/// contours, blob forms) come from [NeuShape].
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
  final ShapeBorder? shape;

  const NeuContainer({
    super.key,
    required this.child,
    this.variant = NeuVariant.raised,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderColor,
    this.borderWidth = 0,
    this.boxShadow,
    this.onTap,
    this.gradient,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _resolveSurface(context);
    final effectiveShape = shape ?? RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    if (variant == NeuVariant.inset) {
      return _buildInset(context, effectiveColor, effectiveShape);
    }

    final decoratedShape = borderColor != null
        ? _withBorder(effectiveShape, borderColor!, borderWidth)
        : effectiveShape;

    final decoration = ShapeDecoration(
      color: gradient == null ? effectiveColor : null,
      gradient: gradient,
      shape: decoratedShape,
      shadows: boxShadow ?? _resolveShadow(context, variant),
    );

    return Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }

  Widget _buildInset(
    BuildContext context,
    Color surfaceColor,
    ShapeBorder effectiveShape,
  ) {
    final rrect = _shapeToRRect(effectiveShape);
    final decoratedShape = borderColor != null
        ? _withBorder(effectiveShape, borderColor!, borderWidth)
        : effectiveShape;

    return CustomPaint(
      foregroundPainter: NeuInsetPainter(
        shadows: NeuShadow.inset(context),
        borderRadius: rrect.tlRadius.x,
      ),
      child: Container(
        margin: margin,
        padding: padding,
        decoration: ShapeDecoration(
          color: surfaceColor,
          shape: decoratedShape,
        ),
        child: child,
      ),
    );
  }

  ShapeBorder _withBorder(ShapeBorder shape, Color color, double width) {
    if (shape is RoundedRectangleBorder) {
      return shape.copyWith(
        side: BorderSide(color: color, width: width),
      );
    }
    if (shape is ContinuousRectangleBorder) {
      return shape.copyWith(
        side: BorderSide(color: color, width: width),
      );
    }
    if (shape is CircleBorder) {
      return shape.copyWith(
        side: BorderSide(color: color, width: width),
      );
    }
    return shape;
  }

  RRect _shapeToRRect(ShapeBorder shape) {
    if (shape is RoundedRectangleBorder) {
      final br = shape.borderRadius;
      if (br is BorderRadius) {
        return RRect.fromRectAndCorners(
          Offset.zero & const Size(100, 100),
          topLeft: br.topLeft,
          topRight: br.topRight,
          bottomLeft: br.bottomLeft,
          bottomRight: br.bottomRight,
        );
      }
    }
    return RRect.fromRectAndRadius(
      Offset.zero & const Size(100, 100),
      const Radius.circular(20),
    );
  }

  Color _resolveSurface(BuildContext context) {
    switch (variant) {
      case NeuVariant.transparent:
        return Colors.transparent;
      case NeuVariant.inset:
        return Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceInsetDark
            : AppColors.surfaceInset;
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
