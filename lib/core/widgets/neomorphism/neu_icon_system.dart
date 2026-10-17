import 'package:flutter/material.dart';

/// Custom neumorphic icon system with handcrafted paths.
///
/// Paths are rendered directly via CustomPainter for perfect extrusion integration.
/// All icons use 1.5-2.0 stroke weight equivalent and rounded caps for organic feel.
/// Single-family icon system — no mixing with Material Icons.
///
/// Design principles:
/// - 24px base grid (iconMd = 24)
/// - Single stroke weight for consistency
/// - Rounded line caps and joins
/// - Minimal detail — clean silhouettes
/// - Species icons use NeuAvatar tinting for depth
abstract final class NeuIcons {
  const NeuIcons._();

  static const double _grid = 24.0;
  static const double _stroke = 2.0;

  /// Returns a Path for the given icon name at size [size].
  static CustomPainter painterFor(NeuIconType type, {required double size}) {
    final scale = size / _grid;
    return _IconPainter(type, scale);
  }

  /// Direct Path construction for embedding in other widgets.
  static Path pathFor(NeuIconType type, double size) {
    final scale = size / _grid;
    final path = _buildPath(type, scale);
    return path ?? Path();
  }
}

/// Enum of all custom icons for CarePaw.
///
/// Categories:
/// - Navigation (bottom nav)
/// - Species (pet types)
/// - Medical records
/// - Actions (UI controls)
enum NeuIconType {
  // Navigation
  home,
  pets,
  calendar,
  reminders,
  profile,

  // Species
  dog,
  cat,
  bird,
  rabbit,
  reptile,

  // Medical records
  visit,
  vaccination,
  medication,
  treatment,
  labTest,
  prescription,
  note,
  alert,

  // Actions
  add,
  edit,
  delete,
  save,
  back,
  more,
  refresh,
  search,
  filter,
  settings,
  attachment,
  check,
  close,
  info,
  warning,
  error,
  success,
}

/// Custom painter for neumorphic icons.
///
/// Icons are drawn with rounded stroke caps and joins to match the organic
/// neumorphism language. The stroke color inherits ambient onSurface via
/// ThemeColors so they don't need explicit color.
class _IconPainter extends CustomPainter {
  final NeuIconType type;
  final double scale;

  _IconPainter(this.type, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale * NeuIcons._stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _resolveIconColor(size);

    final path = NeuIcons.pathFor(type, size.width);
    canvas.drawPath(path, paint);

    // Draw filled paths if needed (some icons have filled elements)
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _resolveIconColor(size).withValues(alpha: 0.12);

    final pathWithFill = _buildPath(type, scale, fill: true);
    if (pathWithFill != null) {
      canvas.drawPath(pathWithFill, fillPaint);
    }
  }

