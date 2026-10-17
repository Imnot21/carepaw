import 'package:flutter/material.dart';
import '../../../app/theme/design_tokens.dart';
import 'neu_container.dart';
import 'neu_progress.dart';
import 'neu_svg_icon.dart';
import 'neu_motion.dart';

/// Circular icon button.
///
/// A bordered circle on the canvas; pressing tints it with the accent. Works
/// for app-bar actions, list-item actions, and toolbars.
///
/// Pass [svgAsset] (a `SvgIcons.*` path) to render the clay icon instead of
/// the Material [icon]. Clay wins when both are given.
class NeuIconButton extends StatefulWidget {
  final IconData icon;
  final String? svgAsset;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final bool isLoading;
  final bool isDisabled;

  /// Bare icon with no plate, border, or shadow — the glyph sits directly on
  /// the canvas. Touch target and press feedback are unchanged.
  final bool plain;

  const NeuIconButton({
    super.key,
    required this.icon,
    this.svgAsset,
    this.onPressed,
    this.tooltip,
    this.size = 24,
    this.color,
    this.backgroundColor,
    this.isLoading = false,
    this.isDisabled = false,
    this.plain = false,
  });

  @override
  State<NeuIconButton> createState() => _NeuIconButtonState();
}

class _NeuIconButtonState extends State<NeuIconButton> {
  bool _pressed = false;

  bool get _enabled => !widget.isDisabled && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.tooltip,
      child: AnimatedScale(
        scale: _pressed ? NeuTokens.scalePressedSmall : 1,
        duration: NeuMotion.duration(context, NeuTokens.durationFast),
        curve: NeuTokens.curveDefault,
        child: GestureDetector(
          onTap: _enabled ? widget.onPressed : null,
          onTapDown: (_) => _enabled ? setState(() => _pressed = true) : null,
          onTapUp: (_) => _enabled ? setState(() => _pressed = false) : null,
          onTapCancel: () => _enabled ? setState(() => _pressed = false) : null,
          behavior: HitTestBehavior.opaque,
          child: _wrap(
            context,
            SizedBox(
              // Minimum 48×48 touch target per WCAG 2.5.8
              width: widget.size * 2 < 48 ? 48 : widget.size * 2,
              height: widget.size * 2 < 48 ? 48 : widget.size * 2,
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: widget.size * 0.8,
                        height: widget.size * 0.8,
                        child: NeuCircularProgress(
                          size: widget.size * 0.8,
                          strokeWidth: 2,
                          value: -1,
                          color: widget.color ?? ThemeColors.primaryText(context),
                        ),
                      )
                    : widget.svgAsset != null
                        ? NeuSvgIcon(widget.svgAsset!, size: widget.size)
                        : Icon(
                            widget.icon,
                            size: widget.size,
                            color: widget.color ?? ThemeColors.primaryText(context),
                          ),
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

  /// [plain] drops the plate entirely; every other variant keeps the raised
  /// (or pressed) container around the glyph.
  Widget _wrap(BuildContext context, Widget child) {
    if (widget.plain) return child;
    return NeuContainer(
      borderRadius: widget.size * 1.2,
      variant: _pressed ? NeuVariant.pressed : NeuVariant.raised,
      color:
          widget.backgroundColor ??
          (_pressed
              ? ThemeColors.primary(context).withValues(alpha: 0.12)
              : null),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.size * 1.2),
      ),
      borderColor: _pressed
          ? ThemeColors.primary(context).withValues(alpha: 0.45)
          : null,
      borderWidth: _pressed ? NeuTokens.borderWidthFocus : 0,
      child: child,
    );
  }
}
