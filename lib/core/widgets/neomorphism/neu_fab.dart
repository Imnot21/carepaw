import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/theme_colors.dart';
import 'neu_button.dart';
import 'neu_container.dart';
import 'neu_shadows.dart';

/// A floating action button.
///
/// The one element in the app that genuinely floats: a filled rounded square
/// with a single soft shadow and no hairline. Can be positioned via
/// [Positioned] or wrapped in a [Stack].
class NeuFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final NeuButtonVariant variant;
  final double size;
  final bool mini;
  final bool extended;
  final String? extendedText;

  const NeuFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.variant = NeuButtonVariant.primary,
    this.size = 56,
    this.mini = false,
    this.extended = false,
    this.extendedText,
  });

  /// A compact version for secondary actions.
  const NeuFAB.mini({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.variant = NeuButtonVariant.secondary,
    this.size = 40,
    this.mini = true,
    this.extended = false,
    this.extendedText,
  });

  /// An extended FAB with text label.
  const NeuFAB.extended({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.extendedText,
    this.tooltip,
    this.variant = NeuButtonVariant.primary,
    this.size = 56,
    this.mini = false,
    this.extended = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = mini ? 40.0 : size;
    final button = NeuButton(
      text: extendedText ?? '',
      onPressed: onPressed,
      isDisabled: onPressed == null,
      variant: variant,
      icon: icon,
      size: NeuButtonSize.medium,
      expanded: extended,
      trailingIcon: null,
    );

    if (extended) {
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: 50),
        child: button,
      );
    }

    return SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: Tooltip(
        message: tooltip ?? '',
        child: NeuContainer(
          variant: onPressed == null ? NeuVariant.flat : NeuVariant.raised,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          borderRadius: 999,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuTokens.radiusLg),
          ),
          boxShadow: onPressed == null
              ? NeuShadow.flat(context)
              : NeuShadow.floating(context, distance: 8, blur: 20),
          color: _resolveFill(context),
          showBorder: false,
          child: Center(
            child: Icon(
              icon,
              size: effectiveSize * 0.44,
              color: _resolveIconColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Color _resolveFill(BuildContext context) {
    if (onPressed == null) return ThemeColors.surfaceContainer(context);
    switch (variant) {
      case NeuButtonVariant.primary:
        return ThemeColors.primary(context);
      case NeuButtonVariant.destructive:
        return ThemeColors.error(context);
      case NeuButtonVariant.secondary:
        return ThemeColors.surface(context);
      default:
        return ThemeColors.primary(context);
    }
  }

  Color _resolveIconColor(BuildContext context) {
    if (onPressed == null) return ThemeColors.textTertiary(context);
    switch (variant) {
      case NeuButtonVariant.primary:
      case NeuButtonVariant.destructive:
        return ThemeColors.onPrimary(context);
      case NeuButtonVariant.secondary:
      case NeuButtonVariant.outline:
        return ThemeColors.primary(context);
      default:
        return ThemeColors.onPrimary(context);
    }
  }
}

/// A speed-dial style FAB that expands to show multiple actions.
class NeuFABSpeedDial extends StatefulWidget {
  final List<NeuFABSpeedDialAction> actions;
  final IconData mainIcon;
  final String? tooltip;
  final NeuButtonVariant variant;
  final double spacing;

  const NeuFABSpeedDial({
    super.key,
    required this.actions,
    this.mainIcon = Icons.add,
    this.tooltip,
    this.variant = NeuButtonVariant.primary,
    this.spacing = 16,
  });

  @override
  State<NeuFABSpeedDial> createState() => _NeuFABSpeedDialState();
}

class _NeuFABSpeedDialState extends State<NeuFABSpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final actionWidgets = <Widget>[];
    for (int i = 0; i < widget.actions.length; i++) {
      final action = widget.actions[i];
      final delay = (i + 1) * 0.1;
      final animation = CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
      );
      actionWidgets.add(
        FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(0, 1.5), end: Offset.zero),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.spacing),
              child: NeuFAB(
                onPressed: () {
                  action.onPressed();
                  if (_expanded) _toggle();
                },
                icon: action.icon,
                tooltip: action.label,
                variant: widget.variant,
                extended: true,
                extendedText: action.label,
                mini: true,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: actionWidgets,
            );
          },
        ),
        const SizedBox(height: 12),
        NeuFAB(
          onPressed: _toggle,
          icon: _expanded ? Icons.close : widget.mainIcon,
          tooltip: widget.tooltip,
          variant: widget.variant,
        ),
      ],
    );
  }
}

class NeuFABSpeedDialAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const NeuFABSpeedDialAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}