  Color _resolveIconColor(Size size) {
    // Will be overridden by parent widget if needed
    // Default fallback for standalone use
    return const Color(0xFF1A1A1A);
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.type != type || old.scale != scale;
}

/// Core path builder. All paths are built on 24x24 grid.
Path? _buildPath(NeuIconType type, double scale, {bool fill = false}) {
  return switch (type) {
    // Navigation
    NeuIconType.home => _home(scale),
    NeuIconType.pets => _pawPrint(scale),
    NeuIconType.calendar => _calendar(scale),
    NeuIconType.reminders => _bell(scale),
    NeuIconType.profile => _user(scale),

    // Species
    NeuIconType.dog => _dogFace(scale),
    NeuIconType.cat => _catFace(scale),
    NeuIconType.bird => _bird(scale),
    NeuIconType.rabbit => _rabbit(scale),
    NeuIconType.reptile => _lizard(scale),

    // Medical
    NeuIconType.visit => _stethoscope(scale),
    NeuIconType.vaccination => _syringe(scale),
    NeuIconType.medication => _pill(scale),
    NeuIconType.treatment => _heartPulse(scale),
    NeuIconType.labTest => _flask(scale),
    NeuIconType.prescription => _rx(scale),
    NeuIconType.note => _note(scale),
    NeuIconType.alert => _alert(scale),

    // Actions
    NeuIconType.add => _plus(scale),
    NeuIconType.edit => _pencil(scale),
    NeuIconType.delete => _trash(scale),
    NeuIconType.save => _checkCircle(scale),
    NeuIconType.back => _chevronLeft(scale),
    NeuIconType.more => _dots(scale),
    NeuIconType.refresh => _refresh(scale),
    NeuIconType.search => _search(scale),
    NeuIconType.filter => _filter(scale),
    NeuIconType.settings => _gear(scale),
    NeuIconType.attachment => _paperclip(scale),
    NeuIconType.check => _check(scale),
    NeuIconType.close => _x(scale),
    NeuIconType.info => _info(scale),
    NeuIconType.warning => _warning(scale),
    NeuIconType.error => _xCircle(scale),
    NeuIconType.success => _checkCircle(scale),
  };
}

// MARK: Navigation Icons

Path _home(double scale) {
  final p = Path();
  p.moveTo(scale * 6, scale * 18);
  p.lineTo(scale * 6, scale * 12);
  p.lineTo(scale * 3, scale * 12);
  p.lineTo(scale * 3, scale * 18);
  p.lineTo(scale * 2, scale * 20);
  p.lineTo(scale * 22, scale * 20);
  p.lineTo(scale * 21, scale * 18);
  p.lineTo(scale * 18, scale * 18);
  p.lineTo(scale * 18, scale * 10);
  p.lineTo(scale * 12, scale * 4);
  p.lineTo(scale * 6, scale * 10);
  p.lineTo(scale * 6, scale * 18);
  return p;
}

Path _pawPrint(double scale) {
  final p = Path();
  // Center pad
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 16),
    width: scale * 6,
    height: scale * 6,
  ));
  // Toes
  final toeR = scale * 2;
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 6, scale * 10),
    width: toeR * 2,
    height: toeR * 2,
  ));
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 6),
    width: toeR * 2,
    height: toeR * 2,
  ));
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 18, scale * 10),
    width: toeR * 2,
    height: toeR * 2,
  ));
  return p;
}

Path _calendar(double scale) {
  final p = Path();
  // Body
  p.addRect(Rect.fromLTWH(scale * 4, scale * 8, scale * 16, scale * 12));
  // Header
  p.addRect(Rect.fromLTWH(scale * 4, scale * 8, scale * 16, scale * 6));
  // Dots
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 8, scale * 11),
    width: scale * 2,
    height: scale * 2,
  ));
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 11),
    width: scale * 2,
    height: scale * 2,
  ));
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 16, scale * 11),
    width: scale * 2,
    height: scale * 2,
  ));
  return p;
}

Path _bell(double scale) {
  final p = Path();
  // Bell body
  p.addArc(Rect.fromCenter(
    center: Offset(scale * 12, scale * 14),
    width: scale * 8,
    height: scale * 8,
  ), -1.1, 2.2);
  // Clapper
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 20),
    width: scale * 3,
    height: scale * 3,
  ));
  // Handle
  p.moveTo(scale * 10, scale * 8);
  p.lineTo(scale * 14, scale * 8);
  return p;
}

Path _user(double scale) {
  final p = Path();
  // Head
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 7),
    width: scale * 8,
    height: scale * 8,
  ));
  // Body
  p.moveTo(scale * 6, scale * 15);
  p.lineTo(scale * 18, scale * 15);
  p.lineTo(scale * 16, scale * 22);
  p.lineTo(scale * 8, scale * 22);
  return p;
}

// MARK: Species Icons

Path _dogFace(double scale) {
  final p = Path();
  // Face
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 11),
    width: scale * 14,
    height: scale * 10,
  ));
  // Ears
  p.moveTo(scale * 5, scale * 6);
  p.quadraticBezierTo(scale * 2, scale * 2, scale * 4, scale * 8);
  p.moveTo(scale * 19, scale * 6);
  p.quadraticBezierTo(scale * 22, scale * 2, scale * 20, scale * 8);
  // Nose
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 13),
    width: scale * 3,
    height: scale * 3,
  ));
  // Eyes
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 8, scale * 9),
    width: scale * 2,
    height: scale * 2,
  ));
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 16, scale * 9),
    width: scale * 2,
    height: scale * 2,
  ));
  return p;
}

