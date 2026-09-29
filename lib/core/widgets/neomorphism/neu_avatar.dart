import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import 'neu_container.dart';
import 'neu_shadows.dart';
import 'neu_shapes.dart';

/// Neumorphic blob avatar — an organic, living-cell contour.
///
/// Instead of a perfect circle, the avatar uses an asymmetric blob shape so
/// every pet and person feels individual and grown. A raised plate with an
/// image, initials, or icon and a species accent fill.
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
    final bg = backgroundColor ?? ThemeColors.primary(context);
    final fg = foregroundColor ?? AppColors.textOnPrimary;
    final blobShape = radius > 24 ? NeuShape.blob : NeuShape.blobSm;

    Widget content;
    if (image != null) {
      content = ClipPath(
        clipper: _BlobClipper(blobShape),
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          boxShadow: NeuShadow.raised(
            context,
            distance: radius * 0.15,
            blur: radius * 0.3,
          ),
        ),
        child: NeuContainer(
          borderRadius: radius,
          variant: NeuVariant.raised,
          color: bg,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: blobShape),
          child: Center(child: content),
        ),
      ),
    );
  }
}

class _BlobClipper extends CustomClipper<Path> {
  final BorderRadius borderRadius;

  _BlobClipper(this.borderRadius);

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final tl = borderRadius.topLeft.x * (w / 70);
    final tr = borderRadius.topRight.x * (w / 70);
    final bl = borderRadius.bottomLeft.x * (w / 70);
    final br = borderRadius.bottomRight.x * (w / 70);

    return Path()
      ..moveTo(tl, 0)
      ..lineTo(w - tr, 0)
      ..quadraticBezierTo(w, 0, w, tr)
      ..lineTo(w, h - br)
      ..quadraticBezierTo(w, h, w - br, h)
      ..lineTo(bl, h)
      ..quadraticBezierTo(0, h, 0, h - bl)
      ..lineTo(0, tl)
      ..quadraticBezierTo(0, 0, tl, 0)
      ..close();
  }

  @override
  bool shouldReclip(_BlobClipper oldClipper) =>
      oldClipper.borderRadius != borderRadius;
}
