import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import 'neu_container.dart';
import 'neu_shadows.dart';

/// Neumorphic circular avatar.
///
/// A raised round plate with an image or initials + species accent fill.
/// Used for pet thumbnails, user avatars, and message headers.
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

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: NeuShadow.raised(context, distance: radius * 0.15, blur: radius * 0.3),
      ),
      child: NeuContainer(
        borderRadius: radius,
        variant: NeuVariant.raised,
        color: bg,
        child: Center(child: content),
      ),
    );
  }
}