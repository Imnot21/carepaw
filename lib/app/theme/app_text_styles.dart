import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_colors.dart';

/// CarePaw typography — warm humanist display voice, quiet system body.
///
/// Display and headline styles are set in Nunito (rounded, organic, friendly)
/// to carry the brand's character. Body, labels, and controls stay on the system
/// face (Roboto / San Francisco) for native legibility and zero cost.
///
/// **Colour is never baked into a style.** Every getter below returns a style
/// with `color: null`, so it inherits the ambient text colour — the
/// `DefaultTextStyle` of its subtree, or `ColorScheme.onSurface` at the root.
/// `AppTheme` supplies the correct value per brightness through
/// `ColorScheme.apply`, so a heading is black on the light canvas and white on
/// the dark one without a single per-call-site `copyWith(color:)`.
///
/// If you need a specific colour, resolve it against the context:
/// ```dart
/// AppTextStyles.headlineSmall.copyWith(color: ThemeColors.textPrimary(context))
/// ```
class AppTextStyles {
  AppTextStyles._();

  // ============ Display (Nunito — rounded, organic) ============

  static TextStyle get displayLarge => GoogleFonts.nunito(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static TextStyle get displayMedium => GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static TextStyle get displaySmall => GoogleFonts.nunito(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.25,
  );

  // ============ Headline (Nunito) ============

  static TextStyle get headlineLarge => GoogleFonts.nunito(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.25,
  );

  static TextStyle get headlineMedium => GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.3,
  );

  static TextStyle get headlineSmall => GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
  );

  // ============ Title (system face — native legibility) ============

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.45,
  );

  // ============ Body (system face) ============

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
  );

  // ============ Label (system face) ============

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.05,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.35,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.3,
  );

  // ============ Specialized ============

  static TextStyle get appBarTitle => GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.5,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    height: 1.6,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.33,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static TextStyle get numberLarge => GoogleFonts.nunito(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.1,
  );

  static TextStyle get numberMedium => GoogleFonts.nunito(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.2,
  );

  static const TextStyle numberSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.3,
  );

  static const TextStyle code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
  );

  // ============ Context-aware colour resolution ============
  //
  // These take the colours that `AppTheme` resolves per brightness, so they are
  // correct in both modes. Prefer `ThemeColors` directly where it reads better;
  // these exist for the call sites that already hold a style.

  static TextStyle primaryOf(BuildContext context, TextStyle style) =>
      style.copyWith(color: ThemeColors.primary(context));

  static TextStyle secondaryOf(BuildContext context, TextStyle style) =>
      style.copyWith(color: ThemeColors.textSecondary(context));

  static TextStyle tertiaryOf(BuildContext context, TextStyle style) =>
      style.copyWith(color: ThemeColors.textTertiary(context));

  static TextStyle successOf(BuildContext context, TextStyle style) =>
      style.copyWith(color: ThemeColors.success(context));

  static TextStyle errorOf(BuildContext context, TextStyle style) =>
      style.copyWith(color: ThemeColors.error(context));

  static TextStyle warningOf(BuildContext context, TextStyle style) =>
      style.copyWith(color: ThemeColors.warning(context));

  static TextStyle linkOf(BuildContext context, TextStyle style) {
    final accent = ThemeColors.primary(context);
    return style.copyWith(
      color: accent,
      decoration: TextDecoration.underline,
      decorationColor: accent,
      decorationThickness: 1.5,
    );
  }

  // ============ Brightness-keyed helpers (no BuildContext) ============
  //
  // Use these when there is no context in scope. They take the brightness
  // explicitly rather than guessing, so a caller can never silently get the
  // wrong mode.

  static TextStyle primaryAt(Brightness brightness, TextStyle style) =>
      style.copyWith(
        color: brightness == Brightness.dark
            ? const Color(0xFFF0927A)
            : const Color(0xFFE27D60),
      );

  static TextStyle secondaryAt(Brightness brightness, TextStyle style) =>
      style.copyWith(
        color: brightness == Brightness.dark
            ? const Color(0xFFE5E7EB)
            : const Color(0xFF2B2B2B),
      );

  static TextStyle tertiaryAt(Brightness brightness, TextStyle style) =>
      style.copyWith(
        color: brightness == Brightness.dark
            ? const Color(0xFFD1D5DB)
            : const Color(0xFF4A4A4A),
      );

  static TextStyle successAt(Brightness brightness, TextStyle style) =>
      style.copyWith(
        color: brightness == Brightness.dark
            ? const Color(0xFF4ADE80)
            : const Color(0xFF16A34A),
      );

  static TextStyle errorAt(Brightness brightness, TextStyle style) =>
      style.copyWith(
        color: brightness == Brightness.dark
            ? const Color(0xFFF87171)
            : const Color(0xFFDC2626),
      );

  static TextStyle warningAt(Brightness brightness, TextStyle style) =>
      style.copyWith(
        color: brightness == Brightness.dark
            ? const Color(0xFFFBBF24)
            : const Color(0xFFD97706),
      );
}

extension TextStyleX on TextStyle {
  TextStyle withColor(Color color, {FontWeight? weight}) =>
      copyWith(color: color, fontWeight: weight);

  // ── Brightness-keyed colour ──
  // `subtleOf` / `mutedOf` are the safe entry points. The context-free
  // `subtle` / `muted` getters are kept for call sites that only ever run in
  // light mode; anything brightness-sensitive should use the `*Of(context)`
  // resolvers on AppTextStyles instead of these.

  TextStyle subtleOf(Brightness brightness) => brightness == Brightness.dark
      ? copyWith(color: const Color(0xFFE5E7EB))
      : copyWith(color: const Color(0xFF2B2B2B));

  TextStyle mutedOf(Brightness brightness) => brightness == Brightness.dark
      ? copyWith(color: const Color(0xFFD1D5DB))
      : copyWith(color: const Color(0xFF4A4A4A));

  TextStyle primaryOf(BuildContext context) =>
      copyWith(color: ThemeColors.primary(context));

  TextStyle successOf(BuildContext context) =>
      copyWith(color: ThemeColors.success(context));

  TextStyle errorOf(BuildContext context) =>
      copyWith(color: ThemeColors.error(context));

  TextStyle warningOf(BuildContext context) =>
      copyWith(color: ThemeColors.warning(context));

  TextStyle linkOf(BuildContext context) {
    final accent = ThemeColors.primary(context);
    return copyWith(
      color: accent,
      decoration: TextDecoration.underline,
      decorationColor: accent,
      decorationThickness: 1.5,
    );
  }

  // ── Weight ──

  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);

  TextStyle get semibold => copyWith(fontWeight: FontWeight.w600);

  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);

  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  // ── Tracking ──

  TextStyle get wide => copyWith(letterSpacing: (letterSpacing ?? 0) + 0.5);

  TextStyle get tight => copyWith(letterSpacing: (letterSpacing ?? 0) - 0.25);

  // ── Decoration ──

  TextStyle underline(Color decorationColor) => copyWith(
    decoration: TextDecoration.underline,
    decorationColor: decorationColor,
    decorationThickness: 1.5,
  );

  // ── Emphasis ──

  /// Warm lift for a hero figure or a short, load-bearing phrase. Purely a
  /// shadow, so it composes with whatever colour the style already resolves.
  TextStyle glow(Color color, {double opacity = 0.35}) => copyWith(
    shadows: [
      Shadow(
        color: color.withValues(alpha: opacity),
        blurRadius: 6,
        offset: const Offset(0, 1),
      ),
    ],
  );
}
