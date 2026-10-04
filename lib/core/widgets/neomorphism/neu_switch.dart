import 'package:flutter/material.dart';
import '../../../app/theme/design_tokens.dart';

/// Toggle switch.
///
/// Off: a muted well with a white thumb and a hairline edge. On: the accent
/// fill with a thumb in the theme's on-accent color. The thumb travels; the
/// track has no shadow.
class NeuSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  /// Semantic label read by screen readers (e.g. "Dark mode", "Notifications").
  final String? label;

  const NeuSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    const trackWidth = NeuTokens.switchTrackWidth;
    const trackHeight = NeuTokens.switchTrackHeight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ThemeColors.primary(context);

    final trackColor = value
        ? accent
        : (isDark ? AppColors.surfaceInsetDark : AppColors.surfaceInset);
    final thumbColor = value
        ? ThemeColors.onPrimary(context)
        : (isDark ? AppColors.textSecondaryOnDark : AppColors.textPrimary);
    final borderColor = value ? accent : ThemeColors.border(context);

    final control = RepaintBoundary(
      child: AnimatedContainer(
        duration: NeuTokens.durationMedium,
        curve: NeuTokens.curveDefault,
        width: trackWidth,
        height: trackHeight,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(trackHeight / 2),
          border: Border.all(
            color: borderColor,
            width: NeuTokens.borderWidthThin,
          ),
        ),
        child: AnimatedAlign(
          duration: NeuTokens.durationMedium,
          curve: NeuTokens.curveDefault,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: NeuTokens.switchThumbSize,
            height: NeuTokens.switchThumbSize,
            decoration: BoxDecoration(
              color: thumbColor,
              shape: BoxShape.circle,
            ),
            child: value
                ? Icon(Icons.check, size: NeuTokens.iconXs, color: accent)
                : null,
          ),
        ),
      ),
    );

    return Semantics(
      toggled: value,
      enabled: enabled,
      label: label,
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
      child: GestureDetector(
        onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: enabled ? 1 : NeuTokens.opacityDisabled,
          child: control,
        ),
      ),
    );
  }
}
