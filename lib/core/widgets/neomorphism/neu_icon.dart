import 'package:flutter/material.dart';
import '../../../app/theme/design_tokens.dart';
import 'neu_container.dart';
import 'neu_shadows.dart';
import 'neu_icon_system.dart';
import 'neu_motion.dart';

/// A neumorphic icon widget using custom handcrafted paths.
///
/// Unlike Material Icons, these are drawn as paths on a CustomPainter so they
/// integrate perfectly with the neumorphic extrusion system. The stroke color
/// inherits the ambient `onSurface` from ThemeColors, so they work in both
/// light and dark mode without explicit color.
///
/// Usage:
/// ```dart
/// NeuIcon(
///   NeuIconType.home,
///   size: NeuTokens.iconMd,
///   variant: NeuVariant.raised,
/// )
/// ```
///
/// For icon buttons, prefer `NeuIconButton` which wraps this with press feedback.
class NeuIcon extends StatelessWidget {
  final NeuIconType type;
  final double size;
  final NeuVariant variant;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final String? tooltip;

  const NeuIcon({
    super.key,
    required this.type,
    this.size = NeuTokens.iconMd,
    this.variant = NeuVariant.raised,
    this.color,
    this.backgroundColor,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve colors
    final resolvedColor = color ??
        ThemeColors.textPrimary(context); // Inherits light/dark automatically

    final resolvedBg = backgroundColor ?? _resolveBackground(context);

    final widget_ = Semantics(
      label: tooltip ?? _defaultLabel(type),
      button: onTap != null,
      child: AnimatedScale(
        scale: variant == NeuVariant.pressed ? NeuTokens.scalePressedSmall : 1,
        duration: NeuMotion.duration(context, NeuTokens.durationFast),
        curve: NeuTokens.curveDefault,
        child: GestureDetector(
          onTap: onTap,
          onTapDown: (_) =>
              onTap != null ? setState(() {}) : null, // No local state, handled by parent
          onTapUp: (_) => setState(() {}),
          onTapCancel: () => setState(() {}),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: size,
            height: size,
            decoration: variant == NeuVariant.transparent
                ? null
                : BoxDecoration(
                    color: resolvedBg,
                    shape: BoxShape.circle,
                    boxShadow: _resolveShadows(context, variant, resolvedBg, isDark),
                  ),
            child: Center(
              child: CustomPaint(
                size: Size(size * 0.7, size * 0.7),
                painter: _ColoredIconPainter(
                  type: type,
                  scale: size / 24.0,
                  color: resolvedColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: widget_);
    }
    return widget_;
  }

  Color _resolveBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (variant) {
      NeuVariant.raised => isDark ? AppColors.surfaceDarkMode : AppColors.surface,
      NeuVariant.pressed => isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
      NeuVariant.inset => isDark ? AppColors.surfaceInsetDark : AppColors.surfaceInset,
      NeuVariant.flat => isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
      NeuVariant.transparent => Colors.transparent,
    };
  }

  List<BoxShadow>? _resolveShadows(
      BuildContext context, NeuVariant variant, Color bg, bool isDark) {
    return switch (variant) {
      NeuVariant.raised => NeuShadow.raised(context),
      NeuVariant.pressed => NeuShadow.pressed(context),
      NeuVariant.inset => NeuShadow.inset(context),
      NeuVariant.flat => NeuShadow.flat(context),
      NeuVariant.transparent => null,
    };
  }

  String _defaultLabel(NeuIconType type) {
    return switch (type) {
      NeuIconType.home => 'Home',
      NeuIconType.pets => 'Pets',
      NeuIconType.calendar => 'Calendar',
      NeuIconType.reminders => 'Reminders',
      NeuIconType.profile => 'Profile',
      NeuIconType.dog => 'Dog',
      NeuIconType.cat => 'Cat',
      NeuIconType.bird => 'Bird',
      NeuIconType.rabbit => 'Rabbit',
      NeuIconType.reptile => 'Reptile',
      NeuIconType.visit => 'Visit',
      NeuIconType.vaccination => 'Vaccination',
      NeuIconType.medication => 'Medication',
      NeuIconType.treatment => 'Treatment',
      NeuIconType.labTest => 'Lab Test',
      NeuIconType.prescription => 'Prescription',
      NeuIconType.note => 'Note',
      NeuIconType.alert => 'Alert',
      NeuIconType.add => 'Add',
      NeuIconType.edit => 'Edit',
      NeuIconType.delete => 'Delete',
      NeuIconType.save => 'Save',
      NeuIconType.back => 'Back',
      NeuIconType.more => 'More',
      NeuIconType.refresh => 'Refresh',
      NeuIconType.search => 'Search',
      NeuIconType.filter => 'Filter',
      NeuIconType.settings => 'Settings',
      NeuIconType.attachment => 'Attachment',
      NeuIconType.check => 'Check',
      NeuIconType.close => 'Close',
      NeuIconType.info => 'Info',
      NeuIconType.warning => 'Warning',
      NeuIconType.error => 'Error',
      NeuIconType.success => 'Success',
    };
  }

  void setState(VoidCallback fn) {
    // No-op: parent handles press state via NeuIconButton or similar
  }
}

/// Painter that applies color to the custom icon paths.
class _ColoredIconPainter extends CustomPainter {
  final NeuIconType type;
  final double scale;
  final Color color;

  _ColoredIconPainter({
    required this.type,
    required this.scale,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale * 2.0 // 2px at 24px base
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final path = NeuIcons.pathFor(type, size.width);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ColoredIconPainter old) =>
      old.type != type || old.scale != scale || old.color != color;
}

/// Convenience factory for common icon sizes.
abstract final class NeuIconSizes {
  static NeuIcon xs(NeuIconType type) => NeuIcon(type: type, size: NeuTokens.iconXs);
  static NeuIcon sm(NeuIconType type) => NeuIcon(type: type, size: NeuTokens.iconSm);
  static NeuIcon md(NeuIconType type) => NeuIcon(type: type, size: NeuTokens.iconMd);
  static NeuIcon lg(NeuIconType type) => NeuIcon(type: type, size: NeuTokens.iconLg);
}