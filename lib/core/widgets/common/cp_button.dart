import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../effects/premium_shadows.dart';
import '../effects/scale_on_tap.dart';

/// CarePaw primary button widget with premium styling.
///
/// Provides consistent button styling throughout the app
/// with multiple variants for different use cases.
class CpButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool expanded;
  final bool usePremiumStyle;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? gradient;

  const CpButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.expanded = false,
    this.usePremiumStyle = true,
    this.textStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final buttonWidget = usePremiumStyle ? _buildPremiumButton(context) : _buildStandardButton();

    if (expanded) {
      return SizedBox(width: double.infinity, child: buttonWidget);
    }
    return buttonWidget;
  }

  Widget _buildPremiumButton(BuildContext context) {
    switch (variant) {
      case ButtonVariant.primary:
        return PremiumElevatedButton(
          onPressed: _getOnPressed(),
          isLoading: isLoading,
          padding: _getPadding(),
          borderRadius: _getBorderRadius(),
          gradient: gradient ?? AppColors.gradientPrimary,
          foregroundColor: foregroundColor ?? AppColors.textOnPrimary,
          backgroundColor: backgroundColor,
          width: expanded ? double.infinity : null,
          child: _buildContentChild(),
        );
      case ButtonVariant.secondary:
        return PremiumElevatedButton(
          onPressed: _getOnPressed(),
          isLoading: isLoading,
          padding: _getPadding(),
          borderRadius: _getBorderRadius(),
          backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: foregroundColor ?? AppColors.textPrimary,
          shadow: PremiumShadows.level(context, 1),
          width: expanded ? double.infinity : null,
          child: _buildContentChild(),
        );
      case ButtonVariant.outline:
        return PremiumElevatedButton(
          onPressed: _getOnPressed(),
          isLoading: isLoading,
          padding: _getPadding(),
          borderRadius: _getBorderRadius(),
          backgroundColor: backgroundColor ?? Colors.transparent,
          foregroundColor: foregroundColor ?? AppColors.primary,
          shadow: [],
          width: expanded ? double.infinity : null,
          child: _buildContentChild(),
        );
      case ButtonVariant.ghost:
        return PremiumElevatedButton(
          onPressed: _getOnPressed(),
          isLoading: isLoading,
          padding: _getPadding(),
          borderRadius: _getBorderRadius(),
          backgroundColor: backgroundColor ?? Colors.transparent,
          foregroundColor: foregroundColor ?? AppColors.textSecondary,
          shadow: [],
          width: expanded ? double.infinity : null,
          child: _buildContentChild(),
        );
      case ButtonVariant.text:
        return _buildPremiumTextButton();
      case ButtonVariant.destructive:
        return PremiumElevatedButton(
          onPressed: _getOnPressed(),
          isLoading: isLoading,
          padding: _getPadding(),
          borderRadius: _getBorderRadius(),
          gradient: gradient ?? AppColors.gradientError,
          foregroundColor: foregroundColor ?? AppColors.textOnPrimary,
          backgroundColor: backgroundColor,
          shadow: PremiumShadows.error,
          width: expanded ? double.infinity : null,
          child: _buildContentChild(),
        );
    }
  }

  Widget _buildPremiumTextButton() {
    final onPressed = _getOnPressed();
    return ScaleOnTap(
      onTap: onPressed,
      child: Opacity(
        opacity: (isLoading || isDisabled) ? 0.5 : 1.0,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          child: Padding(
            padding: _getPadding(),
            child: _buildContentChild(),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardButton() {
    switch (variant) {
      case ButtonVariant.primary:
        return _buildElevatedButton();
      case ButtonVariant.secondary:
        return _buildOutlinedButton();
      case ButtonVariant.outline:
        return _buildOutlinedButton();
      case ButtonVariant.ghost:
        return _buildTextButton();
      case ButtonVariant.text:
        return _buildTextButton();
      case ButtonVariant.destructive:
        return _buildDestructiveButton();
    }
  }

  Widget _buildElevatedButton() {
    return ElevatedButton(
      onPressed: _getOnPressed(),
      style: _getElevatedStyle(),
      child: _buildChild(),
    );
  }

  Widget _buildOutlinedButton() {
    return OutlinedButton(
      onPressed: _getOnPressed(),
      style: _getOutlinedStyle(),
      child: _buildChild(),
    );
  }

  Widget _buildTextButton() {
    return TextButton(
      onPressed: _getOnPressed(),
      style: _getTextStyle(),
      child: _buildChild(),
    );
  }

  Widget _buildDestructiveButton() {
    return ElevatedButton(
      onPressed: _getOnPressed(),
      style: _getDestructiveStyle(),
      child: _buildChild(),
    );
  }

  VoidCallback? _getOnPressed() {
    if (isLoading || isDisabled) return null;
    return onPressed;
  }

  ButtonStyle _getElevatedStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      disabledBackgroundColor: AppColors.disabled,
      disabledForegroundColor: AppColors.textOnPrimary,
      padding: _getPadding(),
      minimumSize: _getMinimumSize(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      elevation: 0,
    );
  }

  ButtonStyle _getOutlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.disabled,
      padding: _getPadding(),
      minimumSize: _getMinimumSize(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      side: BorderSide(
        color: isDisabled ? AppColors.disabled : AppColors.primary,
      ),
    );
  }

  ButtonStyle _getTextStyle() {
    return TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.disabled,
      padding: _getPadding(),
      minimumSize: _getMinimumSize(),
    );
  }

  ButtonStyle _getDestructiveStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.error,
      foregroundColor: AppColors.textOnPrimary,
      disabledBackgroundColor: AppColors.disabled,
      disabledForegroundColor: AppColors.textOnPrimary,
      padding: _getPadding(),
      minimumSize: _getMinimumSize(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      elevation: 0,
    );
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 18);
    }
  }

  Size _getMinimumSize() {
    switch (size) {
      case ButtonSize.small:
        return const Size(80, 40);
      case ButtonSize.medium:
        return const Size(120, 52);
      case ButtonSize.large:
        return const Size(160, 60);
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case ButtonSize.small:
        return 10;
      case ButtonSize.medium:
        return 14;
      case ButtonSize.large:
        return 16;
    }
  }

  Widget _buildChild() {
    if (isLoading) {
      return _buildLoadingChild();
    }
    return _buildContentChild();
  }

  Widget _buildLoadingChild() {
    return SizedBox(
      height: _getLoadingSize(),
      width: _getLoadingSize(),
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          variant == ButtonVariant.primary || variant == ButtonVariant.destructive
              ? AppColors.textOnPrimary
              : AppColors.primary,
        ),
      ),
    );
  }

  double _getLoadingSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  Widget _buildContentChild() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: 8),
        ],
        Text(text, style: textStyle ?? _getTextStyle2()),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: _getIconSize()),
        ],
      ],
    );
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  TextStyle _getTextStyle2() {
    switch (size) {
      case ButtonSize.small:
        return AppTextStyles.labelMedium;
      case ButtonSize.medium:
        return AppTextStyles.labelLarge;
      case ButtonSize.large:
        return AppTextStyles.titleSmall;
    }
  }
}

/// Button variant options
enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
  ghost,
  destructive,
}

/// Button size options
enum ButtonSize {
  small,
  medium,
  large,
}

/// Icon button variant
class CpIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? color;
  final String? tooltip;
  final double size;
  final bool usePremiumStyle;

  const CpIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.color,
    this.tooltip,
    this.size = 24,
    this.usePremiumStyle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (usePremiumStyle) {
      final effectiveOnPressed = (isLoading || isDisabled) ? null : onPressed;
      return ScaleOnTap(
        onTap: effectiveOnPressed,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: effectiveOnPressed,
            borderRadius: BorderRadius.circular(size),
            child: Container(
              width: size * 2,
              height: size * 2,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(size),
              ),
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: size,
                        height: size,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            color ?? AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  : Icon(icon, size: size, color: color ?? AppColors.primary),
            ),
          ),
        ),
      );
    }

    final button = IconButton(
      icon: isLoading
          ? SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? AppColors.primary,
                ),
              ),
            )
          : Icon(icon, size: size),
      onPressed: (isLoading || isDisabled) ? null : onPressed,
      color: color ?? AppColors.primary,
      disabledColor: AppColors.disabled,
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}