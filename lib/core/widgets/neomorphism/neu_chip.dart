import 'package:flutter/material.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/design_tokens.dart';
import 'neu_container.dart';
import 'neu_style.dart';

/// Filter / choice chip — an extruded pill.
///
/// Unselected stands proud of the canvas. Selected **sinks into it**: the light
/// and depth swap and the fill takes the accent tint, so selection is a change
/// of lighting rather than a border that appeared. Nothing about the chip grows
/// or changes size, which keeps a filter row from reflowing as it is used.
class NeuChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? selectedColor;
  final NeuVariant unselectedVariant;

  /// Optional style override. When provided, its [NeumorphicStyle.borderRadius]
  /// and [NeumorphicStyle.padding] take precedence over the token defaults.
  final NeumorphicStyle? style;

  const NeuChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.enabled = true,
    this.selectedColor,
    this.unselectedVariant = NeuVariant.raised,
    this.style,
  });

  @override
  State<NeuChip> createState() => _NeuChipState();
}

class _NeuChipState extends State<NeuChip> {
  @override
  Widget build(BuildContext context) {
    final accent = widget.selectedColor ?? ThemeColors.primary(context);
    final radius = widget.style?.borderRadius ?? NeuTokens.radiusPill;

    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: widget.enabled,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: Opacity(
          opacity: widget.enabled ? 1 : NeuTokens.opacityDisabled,
          child: NeuContainer(
            style: widget.style?.copyWith(borderRadius: radius),
            padding:
                widget.style?.padding ??
                const EdgeInsets.symmetric(
                  horizontal: NeuTokens.spaceSm,
                  vertical: NeuTokens.spaceXs,
                ),
            borderRadius: radius,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            variant: widget.selected
                ? NeuVariant.pressed
                : widget.unselectedVariant,
            color: widget.selected
                ? Color.alphaBlend(
                    accent.withValues(alpha: 0.16),
                    ThemeColors.surfaceMuted(context),
                  )
                : (widget.style?.color ?? null),
            borderColor: null,
            borderWidth: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: NeuTokens.iconXs,
                    color: widget.selected
                        ? accent
                        : ThemeColors.textSecondary(context),
                  ),
                  const SizedBox(width: NeuTokens.spaceXxs + 2),
                ],
                Text(
                  widget.label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: widget.selected
                        ? accent
                        : ThemeColors.textPrimary(context),
                    fontWeight: widget.selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
