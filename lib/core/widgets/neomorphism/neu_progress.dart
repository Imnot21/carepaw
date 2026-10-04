import 'package:flutter/material.dart';
import '../../../app/theme/design_tokens.dart';

/// Linear progress bar.
///
/// A recessed well with an accent fill. No extrusion — the fill's contrast
/// against the track is what communicates progress.
class NeuProgress extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;
  final bool rounded;

  const NeuProgress({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
    this.trackColor,
    this.rounded = true,
  }) : assert(value >= 0 && value <= 1, 'value must be 0..1');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = color ?? ThemeColors.primary(context);
    final channel =
        trackColor ??
        (isDark ? AppColors.surfaceInsetDark : AppColors.surfaceInset);
    final radius = rounded ? height / 2 : NeuTokens.radiusXs;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth =
              constraints.maxWidth * value.clamp(0.0, 1.0).toDouble();
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: channel,
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
              if (fillWidth > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: fillWidth,
                    height: height,
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(radius),
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

/// Circular progress indicator.
///
/// A plain accent arc on a muted track.
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
    final channel = isDark
        ? AppColors.surfaceInsetDark
        : AppColors.surfaceInset;
    final isIndeterminate = value < 0;

    final progress = RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: CircularProgressIndicator(
            value: isIndeterminate ? null : value,
            strokeWidth: strokeWidth,
            color: accent,
            backgroundColor: isIndeterminate ? null : channel,
            strokeCap: StrokeCap.round,
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
