import 'package:flutter/material.dart';
import '../../../app/theme/design_tokens.dart';
import 'neu_container.dart';
import 'neu_shadows.dart';
import 'neu_shapes.dart';
import 'neu_style.dart';

/// An extruded surface — the workhorse of the app.
///
/// List tiles, stat tiles, and detail panels are all [NeuCard]. A card is a
/// plane standing proud of the warm canvas, lit from the top-left, with no
/// hairline: in an extruded system the shadow pair already describes the edge,
/// and a border on top of it would describe it twice.
///
/// Pressing swaps the lighting — the light and depth swap sides and the plane
/// sinks into the canvas. Cards deliberately **do not scale**: at card size a
/// lighting change is the quieter, more legible signal, and a scaling card
/// reads as a button.
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
  final ShapeBorder? shape;
  final NeumorphicStyle? style;
  final bool showBorder;

  const NeuCard({
    super.key,
    required this.child,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.padding = const EdgeInsets.all(NeuTokens.cardPadding),
    this.margin = EdgeInsets.zero,
    this.borderRadius = NeuTokens.radiusMd,
    this.color,
    this.borderColor,
    this.borderWidth = 0,
    this.variant = NeuVariant.raised,
    this.shape,
    this.style,
    this.showBorder = false,
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
    final visualVariant = _pressed && widget.onTap != null
        ? NeuVariant.pressed
        : widget.variant;
    final effectiveShape =
        widget.shape ?? RoundedRectangleBorder(borderRadius: NeuShape.card);

    return Semantics(
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedContainer(
          duration: NeuTokens.durationCard,
          curve: NeuTokens.curveDefault,
          margin: widget.margin,
          padding: widget.padding,
          decoration: ShapeDecoration(
            color: _fill(context, visualVariant),
            shape: _shape(context, effectiveShape, visualVariant),
            shadows: _shadow(context, visualVariant),
          ),
          child: widget.child,
        ),
      ),
    );
  }

  List<BoxShadow> _shadow(BuildContext context, NeuVariant visualVariant) {
    final style = widget.style;
    if (style != null && style.shadow != null) {
      return _shadowForPreset(context, style.shadow!);
    }
    return switch (visualVariant) {
      NeuVariant.raised => NeuShadow.raised(context),
      NeuVariant.pressed => NeuShadow.pressed(context),
      NeuVariant.inset => NeuShadow.inset(context),
      NeuVariant.flat || NeuVariant.transparent => NeuShadow.flat(context),
    };
  }

  List<BoxShadow> _shadowForPreset(BuildContext context, ShadowPreset preset) {
    return switch (preset) {
      ShadowPreset.raised => NeuShadow.raised(context),
      ShadowPreset.pressed => NeuShadow.pressed(context),
      ShadowPreset.inset => NeuShadow.inset(context),
      ShadowPreset.flat => NeuShadow.flat(context),
    };
  }

  Color _fill(BuildContext context, NeuVariant visualVariant) {
    if (widget.color != null) return widget.color!;
    final style = widget.style;
    if (style != null && style.color != null) return style.color!;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (visualVariant == NeuVariant.inset) {
      return isDark ? AppColors.surfaceInsetDark : AppColors.surfaceInset;
    }
    if (visualVariant == NeuVariant.pressed ||
        visualVariant == NeuVariant.flat) {
      return isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted;
    }
    if (visualVariant == NeuVariant.transparent) return Colors.transparent;
    return isDark ? AppColors.surfaceDarkMode : AppColors.surface;
  }

  ShapeBorder _shape(
    BuildContext context,
    ShapeBorder effectiveShape,
    NeuVariant visualVariant,
  ) {
    if (widget.style != null && widget.style!.shape != null) {
      return effectiveShape;
    }

    // A well is defined by its cavity. Drawing an edge around it would fight
    // the fill and read as an error state.
    if (!widget.showBorder ||
        widget.borderWidth <= 0 ||
        visualVariant == NeuVariant.inset ||
        visualVariant == NeuVariant.transparent) {
      return effectiveShape;
    }

    final borderColor = widget.borderColor ?? ThemeColors.border(context);
    final width = widget.borderWidth > 0
        ? widget.borderWidth
        : NeuTokens.borderWidthThin;

    if (effectiveShape is RoundedRectangleBorder) {
      return effectiveShape.copyWith(
        side: BorderSide(color: borderColor, width: width),
      );
    }
    if (effectiveShape is CircleBorder) {
      return effectiveShape.copyWith(
        side: BorderSide(color: borderColor, width: width),
      );
    }
    return effectiveShape;
  }
}
