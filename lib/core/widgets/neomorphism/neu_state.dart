import 'package:flutter/material.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/theme_colors.dart';
import 'neu_button.dart';
import 'neu_container.dart';
import 'neu_shadows.dart';

/// The three states every data screen has to answer for.
///
/// Each of the thirty-eight pages grew its own version of these, which is how
/// "No pets yet" and "You have no pets registered" and "Nothing here" ended up
/// three screens apart with three different buttons. These are the three
/// versions.
///
/// The rule for the copy: an empty state says **what goes here and how to put
/// it there**. "No data" is not an explanation — it is a dead end.

/// Nothing to show yet, and here is how to fix that.
class NeuEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  /// The primary way out. Omit only when there is genuinely nothing the user
  /// can do here — a filtered-to-nothing queue is not that, so give it a
  /// "clear filter" action instead.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A quieter escape hatch, for screens with two reasonable next steps.
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  final EdgeInsetsGeometry padding;

  const NeuEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.padding = const EdgeInsets.symmetric(
      horizontal: NeuTokens.pagePadding,
      vertical: NeuTokens.spaceXxl,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Medallion(icon: icon, color: ThemeColors.primary(context)),
              const SizedBox(height: NeuTokens.spaceLg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: NeuTokens.spaceXs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.subtleOf(
                  Theme.of(context).brightness,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: NeuTokens.spaceXl),
                NeuButton(
                  text: actionLabel!,
                  onPressed: onAction,
                  variant: NeuButtonVariant.primary,
                  expanded: true,
                ),
              ],
              if (secondaryActionLabel != null &&
                  onSecondaryAction != null) ...[
                const SizedBox(height: NeuTokens.spaceXs),
                NeuButton(
                  text: secondaryActionLabel!,
                  onPressed: onSecondaryAction,
                  variant: NeuButtonVariant.text,
                  size: NeuButtonSize.small,
                  expanded: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The disc an empty state sits on.
///
/// Recessed, not raised. An empty state is an absence, and a surface that
/// stands proud of the page would be claiming more presence than an absence
/// should get.
class _Medallion extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _Medallion({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      variant: NeuVariant.inset,
      shape: const CircleBorder(),
      padding: const EdgeInsets.all(NeuTokens.spaceLg),
      boxShadow: NeuShadow.inset(context),
      child: Icon(icon, size: 30, color: color),
    );
  }
}

/// Something went wrong, here is what, and here is the way out.
///
/// [onRetry] is not optional in spirit. An error state without a retry leaves
/// the user stranded; if the operation genuinely cannot be retried, say why in
/// [message] instead of leaving the button off.
class NeuErrorState extends StatelessWidget {
  final String message;
  final String? title;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  const NeuErrorState({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.retryLabel = 'Try again',
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: NeuTokens.pagePadding,
          vertical: NeuTokens.spaceXxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              NeuContainer(
                variant: NeuVariant.inset,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(NeuTokens.spaceLg),
                child: Icon(icon, size: 30, color: ThemeColors.error(context)),
              ),
              const SizedBox(height: NeuTokens.spaceLg),
              Text(
                title!,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: NeuTokens.spaceXs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.subtleOf(
                  Theme.of(context).brightness,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: NeuTokens.spaceXl),
                NeuButton(
                  text: retryLabel!,
                  onPressed: onRetry,
                  variant: NeuButtonVariant.outline,
                  icon: Icons.refresh_rounded,
                  expanded: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading, shaped like the thing that is coming.
///
/// A centred spinner tells the user nothing about what is arriving or how much
/// of it there will be, so the page jumps when the data lands. A skeleton that
/// matches the final layout does not.
class NeuLoadingList extends StatelessWidget {
  final int itemCount;

  const NeuLoadingList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(NeuTokens.pagePadding),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: NeuTokens.tightGap),
      itemBuilder: (_, __) => const NeuLoadingRow(),
    );
  }
}

/// One row-shaped placeholder: avatar, two text lines, trailing pill.
class NeuLoadingRow extends StatelessWidget {
  const NeuLoadingRow({super.key});

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(NeuTokens.spaceMd),
      child: Row(
        children: [
          const NeuLoadingBlock(width: 46, height: 46, circle: true),
          const SizedBox(width: NeuTokens.tightGap),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeuLoadingBlock(width: 140, height: 15),
                SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.55,
                  child: NeuLoadingBlock(width: 100, height: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: NeuTokens.tightGap),
          const NeuLoadingBlock(width: 60, height: 26, radius: 13),
        ],
      ),
    );
  }
}

/// A single shimmering block.
///
/// Wrapped rather than reused from `NeuSkeletonBox` so this file's loading
/// states stay self-contained and a later change to skeleton internals cannot
/// silently reshape every loading state in the app.
class NeuLoadingBlock extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final bool circle;

  const NeuLoadingBlock({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = 7,
    this.circle = false,
  });

  @override
  State<NeuLoadingBlock> createState() => _NeuLoadingBlockState();
}

class _NeuLoadingBlockState extends State<NeuLoadingBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: NeuTokens.durationShimmer,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.skeletonDark : AppColors.skeleton;
    final peak = isDark ? AppColors.surfaceInsetDark : AppColors.surfaceInset;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(base, peak, _controller.value),
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.circle
                ? null
                : BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
