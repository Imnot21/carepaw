import 'package:flutter/material.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/design_tokens.dart';
import 'neu_container.dart';
import 'neu_shadows.dart';
import 'neu_shapes.dart';
import 'neu_icon.dart';
import 'neu_icon_system.dart';

/// Legacy nav item using Material Icons (kept for compatibility).
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

/// New nav item using custom neumorphic icons.
class NeuNavItemCustom {
  final NeuIconType icon;
  final NeuIconType activeIcon;
  final String label;
  final VoidCallback? onSelected;

  const NeuNavItemCustom({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.onSelected,
  });

  factory NeuNavItemCustom.simple(NeuIconType icon, String label) =>
      NeuNavItemCustom(icon: icon, activeIcon: icon, label: label);
}

/// Union type for nav items (supports both legacy and custom).
sealed class NeuNavItemBase {
  const NeuNavItemBase();

  static NeuNavItemBase legacy(NeuNavItem item) => _LegacyNavItem(item);
  static NeuNavItemBase custom(NeuNavItemCustom item) => _CustomNavItem(item);

  String get label;
  VoidCallback? get onSelected;
  NeuIconType? get customIcon;
  NeuIconType? get customActiveIcon;
  IconData? get legacyIcon;
  IconData? get legacyActiveIcon;
}

class _LegacyNavItem extends NeuNavItemBase {
  final NeuNavItem item;
  const _LegacyNavItem(this.item);

  @override
  String get label => item.label;

  @override
  VoidCallback? get onSelected => item.onSelected;

  @override
  NeuIconType? get customIcon => null;

  @override
  NeuIconType? get customActiveIcon => null;

  @override
  IconData? get legacyIcon => item.icon;

  @override
  IconData? get legacyActiveIcon => item.activeIcon;
}

class _CustomNavItem extends NeuNavItemBase {
  final NeuNavItemCustom item;
  const _CustomNavItem(this.item);

  @override
  String get label => item.label;

  @override
  VoidCallback? get onSelected => item.onSelected;

  @override
  NeuIconType? get customIcon => item.icon;

  @override
  NeuIconType? get customActiveIcon => item.activeIcon;

  @override
  IconData? get legacyIcon => null;

  @override
  IconData? get legacyActiveIcon => null;
}

class NeuBottomNav extends StatelessWidget {
  final List<NeuNavItemBase> items;
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

  /// Convenience constructor for legacy items.
  factory NeuBottomNav.legacy({
    required List<NeuNavItem> items,
    required int currentIndex,
    required ValueChanged<int> onTap,
    double height = 54,
  }) {
    return NeuBottomNav(
      items: items.map(NeuNavItemBase.legacy).toList(),
      currentIndex: currentIndex,
      onTap: onTap,
      height: height,
    );
  }

  /// Convenience constructor for custom items.
  factory NeuBottomNav.custom({
    required List<NeuNavItemCustom> items,
    required int currentIndex,
    required ValueChanged<int> onTap,
    double height = 54,
  }) {
    return NeuBottomNav(
      items: items.map(NeuNavItemBase.custom).toList(),
      currentIndex: currentIndex,
      onTap: onTap,
      height: height,
    );
  }

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
  final NeuNavItemBase item;
  final bool selected;
  final VoidCallback onTap;

  const _NavSlot({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColors.primaryText(context);
    final labelColor = ThemeColors.textSecondary(context);

    // Resolve icon based on type
    final customIcon = selected
        ? (item.customActiveIcon ?? item.customIcon)
        : item.customIcon;
    final legacyIcon = selected
        ? (item.legacyActiveIcon ?? item.legacyIcon)
        : item.legacyIcon;

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
                _buildIcon(context, customIcon, legacyIcon, accent),
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
              _buildIcon(context, customIcon, legacyIcon, labelColor),
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

  Widget _buildIcon(
    BuildContext context,
    NeuIconType? customIcon,
    IconData? legacyIcon,
    Color color,
  ) {
    if (customIcon != null) {
      return NeuIcon(
        type: customIcon,
        size: 20,
        color: color,
      );
    }
    if (legacyIcon != null) {
      return Icon(legacyIcon, size: 20, color: color);
    }
    return const SizedBox.shrink();
  }
}

/// Species icon mapping for NeuAvatar.
///
/// Each species gets a tinted neumorphic disc with custom icon.
class SpeciesIcons {
  static const Map<String, NeuIconType> _mapping = {
    'dog': NeuIconType.dog,
    'cat': NeuIconType.cat,
    'bird': NeuIconType.bird,
    'rabbit': NeuIconType.rabbit,
    'reptile': NeuIconType.reptile,
  };

  static NeuIconType forSpecies(String? species) {
    if (species == null) return NeuIconType.pets;
    final normalized = species.toLowerCase().trim();
    return _mapping[normalized] ?? NeuIconType.pets;
  }
}

/// Medical record type icon mapping.
class MedicalRecordIcons {
  static const Map<String, NeuIconType> _mapping = {
    'visit': NeuIconType.visit,
    'vaccination': NeuIconType.vaccination,
    'medication': NeuIconType.medication,
    'treatment': NeuIconType.treatment,
    'lab_test': NeuIconType.labTest,
    'prescription': NeuIconType.prescription,
    'note': NeuIconType.note,
    'alert': NeuIconType.alert,
  };

  static NeuIconType forType(String type) {
    final normalized = type.toLowerCase().replaceAll(' ', '_');
    return _mapping[normalized] ?? NeuIconType.note;
  }
}