Path _catFace(double scale) {
  final p = Path();
  // Face
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 12),
    width: scale * 12,
    height: scale * 10,
  ));
  // Ears (triangles)
  p.moveTo(scale * 7, scale * 4);
  p.lineTo(scale * 3, scale * 10);
  p.lineTo(scale * 9, scale * 9);
  p.moveTo(scale * 17, scale * 4);
  p.lineTo(scale * 21, scale * 10);
  p.lineTo(scale * 15, scale * 9);
  // Nose
  p.moveTo(scale * 10, scale * 13);
  p.lineTo(scale * 12, scale * 14);
  p.lineTo(scale * 14, scale * 13);
  // Whiskers
  p.moveTo(scale * 4, scale * 12);
  p.lineTo(scale * 2, scale * 11);
  p.moveTo(scale * 4, scale * 14);
  p.lineTo(scale * 2, scale * 15);
  p.moveTo(scale * 20, scale * 12);
  p.lineTo(scale * 22, scale * 11);
  p.moveTo(scale * 20, scale * 14);
  p.lineTo(scale * 22, scale * 15);
  // Eyes
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 8, scale * 10),
    width: scale * 2,
    height: scale * 3,
  ));
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 16, scale * 10),
    width: scale * 2,
    height: scale * 3,
  ));
  return p;
}

Path _bird(double scale) {
  final p = Path();
  // Body
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 14),
    width: scale * 10,
    height: scale * 7,
  ));
  // Head
  p.moveTo(scale * 8, scale * 13);
  p.quadraticBezierTo(scale * 4, scale * 11, scale * 4, scale * 9);
  p.quadraticBezierTo(scale * 6, scale * 5, scale * 10, scale * 7);
  p.lineTo(scale * 8, scale * 13);
  // Beak
  p.moveTo(scale * 3, scale * 9);
  p.lineTo(scale * 1, scale * 9);
  // Wing
  p.moveTo(scale * 15, scale * 13);
  p.quadraticBezierTo(scale * 20, scale * 12, scale * 20, scale * 9);
  return p;
}

Path _rabbit(double scale) {
  final p = Path();
  // Ears
  p.moveTo(scale * 7, scale * 4);
  p.lineTo(scale * 5, scale * 14);
  p.lineTo(scale * 9, scale * 14);
  p.moveTo(scale * 17, scale * 4);
  p.lineTo(scale * 19, scale * 14);
  p.lineTo(scale * 15, scale * 14);
  // Head
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 11),
    width: scale * 8,
    height: scale * 7,
  ));
  // Body
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 18),
    width: scale * 10,
    height: scale * 6,
  ));
  // Nose
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 7),
    width: scale * 2,
    height: scale * 1.5,
  ));
  return p;
}

Path _lizard(double scale) {
  final p = Path();
  // Body
  p.moveTo(scale * 5, scale * 14);
  p.quadraticBezierTo(scale * 8, scale * 8, scale * 12, scale * 10);
  p.quadraticBezierTo(scale * 16, scale * 12, scale * 18, scale * 9);
  p.quadraticBezierTo(scale * 20, scale * 6, scale * 20, scale * 10);
  p.lineTo(scale * 16, scale * 18);
  p.lineTo(scale * 8, scale * 20);
  p.close();
  // Head
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 6, scale * 12),
    width: scale * 5,
    height: scale * 5,
  ));
  return p;
}

// MARK: Medical Icons

Path _stethoscope(double scale) {
  final p = Path();
  // Chest piece
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 7, scale * 10),
    width: scale * 6,
    height: scale * 6,
  ));
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 17, scale * 10),
    width: scale * 6,
    height: scale * 6,
  ));
  // Tube
  p.moveTo(scale * 10, scale * 13);
  p.quadraticBezierTo(scale * 12, scale * 18, scale * 14, scale * 13);
  // Earpieces
  p.moveTo(scale * 10, scale * 11);
  p.lineTo(scale * 7, scale * 8);
  p.moveTo(scale * 14, scale * 11);
  p.lineTo(scale * 17, scale * 8);
  return p;
}

Path _syringe(double scale) {
  final p = Path();
  // Barrel
  p.moveTo(scale * 6, scale * 8);
  p.lineTo(scale * 10, scale * 8);
  p.lineTo(scale * 10, scale * 14);
  p.lineTo(scale * 6, scale * 14);
  p.close();
  // Plunger
  p.moveTo(scale * 10, scale * 8);
  p.lineTo(scale * 14, scale * 5);
  p.lineTo(scale * 16, scale * 7);
  p.lineTo(scale * 12, scale * 10);
  p.close();
  // Needle
  p.moveTo(scale * 6, scale * 15);
  p.lineTo(scale * 2, scale * 18);
  return p;
}

Path _pill(double scale) {
  final p = Path();
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 12),
    width: scale * 14,
    height: scale * 8,
  ));
  // Half division
  p.moveTo(scale * 4, scale * 12);
  p.lineTo(scale * 20, scale * 12);
  return p;
}

