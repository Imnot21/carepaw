import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import 'neu_container.dart';

/// NeuButton variants.
enum NeuButtonVariant {
  /// Solid blue accent — primary actions.
  primary,

  /// Raised surface with primary text — secondary actions.
  secondary,

  /// Outline border with primary text — tertiary actions.
  outline,

  /// Solid red — destructive actions.
  destructive,

  /// Transparent with secondary text — subtle actions.
  ghost,

  /// Text-only primary link.
  text,
}

/// NeuButton sizes.
enum NeuButtonSize {
  small,
  medium,
  large,
}

/// Neumorphic action button with physical press feedback.
///
/// Replaces the legacy `CpButton`. A pressed button dips into the canvas —
/// scale + shadow swap — like a real physical control.
class NeuButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final NeuButtonVariant variant;
  final NeuButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool expanded;

  const NeuButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.variant = NeuButtonVariant.primary,
    this.size = NeuButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.expanded = false,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _pressed = false;

  void _handleTapDown(_) {
    if (_enabled) setState(() => _pressed = true);
  }

  void _handleTapUp(_) {
    if (_enabled) setState(() => _pressed = false);
  }

  void _handleTapCancel() {
    if (_enabled) setState(() => _pressed = false);
  }

  bool get _enabled => !widget.isDisabled && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.text,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: _enabled ? widget.onPressed : null,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: Opacity(
            opacity: _enabled ? 1 : 0.5,
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final body = _buildContent(context);
    final content = SizedBox(
      height: _getMinHeight(),
      child: Center(child: body),
    );

    switch (widget.variant) {
      case NeuButtonVariant.primary:
        return NeuContainer(
          padding: _getPadding(),
          borderRadius: _getRadius(),
          variant: _pressed ? NeuVariant.pressed : NeuVariant.raised,
          child: content,
        );
      case NeuButtonVariant.secondary:
        return NeuContainer(
          padding: _getPadding(),
          borderRadius: _getRadius(),
          variant: _pressed ? NeuVariant.pressed : NeuVariant.raised,
          child: content,
        );
      case NeuButtonVariant.outline:
        return NeuContainer(
          padding: _getPadding(),
          borderRadius: _getRadius(),
          variant: NeuVariant.transparent,
          borderColor: AppColors.primary,
          borderWidth: 1.5,
          child: content,
        );
      case NeuButtonVariant.destructive:
        return NeuContainer(
          padding: _getPadding(),
          borderRadius: _getRadius(),
          variant: _pressed ? NeuVariant.pressed : NeuVariant.raised,
          color: AppColors.error,
          child: content,
        );
      case NeuButtonVariant.ghost:
      case NeuButtonVariant.text:
        return Padding(
          padding: _getPadding(),
          child: content,
        );
    }
  }

  Widget _buildContent(BuildContext context) {
    final bodyColor = _getBodyStyle(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: _getIconSize(),
            height: _getIconSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: bodyColor.color,
            ),
          ),
          const SizedBox(width: 10),
        ],
        if (widget.icon != null && !widget.isLoading) ...[
          Icon(widget.icon, size: _getIconSize(), color: bodyColor.color),
          const SizedBox(width: 8),
        ],
        Text(widget.text, style: bodyColor),
        if (widget.trailingIcon != null && !widget.isLoading) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon, size: _getIconSize(), color: bodyColor.color),
        ],
      ],
    );
  }

  TextStyle _getBodyStyle(BuildContext context) {
    final base = switch (widget.size) {
      NeuButtonSize.small => AppTextStyles.labelMedium,
      NeuButtonSize.medium => AppTextStyles.labelLarge,
      NeuButtonSize.large => AppTextStyles.titleSmall,
    };
    final color = switch (widget.variant) {
      NeuButtonVariant.primary => AppColors.textOnPrimary,
      NeuButtonVariant.destructive => AppColors.textOnPrimary,
      NeuButtonVariant.secondary => AppColors.primary,
      NeuButtonVariant.outline => AppColors.primary,
      NeuButtonVariant.ghost => AppColors.textSecondary,
      NeuButtonVariant.text => AppColors.primary,
    };
    return base.copyWith(color: color);
  }

  EdgeInsetsGeometry _getPadding() {
    return switch (widget.size) {
      NeuButtonSize.small =>
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      NeuButtonSize.medium =>
        const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      NeuButtonSize.large =>
        const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
    };
  }

  double _getMinHeight() {
    return switch (widget.size) {
      NeuButtonSize.small => 40,
      NeuButtonSize.medium => 50,
      NeuButtonSize.large => 58,
    };
  }

  double _getRadius() {
    return switch (widget.size) {
      NeuButtonSize.small => 12,
      NeuButtonSize.medium => 16,
      NeuButtonSize.large => 18,
    };
  }

  double _getIconSize() {
    return switch (widget.size) {
      NeuButtonSize.small => 16,
      NeuButtonSize.medium => 20,
      NeuButtonSize.large => 24,
    };
  }
}