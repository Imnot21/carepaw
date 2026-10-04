import 'package:flutter/material.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/theme_colors.dart';
import 'neu_avatar.dart';
import 'neu_container.dart';

/// A tappable row — what most of CarePaw's navigation actually is.
///
/// Every settings screen, quick-link list, and user-management table had its own
/// private `_Row` widget built on a raw [ListTile]. [ListTile] brings Material's
/// own height, padding, and ink rules, which is why the rows ended up at three
/// different heights and two different divider indents.
///
/// This row is 64dp — above the 48dp minimum with room for a two-line label —
/// and its divider aligns to the text, not to the icon.
class NeuListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final ImageProvider? avatar;
  final String? initials;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  /// Set false for the last row in a group, so it does not draw a divider.
  final bool showDivider;

  /// Draw the divider at all. Off inside a group that supplies its own.
  final bool divided;

  /// Hide the leading slot entirely and pull the title to the edge.
  final bool hideLeading;

  const NeuListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.avatar,
    this.initials,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.showDivider = true,
    this.divided = true,
    this.hideLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? ThemeColors.textSecondary(context);

    Widget? leading;
    if (!hideLeading) {
      if (avatar != null || initials != null) {
        leading = NeuAvatar(
          radius: 22,
          image: avatar,
          initials: initials,
          backgroundColor: avatar == null && initials != null
              ? effectiveIconColor
              : null,
        );
      } else if (icon != null) {
        leading = NeuContainer(
          variant: NeuVariant.inset,
          borderRadius: NeuTokens.radiusSm,
          padding: const EdgeInsets.all(NeuTokens.spaceXs),
          child: Icon(icon, size: NeuTokens.iconSm, color: effectiveIconColor),
        );
      }
    }

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NeuTokens.spaceMd,
        vertical: NeuTokens.spaceSm,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: NeuTokens.tightGap),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.subtleOf(
                      Theme.of(context).brightness,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: NeuTokens.spaceXs),
            trailing!,
          ],
        ],
      ),
    );

    return Column(
      children: [
        Semantics(
          button: onTap != null,
          label: subtitle == null ? title : '$title. $subtitle',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: content,
            ),
          ),
        ),
        if (divided && showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent:
                (hideLeading
                        ? 0
                        : (avatar != null || initials != null ? 70 : 60))
                    .toDouble(),
            color: isDark ? AppColors.dividerDark : AppColors.divider,
          ),
      ],
    );
  }
}

/// A stack of [NeuListRow]s sharing one extruded card.
///
/// Rows are inset from the card rather than divided by their own borders, which
/// is what makes a settings screen read as one object instead of a table.
class NeuListGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const NeuListGroup({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: padding,
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
