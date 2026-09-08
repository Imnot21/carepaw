import 'package:flutter/material.dart';
import 'neu_container.dart';

/// Neumorphic card — a raised surface with optional press feedback.
///
/// The workhorse of the CarePaw UI: list tiles, stat tiles, detail panels all
/// render as [NeuCard]s. Cards sit raised on the soft-gray canvas; a tappable
/// card springs gently into [NeuVariant.pressed] while being pressed, then
/// returns to raised on release.
class NeuCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final void Function(TapDownDetails)? onTapDown;
  final void Function(TapUpDetails)? onTapUp;
  final void Function()? onTapCancel;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final NeuVariant variant;

  const NeuCard({
    super.key,
    required this.child,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20,
    this.color,
    this.borderColor,
    this.borderWidth = 0,
    this.variant = NeuVariant.raised,
  });

  @override
  State<NeuCard> createState() => _NeuCardState();
}

class _NeuCardState extends State<NeuCard> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails details) {
    widget.onTapDown?.call(details);
    if (widget.onTap != null) setState(() => _pressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    widget.onTapUp?.call(details);
    if (widget.onTap != null) setState(() => _pressed = false);
  }

  void _handleTapCancel() {
    widget.onTapCancel?.call();
    if (widget.onTap != null) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final visualVariant =
        _pressed && widget.onTap != null ? NeuVariant.pressed : widget.variant;

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: NeuContainer(
          variant: visualVariant,
          padding: widget.padding,
          margin: widget.margin,
          borderRadius: widget.borderRadius,
          color: widget.color,
          borderColor: widget.borderColor,
          borderWidth: widget.borderWidth,
          child: widget.child,
        ),
      ),
    );
  }
}