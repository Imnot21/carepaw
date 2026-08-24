import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

/// Animated gradient background for premium hero sections.
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;
  final Duration duration;
  final Alignment begin;
  final Alignment end;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.duration = const Duration(seconds: 8),
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ??
        [
          AppColors.primary.withValues(alpha: 0.1),
          AppColors.primaryLight.withValues(alpha: 0.05),
          AppColors.tertiary.withValues(alpha: 0.1),
        ];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.lerp(widget.begin, widget.end, _animation.value) as Alignment,
              end: Alignment.lerp(widget.end, widget.begin, _animation.value) as Alignment,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Ripple effect container for touch feedback.
class RippleContainer extends StatelessWidget {
  final Widget child;
  final Color? rippleColor;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const RippleContainer({
    super.key,
    required this.child,
    this.rippleColor,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: rippleColor?.withValues(alpha: 0.2) ?? AppColors.primary.withValues(alpha: 0.1),
        highlightColor: rippleColor?.withValues(alpha: 0.1) ?? AppColors.primary.withValues(alpha: 0.05),
        child: child,
      ),
    );
  }
}