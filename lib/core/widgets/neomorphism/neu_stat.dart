import 'package:flutter/material.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/theme_colors.dart';
import 'neu_container.dart';

/// One metric on a dashboard.
///
/// The number is the loudest thing on the card and the label is the quietest,
/// because the dashboard's job is to be read at a glance from across a clinic
/// counter — not studied. Everything between them is a recessed well holding the
/// icon, which is where the eye goes second.
class NeuStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  /// Optional change indicator. Say which direction is good: for "days until
  /// expiry" a rise is bad, for "pets registered" a rise is good, and a tile
  /// that assumes green-is-good will lie on one of them.
  final String? delta;
  final bool deltaIsGood;

  /// Tile this fills its width, for a grid. Off for a fixed-width tile in a
  /// horizontal scroller.
  final bool expanded;

  final VoidCallback? onTap;

  const NeuStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
    this.delta,
    this.deltaIsGood = true,
    this.expanded = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? ThemeColors.primary(context);
    final tile = NeuContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(NeuTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          NeuContainer(
            variant: NeuVariant.inset,
            borderRadius: NeuTokens.radiusSm,
            padding: const EdgeInsets.all(NeuTokens.spaceXs),
            child: Icon(icon, size: NeuTokens.iconSm, color: tint),
          ),
          const SizedBox(height: NeuTokens.tightGap),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.numberMedium.copyWith(
                color: ThemeColors.textPrimary(context),
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.subtleOf(
              Theme.of(context).brightness,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (delta != null) ...[
            const SizedBox(height: NeuTokens.spaceXs),
            _Delta(delta: delta!, isGood: deltaIsGood),
          ],
        ],
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: tile) : tile;
  }
}

/// A change indicator.
///
/// Reads as a pill rather than bare text so it can be scanned across a row of
/// tiles without the reader parsing each one.
class _Delta extends StatelessWidget {
  final String delta;
  final bool isGood;

  const _Delta({required this.delta, required this.isGood});

  @override
  Widget build(BuildContext context) {
    final tone = isGood
        ? ThemeColors.success(context)
        : ThemeColors.error(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: '$delta, ${isGood ? 'improving' : 'worsening'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NeuTokens.spaceXs,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            tone.withValues(alpha: isDark ? 0.20 : 0.12),
            isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
          ),
          borderRadius: BorderRadius.circular(NeuTokens.radiusXs),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              delta.trimLeft().startsWith('-')
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 12,
              color: tone,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                delta.trimLeft(),
                style: AppTextStyles.labelSmall.copyWith(color: tone),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A responsive grid of [NeuStatTile]s.
///
/// Two columns on a phone is the widest that still leaves room for a number at
/// [AppTextStyles.numberMedium] without truncating it; three on a tablet. The
/// count is never one column, because a single full-width metric is not a grid
/// and should be a [NeuStatTile] on its own.
class NeuStatGrid extends StatelessWidget {
  final List<NeuStatTile> tiles;
  final int mobileColumns;

  const NeuStatGrid({super.key, required this.tiles, this.mobileColumns = 2});

  @override
  Widget build(BuildContext context) {
    final columns = tiles.length == 1
        ? 1
        : MediaQuery.sizeOf(context).width >= 600
        ? 3
        : mobileColumns;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: NeuTokens.tightGap,
        crossAxisSpacing: NeuTokens.tightGap,
        // Square is fine for an icon, a number, and a two-line label, and it
        // keeps the grid on a rhythm without hard-coding a height.
        childAspectRatio: 0.92,
      ),
      itemCount: tiles.length,
      itemBuilder: (_, index) => tiles[index],
    );
  }
}
