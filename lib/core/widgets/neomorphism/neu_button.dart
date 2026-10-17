import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/design_tokens.dart';
import 'neu_container.dart';
import 'neu_style.dart';
import 'neu_svg_icon.dart';
import 'neu_motion.dart';

enum NeuButtonVariant { primary, secondary, outline, destructive, ghost, text }

enum NeuButtonSize { small, medium, large }

/// Action button.
///
/// Pressing swaps the fill rather than dipping the plate into the canvas: a
/// filled control darkens to a deeper tint, an outlined control fills with its
/// own accent tint. That state change is legible without any shadow.
class NeuButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final NeuButtonVariant variant;
  final NeuButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final String? svgAsset;
  final bool expanded;
  final NeumorphicStyle? style;

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
    this.svgAsset,
    this.expanded = false,
    this.style,
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
        scale: _pressed ? NeuTokens.scalePressed : 1,
        duration: NeuMotion.duration(context, NeuTokens.durationFast),
        curve: NeuTokens.curveDefault,
        child: GestureDetector(
          onTap: _enabled ? widget.onPressed : null,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: Opacity(
            opacity: _enabled ? 1 : NeuTokens.opacityDisabled,
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

    final button = switch (widget.variant) {
      NeuButtonVariant.primary => NeuContainer(
        padding: _getPadding(),
        borderRadius: _getRadius(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getRadius()),
        ),
        variant: _pressed ? NeuVariant.pressed : NeuVariant.raised,
        color: _pressed ? _primaryPressedFill(context) : _primaryFill(context),
        boxShadow: _pressed
            ? null
            : _accentPair(
                context,
                _primaryFill(context),
                distance: 5,
                blur: 12,
              ),
        child: content,
      ),
      NeuButtonVariant.secondary => NeuContainer(
        padding: _getPadding(),
        borderRadius: _getRadius(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getRadius()),
        ),
        variant: _pressed ? NeuVariant.pressed : NeuVariant.raised,
        child: content,
      ),
      NeuButtonVariant.outline => NeuContainer(
        padding: _getPadding(),
        borderRadius: _getRadius(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getRadius()),
        ),
        variant: _pressed ? NeuVariant.pressed : NeuVariant.raised,
        // A faint accent cast rather than a neutral pair, so an outline
        // button reads as the accented sibling of `secondary` instead of a
        // duplicate of it. No border — the tint is the edge.
        boxShadow: _pressed
            ? null
            : _accentPair(
                context,
                ThemeColors.primary(context),
                distance: 4,
                blur: 11,
                strength: 0.5,
              ),
        child: content,
      ),
      NeuButtonVariant.destructive => NeuContainer(
        padding: _getPadding(),
        borderRadius: _getRadius(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getRadius()),
        ),
        variant: _pressed ? NeuVariant.pressed : NeuVariant.raised,
        color: _pressed
            ? _destructivePressedFill(context)
            : ThemeColors.error(context),
        boxShadow: _pressed
            ? null
            : _accentPair(
                context,
                ThemeColors.error(context),
                distance: 5,
                blur: 12,
              ),
        child: content,
      ),
      NeuButtonVariant.ghost ||
      NeuButtonVariant.text => Padding(padding: _getPadding(), child: content),
    };

    return widget.expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
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
          if (widget.svgAsset != null)
            NeuSvgIcon(widget.svgAsset!, size: _getIconSize())
          else
            Icon(widget.icon, size: _getIconSize(), color: bodyColor.color),
          const SizedBox(width: 8),
        ],
        Text(widget.text, style: bodyColor),
        if (widget.trailingIcon != null && !widget.isLoading) ...[
          const SizedBox(width: 8),
          Icon(
            widget.trailingIcon,
            size: _getIconSize(),
            color: bodyColor.color,
          ),
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
      NeuButtonVariant.primary => ThemeColors.onPrimary(context),
      NeuButtonVariant.destructive => AppColors.textOnPrimary,
      NeuButtonVariant.secondary => ThemeColors.primaryText(context),
      NeuButtonVariant.outline => ThemeColors.primaryText(context),
      NeuButtonVariant.ghost => ThemeColors.textSecondary(context),
      NeuButtonVariant.text => ThemeColors.primaryText(context),
    };
    return base.copyWith(color: color);
  }

  Color _primaryFill(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColors.primaryOnDark
      : AppColors.primary;

  /// Extrusion tinted to a specific fill.
  ///
  /// A neutral grey pair on a terracotta button describes a light source that
  /// has nothing to do with the button. Both halves are pulled toward [fill]
  /// instead, so a filled control reads as a lit object of that colour rather
  /// than a coloured sticker with a grey outline.
  ///
  /// [strength] scales the depth half, which is what separates an accent cast
  /// (a hint of colour) from a full extrusion (a solid volume).
  List<BoxShadow> _accentPair(
    BuildContext context,
    Color fill, {
    double distance = 5,
    double blur = 12,
    double strength = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        BoxShadow(
          color: fill.withValues(alpha: 0.22),
          offset: Offset(-distance, -distance),
          blurRadius: blur,
        ),
        BoxShadow(
          color: AppColors.shadowDepthDark.withValues(alpha: 0.42 * strength),
          offset: Offset(distance, distance),
          blurRadius: blur,
        ),
      ];
    }
    return [
      BoxShadow(
        color: fill.lighten(0.52).withValues(alpha: 0.90),
        offset: Offset(-distance, -distance),
        blurRadius: blur,
      ),
      BoxShadow(
        color: fill.darken(0.26).withValues(alpha: 0.46 * strength),
        offset: Offset(distance, distance),
        blurRadius: blur,
      ),
    ];
  }

  /// Pressed state for a filled accent button: the same hue, one small step
  /// darker, so the change reads as "held" rather than as a disabled control —
  /// while keeping the ink label at ≥4.5:1.
  Color _primaryPressedFill(BuildContext context) =>
      Color.lerp(_primaryFill(context), Colors.black, 0.06)!;

  Color _destructivePressedFill(BuildContext context) =>
      Color.lerp(ThemeColors.error(context), Colors.black, 0.14)!;

  EdgeInsetsGeometry _getPadding() {
    return switch (widget.size) {
      NeuButtonSize.small => const EdgeInsets.symmetric(
        horizontal: NeuTokens.spaceMd,
        vertical: NeuTokens.spaceXxs,
      ),
      NeuButtonSize.medium => const EdgeInsets.symmetric(
        horizontal: NeuTokens.spaceXl,
        vertical: NeuTokens.spaceXxs,
      ),
      NeuButtonSize.large => const EdgeInsets.symmetric(
        horizontal: NeuTokens.spaceXxl,
        vertical: NeuTokens.spaceXxs,
      ),
    };
  }

  double _getMinHeight() {
    return switch (widget.size) {
      NeuButtonSize.small => NeuTokens.buttonHeightSm,
      NeuButtonSize.medium => NeuTokens.buttonHeightMd,
      NeuButtonSize.large => NeuTokens.buttonHeightLg,
    };
  }

  double _getRadius() {
    return switch (widget.size) {
      NeuButtonSize.small => NeuTokens.radiusSm,
      NeuButtonSize.medium => NeuTokens.radiusMd,
      NeuButtonSize.large => NeuTokens.radiusMd,
    };
  }

  double _getIconSize() {
    return switch (widget.size) {
      NeuButtonSize.small => NeuTokens.iconXs,
      NeuButtonSize.medium => NeuTokens.iconSm,
      NeuButtonSize.large => NeuTokens.iconMd,
    };
  }
}
