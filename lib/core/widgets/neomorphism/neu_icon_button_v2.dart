import 'package:flutter/material.dart';
import '../../../app/theme/design_tokens.dart';
import 'neu_container.dart';
import 'neu_icon.dart';
import 'neu_icon_system.dart';
import 'neu_progress.dart';

/// Icon button using custom neumorphic icons.
///
/// This replaces [NeuIconButton] (which uses IconData) with a version that
/// uses [NeuIconType] paths. It provides the same press feedback and
/// extrusion but with custom-drawn icons that match the CarePaw aesthetic.
///
/// Usage:
/// ```dart
/// NeuIconButtonV2(
///   NeuIconType.home,
///   tooltip: 'Home',
///   onPressed: () {},
/// )
/// ```
class NeuIconButtonV2 extends StatefulWidget {
  final NeuIconType type;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final NeuVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final bool plain;

  const NeuIconButtonV2(
    this.type, {
    super.key,
    this.onPressed,
    this.tooltip,
    this.size = NeuTokens.iconMd,
    this.color,
    this.backgroundColor,
    this.variant = NeuVariant.raised,
    this.isLoading = false,
    this.isDisabled = false,
    this.plain = false,
  });

  @override
  State<NeuIconButtonV2> createState() => _NeuIconButtonV2State();
}

class _NeuIconButtonV2State extends State<NeuIconButtonV2> {
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
        duration: NeuTokens.durationFast,
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
              width: widget.size * 1.8,
              height: widget.size * 1.8,
              child: Center(
                child: _buildIcon(),
              ),
            ),
          ),
        ),
      ),
    );

    return widget.tooltip != null
        ? Tooltip(message: widget.tooltip!, child: button)
        : button;
  }

  Widget _buildIcon() {
    if (widget.isLoading) {
      return _buildLoadingIcon();
    }

    return NeuIcon(
      type: widget.type,
      size: widget.size,
      variant: _pressed ? NeuVariant.pressed : widget.variant,
      color: widget.color,
      backgroundColor: widget.backgroundColor,
    );
  }

  Widget _buildLoadingIcon() {
    return SizedBox(
      width: widget.size * 0.8,
      height: widget.size * 0.8,
      child: NeuCircularProgress(
        size: widget.size * 0.8,
        strokeWidth: 2,
        value: -1,
        color: widget.color ?? ThemeColors.primary(context),
      ),
    );
  }

  Widget _wrap(BuildContext context, Widget child) {
    if (widget.plain) return child;

    return NeuContainer(
      borderRadius: widget.size * 0.6,
      variant: _pressed ? NeuVariant.pressed : widget.variant,
      color: widget.backgroundColor ??
          (_pressed
              ? ThemeColors.primary(context).withValues(alpha: 0.12)
              : null),
      child: child,
    );
  }
}
