import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import 'neu_container.dart';
import 'neu_shadows.dart';

/// Neumorphic linear progress bar.
///
/// A recessed channel with a raised blue fill. Use for queue position, visit
/// progress, stock levels, and multi-step flows.
class NeuProgress extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;
  final bool rounded;

  /// Clamp value into 0..1.
  const NeuProgress({
    super.key,
    required this.value,
    this.height = 10,
    this.color,
    this.trackColor,
    this.rounded = true,
  }) : assert(value >= 0 && value <= 1, 'value must be 0..1');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = color ?? ThemeColors.primary(context);
    final channel = trackColor ??
        (isDark ? AppColors.surfaceContainerDark : AppColors.surfaceInset);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth =
              constraints.maxWidth * value.clamp(0.0, 1.0).toDouble();
          return Stack(
            children: [
              // Recessed channel
              Positioned.fill(
                child: CustomPaint(
                  foregroundPainter: NeuInsetPainter(
                    shadows: NeuShadow.inset(
                      context,
                      distance: math.max(1.5, height * 0.25),
                      blur: math.max(3, height),
                      spread: -math.max(1.0, height * 0.15),
                    ),
                    borderRadius: rounded ? height / 2 : 4,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: channel,
                      borderRadius: BorderRadius.circular(rounded ? height / 2 : 4),
                    ),
                  ),
                ),
              ),
              // Raised fill
              if (fillWidth > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: fillWidth,
                    height: height,
                    child: NeuContainer(
                      borderRadius: rounded ? height / 2 : 4,
                      variant: NeuVariant.pressed,
                      color: fillColor,
                      child: const SizedBox.shrink(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Neumorphic circular progress indicator.
///
/// A recessed ring with a raised blue arc. Use for loading states and
/// deterministic counts (e.g. stock remaining).
class NeuCircularProgress extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final bool showValue;

  const NeuCircularProgress({
    super.key,
    this.value = -1,
    this.size = 48,
    this.strokeWidth = 6,
    this.color,
    this.showValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color ?? ThemeColors.primary(context);
    final channel = isDark ? AppColors.surfaceContainerDark : AppColors.surfaceInset;

    final progress = value < 0
        ? SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              foregroundPainter: NeuInsetPainter(
                shadows: NeuShadow.inset(context, distance: 2, blur: 5, spread: -2),
                borderRadius: size / 2,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: CircularProgressIndicator(
                  strokeWidth: strokeWidth,
                  color: accent,
                ),
              ),
            ),
          )
        : SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              foregroundPainter: NeuInsetPainter(
                shadows: NeuShadow.inset(context, distance: 2, blur: 5, spread: -2),
                borderRadius: size / 2,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: strokeWidth,
                  color: accent,
                  backgroundColor: channel,
                ),
              ),
            ),
          );

    if (!showValue) return progress;
    return Stack(
      alignment: Alignment.center,
      children: [
        progress,
        Text(
          '${(value.clamp(0, 1) * 100).round()}%',
          style: TextStyle(
            fontSize: size * 0.22,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    );
  }
}