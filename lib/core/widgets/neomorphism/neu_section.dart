import 'package:flutter/material.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/theme_colors.dart';
import 'neu_container.dart';

/// A titled block of content.
///
/// Every screen on this app had its own private `_buildSection` — a title, a
/// "View all" action, and a gap that was 12 on one page and 28 on another. This
/// is that pattern, once.
///
/// The header sits closer to the content it labels than to the section above
/// it: a heading belongs to what follows it, so the gap above is the larger
/// one.
///
/// ```dart
/// NeuSection(
///   title: 'Upcoming',
///   actionLabel: 'View all',
///   onAction: () => context.push(Routes.appointments),
///   child: _UpcomingCard(),
/// )
/// ```
class NeuSection extends StatelessWidget {
  final String title;
  final Widget? child;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  /// Gap above the heading. This is the larger of the two gaps on purpose.
  final double topGap;

  /// Gap between the heading and the content it labels.
  final double headerGap;

  const NeuSection({
    super.key,
    required this.title,
    this.child,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.topGap = NeuTokens.sectionGap,
    this.headerGap = NeuTokens.tightGap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeuSectionHeader(
            title: title,
            actionLabel: actionLabel,
            onAction: onAction,
            trailing: trailing,
          ),
          if (child != null) ...[SizedBox(height: headerGap), child!],
        ],
      ),
    );
  }
}

/// The heading row on its own, for when the content is not a single child.
class NeuSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  /// Render the title in the quiet tertiary weight instead of the default
  /// semibold. Use for a minor grouping inside an already-titled section.
  final bool quiet;

  const NeuSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.quiet = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = quiet
        ? AppTextStyles.labelLarge.copyWith(
            color: ThemeColors.textSecondary(context),
          )
        : AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing!,
        if (actionLabel != null && onAction != null)
          _HeaderAction(label: actionLabel!, onTap: onAction!),
      ],
    );
  }
}

/// The "View all" affordance at the end of a section heading.
///
/// A text action, not a button: it is a navigational shortcut, not a
/// commitment, and giving it a plate would make it compete with the real
/// actions on the screen.
class _HeaderAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: NeuTokens.minTapTarget,
            minWidth: NeuTokens.minTapTarget,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NeuTokens.spaceXs,
              ),
              child: Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: ThemeColors.primary(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A label/value pair, the shape most detail screens are built from.
///
/// Replacing the ad-hoc `Row(Text, Text)` pairs that were repeated across
/// twenty-odd pages, which is where mismatched label weights crept in.
class NeuDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final bool isLast;

  const NeuDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : NeuTokens.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: NeuTokens.iconSm,
              color: ThemeColors.textTertiary(context),
            ),
            const SizedBox(width: NeuTokens.spaceXs),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.subtleOf(
                Theme.of(context).brightness,
              ),
            ),
          ),
          const SizedBox(width: NeuTokens.spaceMd),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? ThemeColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A recessed group of related detail rows.
///
/// The inset variant, not a card: detail rows are reference material, not
/// objects the user acts on, so they read best as something the page has carved
/// out rather than as a card sitting on top of it.
class NeuDetailGroup extends StatelessWidget {
  final List<Widget> children;

  const NeuDetailGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      variant: NeuVariant.inset,
      padding: const EdgeInsets.all(NeuTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
