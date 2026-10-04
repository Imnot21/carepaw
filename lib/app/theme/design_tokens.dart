import 'package:flutter/material.dart';
import 'app_colors.dart';

export 'app_colors.dart' show AppColors, ThemeColors;

/// CarePaw design tokens — single source of truth.
///
/// Every spacing gap, border radius, hairline width, animation duration, and
/// opacity used by the `Neu*` surface system lives here. Widgets read from
/// [NeuTokens] so a single constant change propagates everywhere.
///
/// Usage:
/// ```dart
/// NeuContainer(borderRadius: NeuTokens.radiusMd)
/// SizedBox(height: NeuTokens.spaceMd)
/// duration: NeuTokens.durationFast
/// ```
abstract final class NeuTokens {
  // ─────────────────────────────────────────────
  // SPACING
  // ─────────────────────────────────────────────

  /// 4 dp — hairline gaps, icon-to-label nudges.
  static const double spaceXxs = 4;

  /// 8 dp — tight internal padding, between a chip icon and its label.
  static const double spaceXs = 8;

  /// 12 dp — compact padding inside small controls.
  static const double spaceSm = 12;

  /// 16 dp — default horizontal/vertical padding.
  static const double spaceMd = 16;

  /// 20 dp — comfortable section gaps.
  static const double spaceLg = 20;

  /// 24 dp — between major content blocks.
  static const double spaceXl = 24;

  /// 32 dp — page-level breathing room.
  static const double spaceXxl = 32;

  /// 48 dp — hero-section vertical rhythm.
  static const double spaceHero = 48;

  // ─────────────────────────────────────────────
  // RADIUS
  //
  // Generous, organic contours. Extruded surfaces need room: a tight radius
  // makes the top-left highlight terminate awkwardly, so the whole scale sits
  // one step above where a flat card system would put it.
  // ─────────────────────────────────────────────

  /// 12 dp — small badges, tooltips, tags.
  static const double radiusXs = 12;

  /// 16 dp — chips, icon buttons, small inputs.
  static const double radiusSm = 16;

  /// 24 dp — cards, containers, fields. The workhorse.
  static const double radiusMd = 24;

  /// 28 dp — dialogs, sheets, hero surfaces.
  static const double radiusLg = 28;

  /// 36 dp — app bars and large feature panels.
  static const double radiusXl = 36;

  /// 999 dp — full pill (buttons, chips, nav bar, FABs).
  static const double radiusPill = 999;

  // ─────────────────────────────────────────────
  // SHAPE PRESETS
  //
  // One radius per role. The asymmetric "flow" contours the app used before
  // gave each corner a different value, so no two surfaces in a stack aligned;
  // the flat system uses consistent geometry instead.
  // ─────────────────────────────────────────────

  /// The standard card contour.
  static BorderRadius get card => BorderRadius.circular(radiusMd);

  /// The standard contour for dialogs, sheets, and nav containers.
  static BorderRadius get panel => BorderRadius.circular(radiusLg);

  /// Circular contour — avatars, icon buttons, FABs.
  static BorderRadius get circle => BorderRadius.circular(radiusPill);

  /// Circular contour for small avatars.
  static BorderRadius get circleSm => BorderRadius.circular(radiusPill);

  // ─────────────────────────────────────────────
  // DEPTH — the extruded surface system
  //
  // Every raised plane is lit from the top-left and casts depth to the
  // bottom-right. Both halves are always present; a lone shadow reads as a
  // floating sticker rather than a surface with volume.
  //
  // Calibration rules that keep extrusion legible rather than mushy:
  //   • the depth shadow is the canvas hue darkened, never a neutral gray
  //   • blur ≥ 2× distance, so the highlight falls off like light and not like
  //     a bevel
  //   • light mode carries both halves; dark mode drops the light source
  //     entirely, because a white highlight on charcoal describes a light
  //     that does not exist
  // ─────────────────────────────────────────────

  /// Distance the light and depth shadows travel from the surface edge.
  static const double shadowExtrudeDistance = 6;

  /// Blur on the raised pair. Roughly 2.3× the distance.
  static const double shadowExtrudeBlur = 14;

  /// Opacity of the top-left light source in light mode.
  static const double shadowExtrudeLightOpacity = 0.85;

  /// Opacity of the bottom-right depth shadow in light mode.
  static const double shadowExtrudeDarkOpacity = 0.55;

  /// Pressed surfaces pull in tight — the plane is closer to the canvas.
  static const double shadowPressedDistance = 3;
  static const double shadowPressedBlur = 6;
  static const double shadowPressedLightOpacity = 0.35;
  static const double shadowPressedDarkOpacity = 0.55;

  /// Recessed wells use the same pair, inverted, at a longer radius so the
  /// inner falloff reads as depth rather than as a pressed button.
  static const double shadowInsetDistance = 4;
  static const double shadowInsetBlur = 10;
  static const double shadowInsetLightOpacity = 0.40;
  static const double shadowInsetDarkOpacity = 0.70;

  /// Flat surfaces carry no extrusion — they are the canvas-adjacent plane.
  static const double shadowFlatDistance = 0;
  static const double shadowFlatBlur = 0;

  /// Floating chrome — bottom nav, FAB, dialog, sheet. One offset shadow only:
  /// these sit above other surfaces, so they cast down rather than being lit
  /// from a corner.
  static const double shadowFloatingDistance = 10;
  static const double shadowFloatingBlur = 28;
  static const double shadowFloatingDarkOpacity = 0.32;
  static const double shadowFloatingDarkOpacityDark = 0.50;

