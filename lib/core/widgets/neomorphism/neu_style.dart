import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';
import 'neu_container.dart';
import 'neu_shadows.dart';

/// Surface style preset.
///
/// Bundles the decisions a surface makes — plane, radius, padding, edge,
/// lighting — into one object so a family of controls can be restyled from a
/// single place.
class NeumorphicStyle {
  final NeuVariant variant;
  final ShapeBorder? shape;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;

  /// Lighting preset. Drives the shadow pair through [resolveShadows]. When
  /// null, [NeuContainer] infers the lighting from [variant].
  final ShadowPreset? shadow;

  const NeumorphicStyle({
    required this.variant,
    this.shape,
    required this.borderRadius,
    this.color,
    this.borderColor,
    this.borderWidth = 0,
    this.padding,
    this.shadow,
  });

  NeumorphicStyle copyWith({
    NeuVariant? variant,
    ShapeBorder? shape,
    double? borderRadius,
    Color? color,
    Color? borderColor,
    double? borderWidth,
    EdgeInsetsGeometry? padding,
    ShadowPreset? shadow,
  }) {
    return NeumorphicStyle(
      variant: variant ?? this.variant,
      shape: shape ?? this.shape,
      borderRadius: borderRadius ?? this.borderRadius,
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      padding: padding ?? this.padding,
      shadow: shadow ?? this.shadow,
    );
  }

  /// Resolves a sensible surface fill.
  Color resolveColor(BuildContext context) =>
      color ?? ThemeColors.surface(context);

  /// Resolves a sensible edge. Only surfaces that opt into a hairline ask.
  Color? resolveBorderColor(BuildContext context) =>
      borderColor ?? ThemeColors.border(context);

  /// Resolves the shadow pair for this style.
  ///
  /// [shadow] wins when set; otherwise the lighting is inferred from [variant],
  /// so a style that only names a plane still gets the correct treatment.
  List<BoxShadow> resolveShadows(BuildContext context) {
    final preset = shadow;
    if (preset != null) {
      return switch (preset) {
        ShadowPreset.raised => NeuShadow.raised(context),
        ShadowPreset.pressed => NeuShadow.pressed(context),
        ShadowPreset.inset => NeuShadow.inset(context),
        ShadowPreset.flat => NeuShadow.flat(context),
      };
    }
    return switch (variant) {
      NeuVariant.raised => NeuShadow.raised(context),
      NeuVariant.pressed => NeuShadow.pressed(context),
      NeuVariant.inset => NeuShadow.inset(context),
      NeuVariant.flat || NeuVariant.transparent => NeuShadow.flat(context),
    };
  }

  // ─────────────────────────────────────────────
  // Presets
  // ─────────────────────────────────────────────

  /// A card standing proud of the canvas, lit from the top-left.
  static NeumorphicStyle raisedCard({
    double borderRadius = NeuTokens.radiusMd,
    EdgeInsetsGeometry? padding,
  }) {
    return NeumorphicStyle(
      variant: NeuVariant.raised,
      borderRadius: borderRadius,
      padding: padding,
      shadow: ShadowPreset.raised,
    );
  }

  /// The same card held down — the light and depth swap sides.
  static NeumorphicStyle pressedPlate({
    double borderRadius = NeuTokens.radiusMd,
    EdgeInsetsGeometry? padding,
  }) {
    return NeumorphicStyle(
      variant: NeuVariant.pressed,
      borderRadius: borderRadius,
      padding: padding,
      shadow: ShadowPreset.pressed,
    );
  }

  /// A dialog surface — extruded, and floating above the page it was raised
  /// from. Pair with [NeuShadow.floating] when it needs to detach further.
  static NeumorphicStyle dialog({
    double borderRadius = NeuTokens.radiusLg,
    EdgeInsetsGeometry? padding,
  }) {
    return NeumorphicStyle(
      variant: NeuVariant.raised,
      borderRadius: borderRadius,
      padding: padding,
      shadow: ShadowPreset.raised,
    );
  }

  /// A chip. Small, pill, and extruded just enough to lift off the canvas.
  static NeumorphicStyle chip({
    double borderRadius = NeuTokens.radiusPill,
    EdgeInsetsGeometry? padding,
  }) {
    return NeumorphicStyle(
      variant: NeuVariant.raised,
      borderRadius: borderRadius,
      padding: padding,
      shadow: ShadowPreset.raised,
    );
  }

  /// A recessed input well — filled, never outlined.
  static NeumorphicStyle inputInset({
    double borderRadius = NeuTokens.radiusMd,
    EdgeInsetsGeometry? padding,
  }) {
    return NeumorphicStyle(
      variant: NeuVariant.inset,
      borderRadius: borderRadius,
      padding: padding,
      shadow: ShadowPreset.inset,
    );
  }
}

/// Which side of a surface is lit.
///
/// The variant on a [NeumorphicStyle] already implies a lighting state; this
/// enum exists for the cases where a caller wants the lighting of one plane
/// without adopting its fill.
enum ShadowPreset { raised, pressed, flat, inset }
