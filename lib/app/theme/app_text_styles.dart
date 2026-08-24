import 'package:flutter/material.dart';

/// CarePaw premium typography scale following Material 3 guidelines.
///
/// Features:
/// - Optimized for readability and accessibility
/// - Refined font weights and letter spacing
/// - Premium text effects support
/// - System font stack for optimal performance
class AppTextStyles {
  AppTextStyles._();

  // ============ Display Styles ============
  // For large, short text like headlines, hero sections

  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w300,
    letterSpacing: 0,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // ============ Headline Styles ============
  // For section headers, page titles

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.05,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  // ============ Title Styles ============
  // For component titles, card titles

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ============ Body Styles ============
  // For longer content, paragraphs

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.4,
  );

  // ============ Label Styles ============
  // For buttons, inputs, chips

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ============ Specialized Styles ============

  /// For app bar titles
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.4,
  );

  /// For card titles
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.05,
    height: 1.5,
  );

  /// For overline text (small labels, categories)
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    height: 1.6,
  );

  /// For caption text (timestamps, metadata)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  /// For button text
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.43,
  );

  /// For numbers (prices, counts, statistics)
  static const TextStyle numberLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static const TextStyle numberMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle numberSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.3,
  );

  /// For code/technical text
  static const TextStyle code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
  );

  // ============ Premium Text Effects ============

  /// Gradient text - applies gradient to text
  static TextStyle gradient(TextStyle style, Gradient gradient) =>
      style.copyWith(
        foreground: Paint()..shader = gradient.createShader(
          const Rect.fromLTWH(0, 0, 200, 100),
        ),
      );

  /// Primary gradient text
  static TextStyle primaryGradient(TextStyle style) => gradient(
    style,
    const LinearGradient(
      colors: [
        Color(0xFF6D28D9),
        Color(0xFF8B5CF6),
        Color(0xFF14B8A6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// Glowing text effect
  static TextStyle glow(TextStyle style, Color glowColor) =>
      style.copyWith(
        shadows: [
          Shadow(
            color: glowColor.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
          Shadow(
            color: glowColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 0),
          ),
        ],
      );

  /// Primary glow text
  static TextStyle primaryGlow(TextStyle style) => glow(style, const Color(0xFF6D28D9));

  /// Success glow text
  static TextStyle successGlow(TextStyle style) => glow(style, const Color(0xFF10B981));

  /// Warning glow text
  static TextStyle warningGlow(TextStyle style) => glow(style, const Color(0xFFF59E0B));

  /// Error glow text
  static TextStyle errorGlow(TextStyle style) => glow(style, const Color(0xFFEF4444));

  /// Subtle text (for secondary content)
  static TextStyle subtle(TextStyle style) => style.copyWith(
        color: const Color(0xFF98A2B3),
      );

  /// Muted text (for tertiary content)
  static TextStyle muted(TextStyle style) => style.copyWith(
        color: const Color(0xFF667085),
      );

  /// High contrast text
  static TextStyle highContrast(TextStyle style) => style.copyWith(
        color: const Color(0xFF101828),
        fontWeight: FontWeight.w700,
      );

  /// Link text
  static TextStyle link(TextStyle style) => style.copyWith(
        color: const Color(0xFF6D28D9),
        decoration: TextDecoration.underline,
        decorationColor: const Color(0xFF6D28D9),
        decorationThickness: 1.5,
      );

  /// Success text
  static TextStyle success(TextStyle style) => style.copyWith(
        color: const Color(0xFF10B981),
      );

  /// Warning text
  static TextStyle warning(TextStyle style) => style.copyWith(
        color: const Color(0xFFF59E0B),
      );

  /// Error text
  static TextStyle error(TextStyle style) => style.copyWith(
        color: const Color(0xFFEF4444),
      );

  /// Info text
  static TextStyle info(TextStyle style) => style.copyWith(
        color: const Color(0xFF3B82F6),
      );

  /// Primary text
  static TextStyle primary(TextStyle style) => style.copyWith(
        color: const Color(0xFF6D28D9),
      );

  /// Secondary text
  static TextStyle secondary(TextStyle style) => style.copyWith(
        color: const Color(0xFF7C3AED),
      );

  /// Tertiary text
  static TextStyle tertiary(TextStyle style) => style.copyWith(
        color: const Color(0xFF14B8A6),
      );
}

/// Extension for easy text style modifications.
extension TextStyleX on TextStyle {
  /// Apply color with weight
  TextStyle withColor(Color color, {FontWeight? weight}) => copyWith(
        color: color,
        fontWeight: weight,
      );

  /// Make text subtle
  TextStyle get subtle => copyWith(
        color: const Color(0xFF98A2B3),
      );

  /// Make text muted
  TextStyle get muted => copyWith(
        color: const Color(0xFF667085),
      );

  /// Make text bold
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);

  /// Make text semibold
  TextStyle get semibold => copyWith(fontWeight: FontWeight.w600);

  /// Make text medium
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// Make text regular
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);

  /// Make text light
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  /// Add gradient
  TextStyle gradient(Gradient gradient) => copyWith(
        foreground: Paint()..shader = gradient.createShader(
          const Rect.fromLTWH(0, 0, 200, 100),
        ),
      );

  /// Add primary gradient
  TextStyle get primaryGradient => gradient(
    const LinearGradient(
      colors: [
        Color(0xFF6D28D9),
        Color(0xFF8B5CF6),
        Color(0xFF14B8A6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// Add glow effect
  TextStyle glow(Color color) => copyWith(
        shadows: [
          Shadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
          Shadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 0),
          ),
        ],
      );

  /// Add primary glow
  TextStyle get primaryGlow => glow(const Color(0xFF6D28D9));

  /// Add underline for links
  TextStyle get underline => copyWith(
        decoration: TextDecoration.underline,
        decorationColor: color,
        decorationThickness: 1.5,
      );

  /// Increase letter spacing
  TextStyle get wide => copyWith(letterSpacing: (letterSpacing ?? 0) + 0.5);

  /// Decrease letter spacing
  TextStyle get tight => copyWith(letterSpacing: (letterSpacing ?? 0) - 0.25);
}