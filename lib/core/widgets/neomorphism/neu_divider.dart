import 'package:flutter/material.dart';
import '../../../app/theme/theme_colors.dart';

/// A hairline rule replacing [Divider].
///
/// One warm-gray line, no bevel. Supports vertical and horizontal
/// orientations.
class NeuDivider extends StatelessWidget {
  final double thickness;
  final Color? color;
  final double indent;
  final double endIndent;

  const NeuDivider({
    super.key,
    this.thickness = 1,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  });

  /// A vertical divider for row layouts.
  const NeuDivider.vertical({
    super.key,
    this.thickness = 1,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? ThemeColors.divider(context);

    return Padding(
      padding: EdgeInsets.only(left: indent, right: endIndent),
      child: Container(
        height: thickness,
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(thickness / 2),
        ),
      ),
    );
  }
}

/// A vertical divider for row layouts.
class NeuVerticalDivider extends StatelessWidget {
  final double thickness;
  final Color? color;
  final double indent;
  final double endIndent;

  const NeuVerticalDivider({
    super.key,
    this.thickness = 1,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? ThemeColors.divider(context);

    return Padding(
      padding: EdgeInsets.only(top: indent, bottom: endIndent),
      child: Container(
        width: thickness,
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(thickness / 2),
        ),
      ),
    );
  }
}

/// A section divider with optional label — for grouping related content.
class NeuSectionDivider extends StatelessWidget {
  final String label;
  final double thickness;
  final Color? color;
  final TextStyle? labelStyle;

  const NeuSectionDivider({
    super.key,
    required this.label,
    this.thickness = 1,
    this.color,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? ThemeColors.divider(context);
    final effectiveStyle =
        labelStyle ??
        Theme.of(context).textTheme.labelMedium?.copyWith(
          color: ThemeColors.textSecondary(context),
          letterSpacing: 0.8,
        );

    return Row(
      children: [
        Expanded(
          child: NeuDivider(thickness: thickness, color: effectiveColor),
        ),
        const SizedBox(width: 16),
        Text(label.toUpperCase(), style: effectiveStyle),
        const SizedBox(width: 16),
        Expanded(
          child: NeuDivider(thickness: thickness, color: effectiveColor),
        ),
      ],
    );
  }
}
