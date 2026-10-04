import 'package:flutter/material.dart';
import '../../../app/theme/design_tokens.dart';

/// CarePaw shape system.
///
/// One radius per role, taken from [NeuTokens]. The old organic language used
/// asymmetric "flowing" contours — different values per corner, so no two
/// surfaces in a stack aligned. With shadows gone those irregularities read as
/// sloppiness rather than character, so the contours are normalized: every card
/// is the same radius, every field is the same radius, and a stack of surfaces
/// lines up into one grid.
///
/// The paw and leaf motifs survive as decorative brand moments.
class NeuShape {
  const NeuShape._();

  // ============ Radius scale (delegates to NeuTokens) ============

  /// Tight radius for badges and chips.
  static const double sm = NeuTokens.radiusSm;

  /// Default radius for cards, containers, and fields.
  static const double md = NeuTokens.radiusMd;

  /// Generous radius for dialogs, sheets, and hero surfaces.
  static const double lg = NeuTokens.radiusLg;

  /// Full pill — buttons, chips, nav, FABs.
  static const double pill = NeuTokens.radiusPill;

  // ============ Named contours ============

  /// The standard card contour.
  static BorderRadius get card => NeuTokens.card;

  /// The contour for dialogs, sheets, and nav containers.
  static BorderRadius get panel => NeuTokens.panel;

  /// A circular contour — avatars, icon buttons, FABs.
  static BorderRadius get circle => NeuTokens.circle;

  /// A circular contour for small avatars.
  static BorderRadius get circleSm => NeuTokens.circleSm;

  /// A pill contour for buttons and nav — fully rounded, no corners.
  static BorderRadius get pillRadius =>
      BorderRadius.circular(NeuTokens.radiusPill);

  /// A rectangular contour — data rows and table cells, where a rounded corner
  /// would imply the row is tappable.
  static ShapeBorder get square =>
      const RoundedRectangleBorder(borderRadius: BorderRadius.zero);

  // ============ Decorative motifs ============

  /// A paw-print path for decorative brand moments. Rendered in the accent
  /// color at small scale — a quiet signature, never a mascot.
  static Path pawPrint(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.62;
    final padRx = w * 0.22;
    final padRy = h * 0.18;
    final toeR = w * 0.09;
    final toeSpread = w * 0.24;
    final toeY = h * 0.34;

    final path = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: padRx * 2,
          height: padRy * 2,
        ),
      );
    for (var i = 0; i < 4; i++) {
      final t = (i - 1.5) / 1.5;
      path.addOval(
        Rect.fromCenter(
          center: Offset(
            cx + t * toeSpread,
            toeY - (i == 1 || i == 2 ? h * 0.02 : 0),
          ),
          width: toeR * 2,
          height: toeR * 2,
        ),
      );
    }
    return path;
  }

  /// A simple leaf path for decorative accents.
  static Path leaf(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..quadraticBezierTo(w * 0.95, h * 0.35, w * 0.5, h * 0.95)
      ..quadraticBezierTo(w * 0.05, h * 0.35, w * 0.5, h * 0.05)
      ..close();
  }
}
