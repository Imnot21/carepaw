import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import 'neu_container.dart';

/// Neumorphic circular icon button.
///
/// A raised circular plate with an icon. Pressing it dips the plate into the
/// canvas. Works for app-bar actions, list-item actions, and toolbars.
class NeuIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final bool isLoading;
  final bool isDisabled;

  const NeuIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 24,
    this.color,
    this.backgroundColor,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  State<NeuIconButton> createState() => _NeuIconButtonState();
}

class _NeuIconButtonState extends State<NeuIconButton> {
  bool _pressed = false;

  bool get _enabled => !widget.isDisabled && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final button = AnimatedScale(
      scale: _pressed ? 0.92 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: _enabled ? widget.onPressed : null,
        onTapDown: (_) => _enabled ? setState(() => _pressed = true) : null,
        onTapUp: (_) => _enabled ? setState(() => _pressed = false) : null,
        onTapCancel: () => _enabled ? setState(() => _pressed = false) : null,
        behavior: HitTestBehavior.opaque,
        child: NeuContainer(
          borderRadius: widget.size * 1.2,
          variant: _pressed ? NeuVariant.pressed : NeuVariant.raised,
          color: widget.backgroundColor,
          child: SizedBox(
            width: widget.size * 2,
            height: widget.size * 2,
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: widget.size * 0.8,
                      height: widget.size * 0.8,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.color ?? AppColors.primary,
                      ),
                    )
                  : Icon(
                      widget.icon,
                      size: widget.size,
                      color: widget.color ?? AppColors.primary,
                    ),
            ),
          ),
        ),
      ),
    );

    return _enabled && widget.tooltip != null
        ? Tooltip(message: widget.tooltip!, child: button)
        : button;
  }
}