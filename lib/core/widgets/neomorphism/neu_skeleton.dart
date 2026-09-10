import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

/// A moving sheen that makes skeleton placeholders feel alive.
///
/// Wraps [child] (typically a few [NeuSkeletonBox]es) in a [ShaderMask] whose
/// gradient is animated with a rotating transform, sweeping a highlight band
/// across the blocks. Use in place of empty spinners while data loads.
class NeuShimmer extends StatefulWidget {
  final Widget child;
  final Color? base;
  final Color? highlight;
  final Duration duration;

  const NeuShimmer({
    super.key,
    required this.child,
    this.base,
    this.highlight,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<NeuShimmer> createState() => _NeuShimmerState();
}

class _NeuShimmerState extends State<NeuShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.duration)..repeat();
    _animation = Tween<double>(begin: -1.5, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
    final base =
        widget.base ?? (isDark ? AppColors.surfaceContainerDark : AppColors.border);
    final highlight = widget.highlight ??
        (isDark ? AppColors.surfaceDarkMode : AppColors.surface);

    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            colors: [base, highlight, base],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            transform: GradientRotation(_animation.value),
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// A single neumorphic skeleton block (rounded, tinted to the canvas).
///
/// The placeholder color inverts with the theme: darker than the canvas in
/// light mode, lighter in dark mode, so it reads as a raised block. Wrap with
/// [NeuShimmer] for the animated sheen.
class NeuSkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool circle;
  final Color? color;

  const NeuSkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
    this.circle = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color ??
              (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surfaceContainerDark
                  : AppColors.border),
          borderRadius:
              BorderRadius.circular(circle ? height / 2 : borderRadius),
        ),
      ),
    );
  }
}

/// A full-page skeleton list of neumorphic card placeholders — the replacement
/// for the list pages' centered spinner.
class NeuSkeletonList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const NeuSkeletonList({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
  });

  @override
  Widget build(BuildContext context) {
    return NeuShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, _) => const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Avatar circle
          const SizedBox(
            width: 46,
            height: 46,
            child: NeuSkeletonBox(circle: true, color: Colors.transparent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                NeuSkeletonBox(height: 15, borderRadius: 7),
                SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.55,
                  child: NeuSkeletonBox(height: 12, borderRadius: 6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Status pill
          const SizedBox(
            width: 60,
            height: 26,
            child: NeuSkeletonBox(borderRadius: 13, color: Colors.transparent),
          ),
        ],
      ),
    );
  }
}

/// A skeleton layout for flat/detail pages: a headline plus a few content
/// blocks, all under one [NeuShimmer].
class NeuSkeletonDetail extends StatelessWidget {
  final int blocks;
  final EdgeInsetsGeometry padding;

  const NeuSkeletonDetail({
    super.key,
    this.blocks = 3,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return NeuShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const NeuSkeletonBox(height: 26, borderRadius: 12),
            const SizedBox(height: 10),
            const FractionallySizedBox(
              widthFactor: 0.4,
              child: NeuSkeletonBox(height: 14, borderRadius: 7),
            ),
            const SizedBox(height: 28),
            for (var i = 0; i < blocks; i++) ...[
              _SkeletonBlock(),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeuSkeletonBox(height: 14, borderRadius: 7),
          SizedBox(height: 12),
          NeuSkeletonBox(height: 12, borderRadius: 6),
          SizedBox(height: 12),
          FractionallySizedBox(
            widthFactor: 0.8,
            child: NeuSkeletonBox(height: 12, borderRadius: 6),
          ),
        ],
      ),
    );
  }
}