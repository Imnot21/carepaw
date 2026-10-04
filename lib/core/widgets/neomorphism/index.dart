/// CarePaw surface toolkit.
///
/// The extruded layer of the design language: planes lit from the top-left and
/// casting depth to the bottom-right, wells carved out of the canvas, and pill
/// controls. Separation comes from the light/depth pair, not from borders.
///
/// Every widget auto-adapts to light/dark brightness via
/// `Theme.of(context).brightness`.
library;

export 'neu_shadows.dart' show NeuShadow;
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
export 'neu_medallion.dart' show NeuMedallion;
export 'neu_bottom_nav.dart' show NeuBottomNav, NeuNavItem;
export 'neu_dialog.dart' show NeuDialog, NeuConfirmDialog, NeuBottomSheet;
export 'neu_divider.dart'
    show NeuDivider, NeuVerticalDivider, NeuSectionDivider;
export 'neu_fab.dart' show NeuFAB, NeuFABSpeedDial, NeuFABSpeedDialAction;
export 'neu_style.dart' show NeumorphicStyle, ShadowPreset;

// ── Page composition ────────────────────────────────────────
// Shared scaffolding so no two pages disagree about padding, bar height, or
// content width.

export 'neu_page.dart' show NeuPage, NeuPageAppBar, NeuFloatingBar;
export 'neu_section.dart'
    show NeuSection, NeuSectionHeader, NeuDetailRow, NeuDetailGroup;
export 'neu_state.dart'
    show
        NeuEmptyState,
        NeuErrorState,
        NeuLoadingList,
        NeuLoadingRow,
        NeuLoadingBlock;
export 'neu_stat.dart' show NeuStatTile, NeuStatGrid;
export 'neu_badge.dart'
    show NeuStatusBadge, NeuStatusTone, NeuStatusToneResolver, NeuTag;
export 'neu_row.dart' show NeuListRow, NeuListGroup;
export 'neu_filter_bar.dart' show NeuFilterBar, NeuChipRow;
export 'neu_feedback.dart' show NeuToast, NeuToastTone;
