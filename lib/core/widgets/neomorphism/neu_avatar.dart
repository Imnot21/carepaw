import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/design_tokens.dart';
import 'neu_shadows.dart';

/// Circular avatar — an extruded disc.
///
/// The disc stands proud of the canvas on the standard light/depth pair, and
/// the species accent lives in the glyph rather than in a hairline. That split
/// is deliberate: an accent-tinted ring reads as a category tag, while an
/// extruded disc tinted by species reads as an object with volume — and it keeps
/// a row of six avatars legible instead of turning into six competing colours.
///
/// When [backgroundColor] is supplied the pair is tinted to that hue, so a cat
/// avatar is lit in cat tones and a dog avatar in dog tones. The extrusion is
/// the same shape either way.
class NeuAvatar extends StatelessWidget {
  final double radius;
  final String? initials;
  final ImageProvider? image;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onTap;

  const NeuAvatar({
    super.key,
    this.radius = 28,
    this.initials,
    this.image,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDarkMode : AppColors.surface;

    // A supplied background is a species tint. Keep it as the disc fill, but
    // make sure it is opaque enough to carry a shadow — a 15%-alpha fill lets
    // the depth shadow bleed through and the disc stops reading as solid.
    final supplied = backgroundColor;
    final bg = supplied == null
        ? surface
        : _opaqueEnough(supplied, surface, isDark);

    final fg =
        foregroundColor ??
        (supplied == null ? AppColors.textOnPrimary : _readableOn(bg, isDark));

    final distance = radius * 0.11;
    final blur = radius * 0.26;

    Widget content;
    if (image != null) {
      content = ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Image(image: image!, fit: BoxFit.cover),
        ),
      );
    } else if (icon != null) {
      content = Icon(icon, size: radius * 0.9, color: fg);
    } else {
      content = Text(
        initials ?? '?',
        style: AppTextStyles.titleMedium.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Semantics(
      label: initials,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: supplied == null
                ? NeuShadow.raised(context, distance: distance, blur: blur)
                : _tintedPair(context, supplied, distance, blur, isDark),
          ),
          child: Center(child: content),
        ),
      ),
    );
  }

  /// Lift a translucent species tint onto an opaque base.
  ///
  /// Callers routinely pass `speciesColor.withValues(alpha: 0.15)`. Composited
  /// over the surface that reads correctly on screen, but as a shadow-bearing
  /// fill it lets the depth shadow through. Blending it down to a real alpha is
  /// what keeps the disc solid.
  Color _opaqueEnough(Color supplied, Color surface, bool isDark) {
    final alpha = supplied.a;
    if (alpha >= 0.999) return supplied;
    return Color.alphaBlend(
      supplied.withValues(alpha: alpha.clamp(0.0, 1.0)),
      surface,
    );
  }

  /// Extrusion tinted to the species hue.
  ///
  /// A neutral grey pair on a cat disc describes a light source that has nothing
  /// to do with the disc. Tinting both halves keeps the lighting and the
  /// material in agreement.
  List<BoxShadow> _tintedPair(
    BuildContext context,
    Color hue,
    double distance,
    double blur,
    bool isDark,
  ) {
    if (isDark) {
      return [
        BoxShadow(
          color: hue.withValues(alpha: 0.16),
          offset: Offset(-distance, -distance),
          blurRadius: blur,
        ),
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.46),
          offset: Offset(distance, distance),
          blurRadius: blur,
        ),
      ];
    }
    return [
      BoxShadow(
        color: hue.lighten(0.34).withValues(alpha: 0.85),
        offset: Offset(-distance, -distance),
        blurRadius: blur,
      ),
      BoxShadow(
        color: hue.darken(0.20).withValues(alpha: 0.50),
        offset: Offset(distance, distance),
        blurRadius: blur,
      ),
    ];
  }

  /// Pick a foreground that actually passes contrast on [bg].
  Color _readableOn(Color bg, bool isDark) {
    final luminance = bg.computeLuminance();
    // Dark glyphs need a light disc, and vice versa. The threshold sits above
    // the WCAG boundary so the softer of the two pairings is never chosen at
    // the edge.
    final useDarkInk = luminance > 0.42;
    if (useDarkInk) {
      return AppColors.textPrimary;
    }
    return isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary;
  }
}
