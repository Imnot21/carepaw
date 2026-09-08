import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import 'neu_container.dart';
import 'neu_shadows.dart';

/// Neumorphic filter / choice chip.
///
/// A small raised plate that switches to a selected state (blue accent glow),
/// or an unselected raised/flat state. Used for queue filters, species chips,
/// and appointment-type pickers.
class NeuChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? selectedColor;
  final NeuVariant unselectedVariant;

  const NeuChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.enabled = true,
    this.selectedColor,
    this.unselectedVariant = NeuVariant.raised,
  });

  @override
  State<NeuChip> createState() => _NeuChipState();
}

class _NeuChipState extends State<NeuChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.selectedColor ?? AppColors.primary;

    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: (_) => widget.enabled ? setState(() => _pressed = true) : null,
      onTapUp: (_) => widget.enabled ? setState(() => _pressed = false) : null,
      onTapCancel: () => widget.enabled ? setState(() => _pressed = false) : null,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.5,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 80),
          child: NeuContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            borderRadius: 14,
            variant: widget.selected ? NeuVariant.pressed : widget.unselectedVariant,
            boxShadow: widget.selected ? NeuShadow.color(context, accent, blur: 14, opacity: 0.35) : null,
            borderColor: widget.selected ? accent : null,
            borderWidth: widget.selected ? 1 : 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 16,
                    color: widget.selected ? accent : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: widget.selected ? accent : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
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