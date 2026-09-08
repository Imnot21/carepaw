import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

/// Neomorphism shadow system.
///
/// The core of the design language. Every raised element casts a **dual
/// shadow**: a white (or lighter-than-canvas) light source from the upper-left
/// and a muted blue-gray (or darker-than-canvas) depth shadow from the
/// lower-right. Pressed elements invert this so they look pushed into the
/// surface.
///
/// Shadows resolve by [`Brightness`]: light mode uses a white light source,
/// dark mode inverts the source so the light comes from below (embossed).
///
/// Note: this Flutter build's [`BoxShadow`] has no `inset` parameter, so the
/// sunken effect is rendered by [`NeuInsetPainter`] instead of BoxShadow lists.
class NeuShadow {
  NeuShadow._();

  /// Resolve the canvas color for the current brightness.
  static Color _surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDarkMode
          : AppColors.surface;

  /// Resolve the light-source shadow color for the current brightness.
  static Color _light(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.shadowLightOnDark
          : AppColors.shadowLight;

  /// Resolve the depth shadow color for the current brightness.
  static Color _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.shadowDarkOnDark
          : AppColors.shadowDark;

  /// The surface color a neumorphic element should render on.
  static Color surfaceOf(BuildContext context) => _surface(context);

  /// Raised (default) — the surface appears to float above the canvas.
  static List<BoxShadow> raised(
    BuildContext context, {
    double distance = 6,
    double blur = 12,
    double? spread,
  }) {
    return [
      BoxShadow(
        color: _dark(context).withValues(alpha: 0.28),
        offset: Offset(distance, distance),
        blurRadius: blur,
        spreadRadius: spread ?? 0,
      ),
      BoxShadow(
        color: _light(context).withValues(alpha: 0.6),
        offset: Offset(-distance, -distance),
        blurRadius: blur * 0.9,
        spreadRadius: spread ?? 0,
      ),
    ];
  }

  /// Pressed-looking raised plate — moderate dual shadow for active buttons.
  static List<BoxShadow> pressed(
    BuildContext context, {
    double distance = 4,
    double blur = 8,
  }) {
    return [
      BoxShadow(
        color: _dark(context).withValues(alpha: 0.22),
        offset: Offset(distance, distance),
        blurRadius: blur,
      ),
      BoxShadow(
        color: _light(context).withValues(alpha: 0.5),
        offset: Offset(-distance, -distance),
        blurRadius: blur,
      ),
    ];
  }

  /// Flat — minimal shadow, for secondary/muted elements.
  static List<BoxShadow> flat(
    BuildContext context, {
    double distance = 3,
    double blur = 7,
  }) {
    return [
      BoxShadow(
        color: _dark(context).withValues(alpha: 0.16),
        offset: Offset(distance, distance),
        blurRadius: blur,
      ),
      BoxShadow(
        color: _light(context).withValues(alpha: 0.4),
        offset: Offset(-distance, -distance),
        blurRadius: blur,
      ),
    ];
  }

  /// No shadow — for transparent / ghost elements.
  static const List<BoxShadow> none = [];

  /// A single colored glow — for status accents (selected chips, badges).
  static List<BoxShadow> color(
    BuildContext context,
    Color color, {
    double blur = 18,
    double opacity = 0.35,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: 1,
      ),
    ];
  }

  /// Sunken (inset) shadow spec — dark edge upper-left, light edge lower-right.
  static List<NeuInsetShadow> inset(
    BuildContext context, {
    double distance = 4,
    double blur = 9,
    double spread = -1,
  }) {
    return [
      NeuInsetShadow(
        color: _dark(context).withValues(alpha: 0.3),
        offset: Offset(distance, distance),
        blurRadius: blur,
        spread: spread,
      ),
      NeuInsetShadow(
        color: _light(context).withValues(alpha: 0.6),
        offset: Offset(-distance, -distance),
        blurRadius: blur,
        spread: spread,
      ),
    ];
  }
}

/// One edge-shadow of a sunken surface. Rendered by [`NeuInsetPainter`].
@immutable
class NeuInsetShadow {
  final Color color;
  final Offset offset;
  final double blurRadius;
  final double spread;

  const NeuInsetShadow({
    required this.color,
    required this.offset,
    required this.blurRadius,
    this.spread = -1,
  });

  @override
  bool operator ==(Object other) =>
      other is NeuInsetShadow &&
      other.color == color &&
      other.offset == offset &&
      other.blurRadius == blurRadius &&
      other.spread == spread;

  @override
  int get hashCode => Object.hash(color, offset, blurRadius, spread);
}

/// Paints sunken (inset) edge shadows clipped to a rounded rectangle.
///
/// `BoxShadow` in this Flutter build cannot render true inset shadows, so this
/// painter draws translated, blurred copies of the rounded-rect path clipped to
/// its own bounds — producing the classic neumorphic recessed edge.
class NeuInsetPainter extends CustomPainter {
  final List<NeuInsetShadow> shadows;
  final double borderRadius;

  const NeuInsetPainter({
    required this.shadows,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shadows.isEmpty) return;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final clipPath = Path()..addRRect(rrect);

    canvas.save();
    canvas.clipPath(clipPath);
    for (final shadow in shadows) {
      final path = Path()
        ..addRRect(rrect.shift(shadow.offset).inflate(shadow.spread));
      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, shadow.blurRadius * 0.5);
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(NeuInsetPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      !listEquals(oldDelegate.shadows, shadows);
}