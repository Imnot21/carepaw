import 'package:flutter/material.dart';
import '../../../app/theme/design_tokens.dart';

/// The extrusion engine.
///
/// Every raised plane in CarePaw is lit from the top-left and casts depth to the
/// bottom-right. Both halves are always drawn: a lone shadow reads as a sticker
/// floating above the page, not as a surface with volume.
///
/// Three calibration rules keep the extrusion legible instead of mushy:
///
/// 1. **The depth shadow is tinted.** It is the canvas hue darkened, never a
///    neutral gray — a gray shadow on `#F8F5F0` reads as dirt.
/// 2. **Blur runs at roughly twice the distance.** A tight shadow reads as a
///    hard bevel; a soft one reads as a lit surface.
/// 3. **Dark mode drops the light source.** A white highlight on charcoal
///    describes a light that is not there, so the top-left half becomes a faint
///    rim in the surface's own hue and the depth shadow carries the volume.
///
/// All values resolve by [Brightness] and come from [NeuTokens], so the whole
/// system can be retuned from one file.
abstract final class NeuShadow {
  const NeuShadow._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Resolve the canvas colour for the current brightness.
  static Color surfaceOf(BuildContext context) =>
      _isDark(context) ? AppColors.surfaceDarkMode : AppColors.surface;

  static Color _light(BuildContext context, double opacity) =>
      _lightColorOf(context).withValues(alpha: opacity);

  static Color _depth(BuildContext context, double opacity) =>
      _depthColorOf(context).withValues(alpha: opacity);

  static Color _lightColorOf(BuildContext context) =>
      _isDark(context) ? AppColors.shadowLightDark : AppColors.shadowLight;

  static Color _depthColorOf(BuildContext context) =>
      _isDark(context) ? AppColors.shadowDepthDark : AppColors.shadowDepth;

  static Color _floatingColorOf(BuildContext context) =>
      _isDark(context) ? AppColors.shadowDepthDark : AppColors.shadowFloating;

  /// Raised — the workhorse. A card sitting proud of the canvas.
  ///
  /// Light mode draws the full pair. Dark mode tightens the distance slightly
  /// and leans harder on the depth shadow, because a charcoal surface loses
  /// more of its silhouette than a white one.
  static List<BoxShadow> raised(
    BuildContext context, {
    double? distance,
    double? blur,
    double? spread,
  }) {
    final dark = _isDark(context);
    final d =
        distance ??
        (dark
            ? NeuTokens.shadowExtrudeDistanceDark
            : NeuTokens.shadowExtrudeDistance);
    final b = blur ?? NeuTokens.shadowExtrudeBlur;
    final lightOpacity = dark
        ? NeuTokens.shadowExtrudeLightOpacityDark
        : NeuTokens.shadowExtrudeLightOpacity;
    final depthOpacity = dark
        ? NeuTokens.shadowExtrudeDarkOpacityDark
        : NeuTokens.shadowExtrudeDarkOpacity;

    return [
      BoxShadow(
        color: _light(context, lightOpacity),
        offset: Offset(-d, -d),
        blurRadius: b,
        spreadRadius: spread ?? 0,
      ),
      BoxShadow(
        color: _depth(context, depthOpacity),
        offset: Offset(d, d),
        blurRadius: b,
        spreadRadius: spread ?? 0,
      ),
    ];
  }

  /// Pressed — the same pair with the light and the depth swapped.
  ///
  /// This is what makes a card appear to sink into the canvas rather than
  /// shrink. Cards must not scale on press; swapping which side is lit is the
  /// quieter, more legible signal at card size.
  static List<BoxShadow> pressed(BuildContext context) {
    final dark = _isDark(context);
    final d = NeuTokens.shadowPressedDistance;
    final b = NeuTokens.shadowPressedBlur;
    final lightOpacity = dark
        ? NeuTokens.shadowPressedDarkOpacityDark
        : NeuTokens.shadowPressedLightOpacity;
    final depthOpacity = dark
        ? NeuTokens.shadowPressedDarkOpacityDark
        : NeuTokens.shadowPressedDarkOpacity;

    return [
      BoxShadow(
        color: _depth(context, lightOpacity),
        offset: Offset(-d, -d),
        blurRadius: b,
      ),
      BoxShadow(
        color: _light(context, depthOpacity),
        offset: Offset(d, d),
        blurRadius: b,
      ),
    ];
  }

  /// Inset — a recessed well for input fields and progress tracks.
  ///
  /// Shares the pressed logic but runs a longer radius, so the inner falloff
  /// reads as a cavity rather than as a button being held down. A well is
  /// always filled and never outlined: an edge around a recessed field reads as
  /// an error state rather than as somewhere to type.
  static List<BoxShadow> inset(BuildContext context) {
    final dark = _isDark(context);
    final d = NeuTokens.shadowInsetDistance;
    final b = NeuTokens.shadowInsetBlur;
    final lightOpacity = dark
        ? NeuTokens.shadowInsetLightOpacityDark
        : NeuTokens.shadowInsetLightOpacity;
    final depthOpacity = dark
        ? NeuTokens.shadowInsetDarkOpacityDark
        : NeuTokens.shadowInsetDarkOpacity;

    return [
      BoxShadow(
        color: _depth(context, lightOpacity),
        offset: Offset(-d, -d),
        blurRadius: b,
      ),
      BoxShadow(
        color: _light(context, depthOpacity),
        offset: Offset(d, d),
        blurRadius: b,
      ),
    ];
  }

  /// Flat — no extrusion. Quiet groupings, table headers, section backgrounds.
  ///
  /// This is a deliberate plane in the system, not a stripped-back raised: a
  /// surface with no shadow is meant to sit flush with its parent.
  static List<BoxShadow> flat(BuildContext context) => none;

  /// No shadow — for transparent / ghost elements.
  static const List<BoxShadow> none = [];

  /// Floating — bottom nav, FAB, dialog, bottom sheet.
  ///
  /// One offset shadow, cast straight down. These sit above other surfaces
  /// rather than beside them, so a corner light source would be a lie about
  /// where they are.
  static List<BoxShadow> floating(
    BuildContext context, {
    double distance = NeuTokens.shadowFloatingDistance,
    double blur = NeuTokens.shadowFloatingBlur,
    double? opacity,
  }) {
    final resolvedOpacity =
        opacity ??
        (_isDark(context)
            ? NeuTokens.shadowFloatingDarkOpacityDark
            : NeuTokens.shadowFloatingDarkOpacity);
    return [
      BoxShadow(
        color: _floatingColorOf(context).withValues(alpha: resolvedOpacity),
        offset: Offset(0, distance),
        blurRadius: blur,
      ),
    ];
  }

  /// Accent shadow — an anchored glow for a selected or active element.
  ///
  /// The offset is what makes this read as depth rather than as a halo; a chip
  /// that lights up without an anchor floats ambiguously. Rationed: the accent
  /// may glow, the canvas may not.
  static List<BoxShadow> color(
    BuildContext context,
    Color color, {
    double blur = NeuTokens.shadowAccentBlur,
    double opacity = NeuTokens.shadowAccentOpacity,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        offset: Offset(0, (blur * 0.25).roundToDouble()),
        blurRadius: blur,
      ),
    ];
  }
}