  // ── Dark mode ──
  // The light source is replaced by a faint top-left rim in the surface's own
  // hue; the depth shadow becomes near-black and does more of the work.

  static const double shadowExtrudeDistanceDark = 5;
  static const double shadowExtrudeDarkOpacityDark = 0.50;
  static const double shadowExtrudeLightOpacityDark = 0.55;
  static const double shadowPressedDarkOpacityDark = 0.42;
  static const double shadowInsetDarkOpacityDark = 0.60;
  static const double shadowInsetLightOpacityDark = 0.45;

  /// Accent glow — used sparingly on a selected chip or an active FAB.
  static const double shadowAccentBlur = 12;
  static const double shadowAccentOpacity = 0.24;

  // ─────────────────────────────────────────────
  // PAGE LAYOUT
  //
  // Every screen inherits these. Page padding, section gaps, and card padding
  // are app-wide constants so two pages never disagree about where a margin
  // sits.
  // ─────────────────────────────────────────────

  /// Horizontal page padding — 20 to 24 by role, locked at 24 for reading
  /// comfort on a phone.
  static const double pagePadding = 24;

  /// Gap between major content blocks within a page.
  static const double sectionGap = 28;

  /// Gap between tightly-related elements — chips in a row, icon and label.
  static const double tightGap = 12;

  /// Padding inside a card.
  static const double cardPadding = 20;

  /// Content never stretches wider than this, so a tablet or desktop window
  /// does not fling cards to opposite edges of the screen.
  static const double maxContentWidth = 640;

  // ─────────────────────────────────────────────
  // HAIRLINES
  // ─────────────────────────────────────────────

  /// The default edge on every surface.
  static const double borderWidthThin = 1;

  /// Emphasized edge — focused fields, selected chips, active outlines.
  static const double borderWidthFocus = 1.5;

  /// Standard edge for outline controls.
  static const double borderWidthMd = 1;

  // ─────────────────────────────────────────────
  // ANIMATION DURATIONS
  // ─────────────────────────────────────────────

  /// 80 ms — micro interactions (chip press scale).
  static const Duration durationMicro = Duration(milliseconds: 80);

  /// 90 ms — button / icon-button press feedback.
  static const Duration durationFast = Duration(milliseconds: 90);

  /// 100 ms — card press scale.
  static const Duration durationCard = Duration(milliseconds: 100);

  /// 200 ms — switch slide, color fade.
  static const Duration durationMedium = Duration(milliseconds: 200);

  /// 300 ms — page transitions, skeleton in/out.
  static const Duration durationSlow = Duration(milliseconds: 300);

  /// 1500 ms — shimmer sweep cycle.
  static const Duration durationShimmer = Duration(milliseconds: 1500);

  // ─────────────────────────────────────────────
  // ANIMATION CURVES
  // ─────────────────────────────────────────────

  static const Curve curveDefault = Curves.easeOut;
  static const Curve curveSpring = Curves.elasticOut;
  static const Curve curveSharp = Curves.easeInOut;

  // ─────────────────────────────────────────────
  // OPACITY
  // ─────────────────────────────────────────────

  /// Disabled elements.
  static const double opacityDisabled = 0.50;

  /// Pressed scale for buttons. Restrained — the shadow pair already signals
  /// the press, so the transform only needs to confirm it.
  static const double scalePressed = 0.97;

  /// Cards do not scale at all. Pressing swaps the shadow pair so the plane
  /// appears to sink into the canvas, which is the quieter and more legible
  /// signal at the size a card occupies.
  static const double scalePressedCard = 1;

  /// Pressed scale for icon buttons / chips.
  static const double scalePressedSmall = 0.97;

  // ─────────────────────────────────────────────
  // ICON SIZES
  // ─────────────────────────────────────────────

  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;

  // ─────────────────────────────────────────────
  // CONTROL SIZES
  // ─────────────────────────────────────────────

  /// Minimum tap-target height (WCAG 2.5.5).
  static const double minTapTarget = 44;

  static const double buttonHeightSm = 40;
  static const double buttonHeightMd = 50;
  static const double buttonHeightLg = 58;

  static const double switchTrackWidth = 56;
  static const double switchTrackHeight = 32;
  static const double switchThumbSize = 26;

  static const double navBarHeight = 72;
  static const double appBarHeight = 64;

  // ─────────────────────────────────────────────
  // ELEVATION / Z-INDEX (conceptual, not Flutter elevation)
  // ─────────────────────────────────────────────

  /// Base canvas — scaffolds and backgrounds.
  static const int zCanvas = 0;

  /// Cards and containers raised above the canvas.
  static const int zRaised = 1;

  /// Overlays: dialogs, bottom sheets, FABs.
  static const int zOverlay = 2;

  /// Toasts and snackbars — always on top.
  static const int zToast = 3;

  // ─────────────────────────────────────────────
  // COLOR HELPERS (context-free static refs for const contexts)
  // These mirror ThemeColors but are usable without BuildContext where
  // a static default is needed (e.g. shimmer base before first build).
  // ─────────────────────────────────────────────

  static const Color colorPrimary = AppColors.primary;
  static const Color colorPrimaryDark = AppColors.primaryOnDark;
  static const Color colorSurface = AppColors.surface;
  static const Color colorSurfaceDark = AppColors.surfaceDarkMode;
  static const Color colorBackground = AppColors.background;
  static const Color colorBackgroundDark = AppColors.backgroundDark;
  static const Color colorBorder = AppColors.border;
  static const Color colorBorderDark = AppColors.borderDark;
  static const Color colorError = AppColors.error;
  static const Color colorSuccess = AppColors.success;
  static const Color colorWarning = AppColors.warning;
}
