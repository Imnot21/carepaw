import 'package:flutter/material.dart';

/// A flat accent medallion — a circular disc with a tinted fill and a 1px
/// accent hairline. Replaces the old neumorphic accent-glow discs.
///
/// Used for empty-state icons, section headers, and anywhere a decorative
/// colored circle appeared with a neumorphic shadow.
class NeuMedallion extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;

  const NeuMedallion({
    super.key,
    required this.child,
    required this.color,
    this.radius = 60,
    this.borderWidth = 1,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      padding: padding ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: borderWidth),
      ),
      child: Center(child: child),
    );
  }
}