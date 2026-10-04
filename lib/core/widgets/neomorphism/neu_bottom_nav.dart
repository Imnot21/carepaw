import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/design_tokens.dart';
import 'neu_container.dart';
import 'neu_shadows.dart';
import 'neu_shapes.dart';

class NeuNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final VoidCallback? onSelected;

  const NeuNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.onSelected,
  });

  factory NeuNavItem.simple(IconData icon, String label) =>
      NeuNavItem(icon: icon, label: label);
}

class NeuBottomNav extends StatelessWidget {
  final List<NeuNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double height;

  const NeuBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.height = 54,
  }) : assert(items.length >= 2, 'at least two items');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dynamicHeight = items.length >= 6 ? 64.0 : 54.0;
    final effectiveHeight = height == 54 ? dynamicHeight : height;

    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          height: effectiveHeight,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
            borderRadius: NeuShape.panel,
            boxShadow: NeuShadow.floating(context),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavSlot(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () {
                      items[i].onSelected?.call();
                      onTap(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  final NeuNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavSlot({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColors.primary(context);
    final icon = selected ? (item.activeIcon ?? item.icon) : item.icon;

    if (selected) {
      return Semantics(
        selected: true,
        label: item.label,
        button: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: NeuContainer(
            variant: NeuVariant.pressed,
            borderRadius: NeuTokens.radiusMd,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: accent),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final labelColor = ThemeColors.textSecondary(context);
    return Semantics(
      selected: false,
      label: item.label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: labelColor),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  height: 1.1,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
