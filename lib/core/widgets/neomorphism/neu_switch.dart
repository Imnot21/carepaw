import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import 'neu_container.dart';
import 'neu_shadows.dart';

/// Neumorphic toggle switch.
///
/// A recessed (inset-edged) track that fills with the blue accent when active.
/// The thumb is a small raised plate that slides across; the whole control
/// carries the physical pressed feel of the design language. The recessed
/// edges are painted by [`NeuInsetPainter`] so the track stays animatable.
class NeuSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const NeuSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const trackWidth = 56.0, trackHeight = 32.0;
    final trackColor = value
        ? AppColors.primary
        : (isDark ? AppColors.surfaceContainerDark : AppColors.surfaceDark);

    final track = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: trackWidth,
      height: trackHeight,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: trackColor,
        boxShadow: value
            ? NeuShadow.color(context, AppColors.primary, blur: 10, opacity: 0.35)
            : null,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: NeuContainer(
          borderRadius: 14,
          variant: value ? NeuVariant.pressed : NeuVariant.raised,
          child: SizedBox(
            width: 26,
            height: 26,
            child: value
                ? const Icon(Icons.check, size: 16, color: AppColors.textOnPrimary)
                : null,
          ),
        ),
      ),
    );

    // Recessed edge shadows painted over the animated track.
    final control = CustomPaint(
      foregroundPainter: NeuInsetPainter(
        shadows: NeuShadow.inset(context, distance: 3, blur: 6, spread: -2),
        borderRadius: 18,
      ),
      child: track,
    );

    return GestureDetector(
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(opacity: enabled ? 1 : 0.5, child: control),
    );
  }
}