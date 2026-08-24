import 'package:flutter/material.dart';

/// Pulsing glow effect widget that animates a glow around a child.
class PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxRadius;
  final Duration duration;
  final double minRadius;

  const PulsingGlow({
    super.key,
    required this.child,
    required this.glowColor,
    this.maxRadius = 30.0,
    this.duration = const Duration(seconds: 2),
    this.minRadius = 0.0,
  });

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
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

    _animation = Tween<double>(
      begin: widget.minRadius,
      end: widget.maxRadius,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _GlowPainter(
            glowColor: widget.glowColor,
            radius: _animation.value,
            childSize: widget.child is RenderBox
                ? (widget.child as RenderBox).size
                : Size.zero,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _GlowPainter extends CustomPainter {
  final Color glowColor;
  final double radius;
  final Size childSize;

  _GlowPainter({
    required this.glowColor,
    required this.radius,
    required this.childSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius);

    // Draw multiple layers for more intense glow
    for (double r = radius; r > 0; r -= radius / 3) {
      paint.color = glowColor.withValues( alpha: (r / radius) * 0.15);
      canvas.drawCircle(center, r + (childSize.width / 2).clamp(0.0, 50.0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _GlowPainter &&
        oldDelegate.glowColor != glowColor &&
        oldDelegate.radius != radius;
  }
}