Path _heartPulse(double scale) {
  final p = Path();
  // Heart
  p.moveTo(scale * 12, scale * 8);
  p.quadraticBezierTo(scale * 6, scale * 3, scale * 4, scale * 9);
  p.quadraticBezierTo(scale * 2, scale * 14, scale * 12, scale * 20);
  p.quadraticBezierTo(scale * 22, scale * 14, scale * 20, scale * 9);
  p.quadraticBezierTo(scale * 18, scale * 3, scale * 12, scale * 8);
  // Pulse line
  p.moveTo(scale * 6, scale * 16);
  p.lineTo(scale * 10, scale * 12);
  p.lineTo(scale * 14, scale * 18);
  p.lineTo(scale * 20, scale * 10);
  return p;
}

Path _flask(double scale) {
  final p = Path();
  // Flask body
  p.moveTo(scale * 7, scale * 8);
  p.lineTo(scale * 8, scale * 18);
  p.quadraticBezierTo(scale * 12, scale * 20, scale * 17, scale * 18);
  p.lineTo(scale * 18, scale * 8);
  p.lineTo(scale * 16, scale * 8);
  p.lineTo(scale * 16, scale * 6);
  p.lineTo(scale * 9, scale * 6);
  p.lineTo(scale * 9, scale * 8);
  p.close();
  return p;
}

Path _rx(double scale) {
  final p = Path();
  // Rx symbol
  p.moveTo(scale * 6, scale * 10);
  p.lineTo(scale * 18, scale * 18);
  p.moveTo(scale * 14, scale * 6);
  p.lineTo(scale * 8, scale * 14);
  p.lineTo(scale * 10, scale * 14);
  p.lineTo(scale * 16, scale * 8);
  return p;
}

Path _note(double scale) {
  final p = Path();
  // Paper
  p.addRect(Rect.fromLTWH(scale * 6, scale * 6, scale * 12, scale * 14));
  // Lines
  for (int i = 0; i < 4; i++) {
    p.moveTo(scale * 8, scale * 10 + i * scale * 2.5);
    p.lineTo(scale * 17, scale * 10 + i * scale * 2.5);
  }
  return p;
}

Path _alert(double scale) {
  final p = Path();
  // Triangle
  p.moveTo(scale * 12, scale * 5);
  p.lineTo(scale * 5, scale * 19);
  p.lineTo(scale * 19, scale * 19);
  p.close();
  // Exclamation
  p.moveTo(scale * 12, scale * 12);
  p.lineTo(scale * 12, scale * 16);
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 19),
    width: scale * 1.5,
    height: scale * 1.5,
  ));
  return p;
}

// MARK: Action Icons

Path _plus(double scale) {
  final p = Path();
  p.moveTo(scale * 12, scale * 6);
  p.lineTo(scale * 12, scale * 18);
  p.moveTo(scale * 6, scale * 12);
  p.lineTo(scale * 18, scale * 12);
  return p;
}

Path _pencil(double scale) {
  final p = Path();
  p.moveTo(scale * 6, scale * 18);
  p.lineTo(scale * 18, scale * 6);
  p.moveTo(scale * 18, scale * 18);
  p.lineTo(scale * 13, scale * 13);
  p.moveTo(scale * 8, scale * 18);
  p.lineTo(scale * 6, scale * 20);
  return p;
}

Path _trash(double scale) {
  final p = Path();
  // Bin
  p.moveTo(scale * 7, scale * 8);
  p.lineTo(scale * 17, scale * 8);
  p.lineTo(scale * 16, scale * 18);
  p.lineTo(scale * 8, scale * 18);
  p.close();
  // Lid
  p.moveTo(scale * 8, scale * 8);
  p.lineTo(scale * 16, scale * 8);
  p.moveTo(scale * 10, scale * 6);
  p.lineTo(scale * 14, scale * 6);
  return p;
}

Path _checkCircle(double scale) {
  final p = Path();
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 12),
    width: scale * 16,
    height: scale * 16,
  ));
  p.moveTo(scale * 8, scale * 12);
  p.lineTo(scale * 11, scale * 15);
  p.lineTo(scale * 17, scale * 9);
  return p;
}

Path _chevronLeft(double scale) {
  final p = Path();
  p.moveTo(scale * 16, scale * 6);
  p.lineTo(scale * 8, scale * 12);
  p.lineTo(scale * 16, scale * 18);
  return p;
}

