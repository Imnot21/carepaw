import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
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

/// Neumorphic bottom navigation — a raised organic pill with recessed active
/// slot.
///
/// The active tab's icon sits on a pressed terracotta plate; inactive tabs are
/// quiet raised plates. The bar itself is a flowing pill contour, the organic
/// layer's signature at the root of every screen.
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
    this.height = 72,
  }) : assert(items.length >= 2, 'at least two items');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: height,
          child: NeuContainer(
            borderRadius: 30,
            variant: NeuVariant.raised,
            color: Theme.of(context).colorScheme.surface,
            boxShadow: NeuShadow.color(
              context,
              Theme.of(context).colorScheme.primary.withAlpha((255 * 0.12).round()),
              blur: 18,
              opacity: 0.45,
            ),
            shape: RoundedRectangleBorder(borderRadius: NeuShape.navFlow),
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
    final labelColor = selected ? accent : ThemeColors.textSecondary(context);
    final icon = selected ? (item.activeIcon ?? item.icon) : item.icon;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: selected
                      ? NeuContainer(
                          borderRadius: 18,
                          variant: NeuVariant.pressed,
                          color: accent,
                          boxShadow: NeuShadow.color(context, accent, blur: 14, opacity: 0.32),
                          child: SizedBox(
                            width: 52,
                            height: 40,
                            child: Icon(icon, size: 22, color: AppColors.textOnPrimary),
                          ),
                        )
                      : NeuContainer(
                          borderRadius: 18,
                          variant: NeuVariant.raised,
                          child: SizedBox(
                            width: 52,
                            height: 40,
                            child: Icon(icon, size: 22, color: ThemeColors.textSecondary(context)),
                          ),
                        ),
                ),
              ),
            ),
            Text(
              item.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: labelColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
