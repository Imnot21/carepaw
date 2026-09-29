/// Soft Clinic neumorphic widget toolkit.
///
/// The material layer of the design language: soft-extruded surfaces with
/// dual light/dark shadows, organic flowing shapes, and minimalist spacing.
/// Every widget auto-adapts to light/dark brightness via
/// `Theme.of(context).brightness`.
library;

export 'neu_shadows.dart' show NeuShadow, NeuInsetShadow, NeuInsetPainter;
export 'neu_shapes.dart' show NeuShape;
export 'neu_container.dart' show NeuContainer, NeuVariant;
export 'neu_card.dart' show NeuCard;
export 'neu_button.dart' show NeuButton, NeuButtonSize, NeuButtonVariant;
export 'neu_icon_button.dart' show NeuIconButton;
export 'neu_text_field.dart' show NeuTextField;
export 'neu_switch.dart' show NeuSwitch;
export 'neu_chip.dart' show NeuChip;
export 'neu_progress.dart' show NeuProgress, NeuCircularProgress;
export 'neu_skeleton.dart'
    show NeuShimmer, NeuSkeletonBox, NeuSkeletonList, NeuSkeletonDetail;
export 'neu_avatar.dart' show NeuAvatar;
export 'neu_bottom_nav.dart' show NeuBottomNav, NeuNavItem;
