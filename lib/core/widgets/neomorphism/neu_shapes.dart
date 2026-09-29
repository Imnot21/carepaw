import 'package:flutter/material.dart';

/// Soft Clinic organic shape system.
///
/// The organic layer of the design language: flowing asymmetric radii, soft
/// squircle contours, and blob forms. Every shape in the app derives from
/// these tokens so the system feels grown from one root, not assembled from
/// unrelated corners.
///
/// Shape allocation (who owns what):
/// - Neumorphism owns depth (shadows) — see [neu_shadows.dart]
/// - Organic owns form (this file) — flowing radii, blobs, squircle contours
/// - Minimalist owns spacing and type — see `AppTextStyles`
class NeuShape {
  NeuShape._();

  // ============ Radius scale ============

  /// Tight radius for small controls (chips, inputs).
  static const double sm = 12;

  /// Default radius for cards and containers.
  static const double md = 20;

  /// Generous radius for hero cards and feature surfaces.
  static const double lg = 28;

  /// Full pill — buttons, nav bar, FABs.
  static const double pill = 999;

  // ============ Organic flowing radii ============
  /// A card's flowing contour — larger top-left, settling smaller toward the
  /// bottom-right, like a leaf or a pebble worn by water.
  static BorderRadius get cardFlow => const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(22),
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(28),
      );

  /// A soft squircle contour for feature surfaces — between a circle and a
  /// rectangle, the shape of a well-worn stone.
  static ShapeBorder get squircle => ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      );

  /// A gentle squircle for smaller surfaces.
  static ShapeBorder get squircleSm => ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      );

  /// An asymmetric blob contour for avatars and decorative plates — no two
  /// corners alike, the shape of a living cell or a drop of water.
  static BorderRadius get blob => const BorderRadius.only(
        topLeft: Radius.circular(38),
        topRight: Radius.circular(28),
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(36),
      );

  /// A softer blob for smaller avatars.
  static BorderRadius get blobSm => const BorderRadius.only(
        topLeft: Radius.circular(26),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(24),
      );

  /// A pill contour for buttons and nav — fully rounded, no corners.
  static BorderRadius get pillRadius => BorderRadius.circular(pill);

  /// A flowing pill for the bottom nav — slightly asymmetric, like a river
  /// stone.
  static BorderRadius get navFlow => const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(28),
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(32),
      );

  // ============ Organic motifs ============
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

    final path = Path();
    // Main pad — a soft triangle with rounded corners
    path.addOval(Rect.fromCenter(
      center: Offset(cx, cy),
      width: padRx * 2,
      height: padRy * 2,
    ));
    // Four toes
    for (var i = 0; i < 4; i++) {
      final t = (i - 1.5) / 1.5;
      path.addOval(Rect.fromCenter(
        center: Offset(cx + t * toeSpread, toeY - (i == 1 || i == 2 ? h * 0.02 : 0)),
        width: toeR * 2,
        height: toeR * 2,
      ));
    }
    return path;
  }

  /// A simple leaf path for organic decorative accents.
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