Path _dots(double scale) {
  final p = Path();
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 8, scale * 12),
    width: scale * 3,
    height: scale * 3,
  ));
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 12),
    width: scale * 3,
    height: scale * 3,
  ));
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 16, scale * 12),
    width: scale * 3,
    height: scale * 3,
  ));
  return p;
}

Path _refresh(double scale) {
  final p = Path();
  p.moveTo(scale * 12, scale * 6);
  p.arcToPoint(Offset(scale * 6, scale * 12),
      radius: Radius.circular(scale * 6), clockwise: false);
  p.lineTo(scale * 6, scale * 12);
  p.moveTo(scale * 12, scale * 18);
  p.arcToPoint(Offset(scale * 18, scale * 12),
      radius: Radius.circular(scale * 6), clockwise: true);
  p.lineTo(scale * 18, scale * 12);
  return p;
}

Path _search(double scale) {
  final p = Path();
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 10, scale * 10),
    width: scale * 8,
    height: scale * 8,
  ));
  p.moveTo(scale * 16, scale * 16);
  p.lineTo(scale * 22, scale * 22);
  return p;
}

Path _filter(double scale) {
  final p = Path();
  // Funnel shape
  p.moveTo(scale * 8, scale * 6);
  p.lineTo(scale * 16, scale * 6);
  p.lineTo(scale * 12, scale * 10);
  p.lineTo(scale * 12, scale * 14);
  p.lineTo(scale * 16, scale * 18);
  p.lineTo(scale * 8, scale * 18);
  p.close();
  return p;
}

Path _gear(double scale) {
  final p = Path();
  // Simplified gear
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 12),
    width: scale * 10,
    height: scale * 10,
  ));
  // Teeth (simplified)
  p.moveTo(scale * 12, scale * 4);
  p.lineTo(scale * 12, scale * 2);
  p.moveTo(scale * 20, scale * 12);
  p.lineTo(scale * 22, scale * 12);
  p.moveTo(scale * 12, scale * 20);
  p.lineTo(scale * 12, scale * 22);
  p.moveTo(scale * 4, scale * 12);
  p.lineTo(scale * 2, scale * 12);
  return p;
}

Path _paperclip(double scale) {
  final p = Path();
  p.moveTo(scale * 6, scale * 12);
  p.quadraticBezierTo(scale * 4, scale * 7, scale * 10, scale * 5);
  p.lineTo(scale * 12, scale * 7);
  p.quadraticBezierTo(scale * 15, scale * 9, scale * 18, scale * 16);
  p.quadraticBezierTo(scale * 16, scale * 18, scale * 12, scale * 16);
  return p;
}

Path _check(double scale) {
  final p = Path();
  p.moveTo(scale * 8, scale * 12);
  p.lineTo(scale * 11, scale * 15);
  p.lineTo(scale * 17, scale * 9);
  return p;
}

Path _x(double scale) {
  final p = Path();
  p.moveTo(scale * 6, scale * 6);
  p.lineTo(scale * 18, scale * 18);
  p.moveTo(scale * 18, scale * 6);
  p.lineTo(scale * 6, scale * 18);
  return p;
}

Path _info(double scale) {
  final p = Path();
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 11),
    width: scale * 10,
    height: scale * 10,
  ));
  p.moveTo(scale * 12, scale * 7);
  p.lineTo(scale * 12, scale * 10);
  p.moveTo(scale * 12, scale * 13);
  p.lineTo(scale * 12, scale * 17);
  return p;
}

Path _warning(double scale) {
  final p = Path();
  p.moveTo(scale * 12, scale * 6);
  p.lineTo(scale * 6, scale * 18);
  p.lineTo(scale * 18, scale * 18);
  p.close();
  p.moveTo(scale * 12, scale * 11);
  p.lineTo(scale * 12, scale * 15);
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 18),
    width: scale * 2,
    height: scale * 2,
  ));
  return p;
}

Path _xCircle(double scale) {
  final p = Path();
  p.addOval(Rect.fromCenter(
    center: Offset(scale * 12, scale * 12),
    width: scale * 16,
    height: scale * 16,
  ));
  p.moveTo(scale * 8, scale * 8);
  p.lineTo(scale * 16, scale * 16);
  p.moveTo(scale * 16, scale * 8);
  p.lineTo(scale * 8, scale * 16);
  return p;
}
