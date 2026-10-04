import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/design_tokens.dart';
import 'neu_shadows.dart';
import 'neu_style.dart';

/// Visual plane a surface occupies.
///
/// The variant selects a **plane and a lighting state**, not just an amount of
/// extrusion — which side is lit is part of what the variant means.
///
/// - [raised] — a card sitting proud of the canvas, lit from the top-left. The
///   workhorse.
/// - [pressed] — the same card held down: the light and depth swap, so it
///   appears to sink into the canvas. No scale change.
/// - [inset] — a recessed well for input fields and tracks. Always filled,
///   never outlined, so it reads as "put something here".
/// - [flat] — flush with its parent. Quiet grouping, no extrusion, no edge.
/// - [transparent] — no plane at all; padding and layout only.
enum NeuVariant { raised, pressed, inset, flat, transparent }

/// Base surface with fill level and hairline edge.
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
  final NeumorphicStyle? style;

  /// Set false to drop the hairline on a bordered variant — for a card whose
  /// parent already supplies one, so edges do not double up.
  final bool showBorder;

  const NeuContainer({
    super.key,
    required this.child,
    this.variant = NeuVariant.raised,
    this.borderRadius = NeuTokens.radiusMd,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderColor,
    this.borderWidth = 0,
    this.boxShadow,
    this.onTap,
    this.gradient,
    this.shape,
    this.style,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = style;
    final resolvedVariant = resolvedStyle?.variant ?? variant;
    final resolvedBorderRadius = resolvedStyle?.borderRadius ?? borderRadius;
    final effectiveColor =
        resolvedStyle?.resolveColor(context) ??
        (color ?? _resolveFill(context, resolvedVariant));
    final effectiveShape =
        resolvedStyle?.shape ??
        (shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(resolvedBorderRadius),
            ));

    final resolvedBorderWidth = resolvedStyle?.borderWidth ?? borderWidth;
    // An explicit fill means the caller has already chosen the plane — a
    // neutral hairline around an accent fill reads as a defect, not an edge.
    final resolvedBorderColor =
        borderColor ??
        (color != null
            ? null
            : (resolvedStyle?.resolveBorderColor(context) ??
                  _defaultBorderColor(context, resolvedVariant)));
    final resolvedPadding = resolvedStyle?.padding ?? padding;
    final resolvedBoxShadow =
        boxShadow ??
        resolvedStyle?.resolveShadows(context) ??
        _resolveShadow(context, resolvedVariant);

    final border =
        showBorder && resolvedBorderColor != null && resolvedBorderWidth > 0
        ? _withBorder(effectiveShape, resolvedBorderColor, resolvedBorderWidth)
        : effectiveShape;

    return Container(
      margin: margin,
      padding: resolvedPadding,
      decoration: ShapeDecoration(
        color: gradient == null ? effectiveColor : null,
        gradient: gradient,
        shape: border,
        shadows: resolvedBoxShadow,
      ),
      child: onTap == null
          ? child
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
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

  /// The fill for each plane.
  ///
  /// Light mode steps *down* from the canvas for recessed wells; dark mode
  /// steps down too, so a field is always visibly below a card.
  Color _resolveFill(BuildContext context, NeuVariant resolvedVariant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (resolvedVariant) {
      NeuVariant.transparent => Colors.transparent,
      NeuVariant.inset =>
        isDark ? AppColors.surfaceInsetDark : AppColors.surfaceInset,
      NeuVariant.flat || NeuVariant.pressed =>
        isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
      NeuVariant.raised =>
        isDark ? AppColors.surfaceDarkMode : AppColors.surface,
    };
  }

  /// The default edge for each plane.
  ///
  /// None by default. In an extruded system a hairline and a highlight fight
  /// each other — both are trying to describe the same edge — so ordinary
  /// surfaces let the shadow pair carry the silhouette. A caller opts into a
  /// hairline explicitly, and should do so only where the edge carries data
  /// rather than decoration: queue position, batch expiry, a destructive row.
  ///
  /// A well is never outlined under any circumstance. An edge around a
  /// recessed field reads as an error state rather than as somewhere to type.
  Color? _defaultBorderColor(BuildContext context, NeuVariant resolvedVariant) {
    return switch (resolvedVariant) {
      NeuVariant.raised ||
      NeuVariant.pressed ||
      NeuVariant.inset ||
      NeuVariant.flat ||
      NeuVariant.transparent => null,
    };
  }

  /// The extrusion for each plane.
  ///
  /// Each variant gets its own pair rather than a scaled version of one pair:
  /// a card is lit from the top-left, a pressed card is lit from the
  /// bottom-right, and a well is a cavity. `flat` is genuinely flat.
  List<BoxShadow>? _resolveShadow(
    BuildContext context,
    NeuVariant resolvedVariant,
  ) {
    return switch (resolvedVariant) {
      NeuVariant.raised => NeuShadow.raised(context),
      NeuVariant.pressed => NeuShadow.pressed(context),
      NeuVariant.inset => NeuShadow.inset(context),
      NeuVariant.flat || NeuVariant.transparent => NeuShadow.flat(context),
    };
  }
}
