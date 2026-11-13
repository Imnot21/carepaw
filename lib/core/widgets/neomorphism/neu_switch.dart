import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/design_tokens.dart';
import 'neu_svg_icon.dart';
import 'neu_motion.dart';

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
        : (ThemeColors.surfaceInset(context));
    final thumbColor = value
        ? ThemeColors.onPrimary(context)
        : (isDark ? AppColors.textSecondaryOnDark : AppColors.textPrimary);
    final borderColor = value ? accent : ThemeColors.border(context);

    final control = RepaintBoundary(
      child: AnimatedContainer(
        duration: NeuMotion.duration(context, NeuTokens.durationMedium),
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
          duration: NeuMotion.duration(context, NeuTokens.durationMedium),
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
                ? NeuSvgIcon(SvgIcons.check, size: NeuTokens.iconXs)
                : null,
          ),
        ),
      ),
    );

    final VoidCallback? toggle = enabled && onChanged != null
        ? () {
            HapticFeedback.selectionClick();
            onChanged!(!value);
          }
        : null;

    return Semantics(
      toggled: value,
      enabled: enabled,
      label: label,
      onTap: toggle,
      child: GestureDetector(
        onTap: toggle,
        behavior: HitTestBehavior.opaque,
        // The track is 32 tall. The box around it brings the touch area up to
        // the minimum tap target without changing how the switch looks.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: NeuTokens.minTapTarget,
            minHeight: NeuTokens.minTapTarget,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Opacity(
              opacity: enabled ? 1 : NeuTokens.opacityDisabled,
              child: control,
            ),
          ),
        ),
      ),
    );
  }
}
