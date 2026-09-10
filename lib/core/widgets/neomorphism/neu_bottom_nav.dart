import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import 'neu_container.dart';
import 'neu_shadows.dart';

/// One destination in a [`NeuBottomNav`].
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

/// Neumorphic bottom navigation bar.
///
/// A raised pill-shaped bar with recessed slots. The active tab's icon sits on
/// a pressed blue plate; inactive tabs are flat raised plates. Replaces the
/// Material `NavigationBar` in the app shell.
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
          // Transparent shell: no solid bar behind the icons, so the per-item
          // neumorphic plates appear to float on the page background.
          child: NeuContainer(
            borderRadius: 26,
            variant: NeuVariant.transparent,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                child: selected
                    ? NeuContainer(
                        borderRadius: 16,
                        variant: NeuVariant.pressed,
                        color: accent,
                        boxShadow: NeuShadow.color(context, accent, blur: 12, opacity: 0.4),
                        child: SizedBox(
                          width: 44,
                          height: 40,
                          child: Icon(icon, size: 22, color: AppColors.textOnPrimary),
                        ),
                      )
                    : NeuContainer(
                        borderRadius: 16,
                        variant: NeuVariant.raised,
                        child: SizedBox(
                          width: 44,
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
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}