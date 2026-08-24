import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

/// Premium glassmorphism container with frosted glass effect.
///
/// Creates a sophisticated frosted glass surface with:
/// - Blur effect for content behind
/// - Subtle gradient overlay for depth
/// - Refined border for crisp edges
/// - Optional glow effect
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double blur;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final bool useGradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.blur = 10,
    this.boxShadow,
    this.gradient,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = backgroundColor ??
        (isDark ? AppColors.glassDark : AppColors.glassLight);

    final border = borderColor ??
        (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: isDark ? AppColors.shadowDark2 : AppColors.shadow1,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
        border: Border.all(
          color: border,
          width: borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ColorFilter.mode(
            const Color(0x00FFFFFF),
            BlendMode.srcOver,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: useGradient
                  ? (gradient ??
                      LinearGradient(
                        colors: isDark
                            ? [
                                AppColors.glassHighlightDark,
                                Colors.transparent,
                              ]
                            : [
                                AppColors.glassHighlightLight,
                                Colors.transparent,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ))
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading effect for premium skeleton states.
class PremiumShimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const PremiumShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PremiumShimmer> createState() => _PremiumShimmerState();
}

class _PremiumShimmerState extends State<PremiumShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ??
        (isDark ? AppColors.surfaceContainerDark : AppColors.surfaceVariant);
    final highlight = widget.highlightColor ??
        (isDark ? AppColors.surfaceDark : AppColors.surface);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: GradientRotation(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Premium skeleton placeholder with shimmer.
class PremiumSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const PremiumSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PremiumShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
