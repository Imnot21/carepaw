import 'package:flutter/material.dart';
import '../../../features/pets/domain/entities/pet.dart';

/// CarePaw color palette - Premium purple primary with sophisticated depth.
///
/// Design principles:
/// - Bold purple primary for brand identity with premium depth
/// - Multi-layered surface system for glassmorphism effects
/// - Rich gradients and shadow system for elevation
/// - High contrast for accessibility (WCAG AA minimum)
/// - Pet-inspired accent colors with refined saturation
class AppColors {
  AppColors._();

  /// Transparent color for cases where no color is desired
  static const Color transparent = Color(0x00000000);

  // ============ Primary Colors - Premium Purple ============
  /// Primary brand color - Rich, deep purple with premium feel
  static const Color primary = Color(0xFF6D28D9);

  /// Primary variant - Deeper for emphasis and pressed states
  static const Color primaryDark = Color(0xFF5B21B6);

  /// Primary variant - Lighter for hover/focus states
  static const Color primaryLight = Color(0xFF8B5CF6);

  /// Primary glow - For subtle glow effects
  static const Color primaryGlow = Color(0x336D28D9);

  /// Primary container - Very light for chips, badges
  static const Color primaryContainer = Color(0xFFF3E8FF);
  static const Color onPrimaryContainer = Color(0xFF4C1D95);

  // ============ Secondary Colors - Sophisticated Purple ============
  /// Secondary brand color - Muted purple for secondary actions
  static const Color secondary = Color(0xFF9D6FFF);
  static const Color secondaryDark = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFC4B5FD);
  static const Color secondaryContainer = Color(0xFFF5F0FF);
  static const Color onSecondaryContainer = Color(0xFF4C1D95);

  // ============ Accent Colors - Refined Complementary ============
  /// Tertiary - Refined teal for accents and success states
  static const Color tertiary = Color(0xFF14B8A6);
  static const Color tertiaryDark = Color(0xFF0D9488);
  static const Color tertiaryLight = Color(0xFF5EEAD4);
  static const Color tertiaryContainer = Color(0xFFCCFBF1);
  static const Color onTertiaryContainer = Color(0xFF0F766E);

  /// Quaternary - Warm coral for energy/warning states
  static const Color quaternary = Color(0xFFF97316);
  static const Color quaternaryDark = Color(0xFFEA580C);
  static const Color quaternaryLight = Color(0xFFFED7AA);
  static const Color quaternaryContainer = Color(0xFFFFEDD5);
  static const Color onQuaternaryContainer = Color(0xFF9A3412);

  // ============ Semantic Colors ============
  /// Success - Refined emerald
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF059669);
  static const Color successGlow = Color(0x3310B981);

  /// Warning - Refined amber
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningGlow = Color(0x33F59E0B);

  /// Error - Refined red (not harsh)
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorGlow = Color(0x33EF4444);

  /// Info - Refined blue
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF2563EB);
  static const Color infoGlow = Color(0x333B82F6);

  // ============ Neutral Colors - Premium Grays ============
  /// Background - Warm off-white for premium feel
  static const Color background = Color(0xFFFAFAFB);

  /// Surface - Pure white for cards
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface tinted - Subtle purple tint for depth
  static const Color surfaceTinted = Color(0xFFF8F5FF);

  /// Surface variant - Subtle gray for sections
  static const Color surfaceVariant = Color(0xFFF1F3F5);

  /// Surface container - Slightly elevated
  static const Color surfaceContainer = Color(0xFFE8EBEF);

  /// Surface container high - For hover states
  static const Color surfaceContainerHigh = Color(0xFFDEE2E6);

  /// Surface container highest - For pressed states
  static const Color surfaceContainerHighest = Color(0xFFD0D5DD);

  /// Text colors - Rich dark gray (not harsh black)
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF475467);
  static const Color textTertiary = Color(0xFF667085);
  static const Color textHint = Color(0xFF98A2B3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  /// Divider and border - Refined subtle grays
  static const Color divider = Color(0xFFE4E7EC);
  static const Color border = Color(0xFFD0D5DD);
  static const Color borderFocus = Color(0xFF6D28D9);
  static const Color borderStrong = Color(0xFF98A2B3);

  /// Disabled state
  static const Color disabled = Color(0xFFBCC1C9);
  static const Color disabledBackground = Color(0xFFF2F4F7);

  // ============ Premium Shadow System ============
  /// Shadow level 1 - Subtle (cards, inputs)
  static const Color shadow1 = Color(0x0A101828);
  /// Shadow level 2 - Low (buttons, chips)
  static const Color shadow2 = Color(0x10101828);
  /// Shadow level 3 - Medium (modals, dropdowns)
  static const Color shadow3 = Color(0x15101828);
  /// Shadow level 4 - High (tooltips, popovers)
  static const Color shadow4 = Color(0x20101828);
  /// Shadow level 5 - Maximum (drawers, sheets)
  static const Color shadow5 = Color(0x28101828);

  /// Colored shadows for premium effects
  static const Color shadowPrimary = Color(0x336D28D9);
  static const Color shadowSuccess = Color(0x3310B981);
  static const Color shadowWarning = Color(0x33F59E0B);
  static const Color shadowError = Color(0x33EF4444);

  // ============ Glassmorphism System ============
  /// Glass background - Light theme
  static const Color glassLight = Color(0xCCFFFFFF);
  /// Glass background - Dark theme (more visible against dark surface)
  static const Color glassDark = Color(0xDD1E2025);
  /// Glass border - Light theme
  static const Color glassBorderLight = Color(0x33FFFFFF);
  /// Glass border - Dark theme (more visible)
  static const Color glassBorderDark = Color(0x66FFFFFF);
  /// Glass highlight - Light theme
  static const Color glassHighlightLight = Color(0x1AFFFFFF);
  /// Glass highlight - Dark theme (more visible)
  static const Color glassHighlightDark = Color(0x2FFFFFFF);

  // ============ Gradient System ============
  /// Primary gradient - For hero sections, primary buttons
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Primary gradient reverse
  static const LinearGradient gradientPrimaryReverse = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Secondary gradient
  static const LinearGradient gradientSecondary = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF9D6FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success gradient
  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warning gradient
  static const LinearGradient gradientWarning = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Error gradient
  static const LinearGradient gradientError = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Surface gradient - Subtle for cards
  static const LinearGradient gradientSurface = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dark surface gradient
  static const LinearGradient gradientSurfaceDark = LinearGradient(
    colors: [Color(0xFF24272D), Color(0xFF2D3138)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Hero gradient - For splash screens, onboarding
  static const LinearGradient gradientHero = LinearGradient(
    colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // ============ Pet-Specific Colors - Premium Pastel Variants ============
  /// Dog - Warm caramel
  static const Color dogAccent = Color(0xFFD4A574);
  static const Color dogAccentLight = Color(0xFFFEF3E2);
  static const Color dogAccentDark = Color(0xFFC4905A);
  static const Color dogAccentGlow = Color(0x33D4A574);

  /// Cat - Soft lavender (complements primary)
  static const Color catAccent = Color(0xFFB8A9F0);
  static const Color catAccentLight = Color(0xFFF5F0FF);
  static const Color catAccentDark = Color(0xFFA08FD8);
  static const Color catAccentGlow = Color(0x33B8A9F0);

  /// Bird - Soft sky blue
  static const Color birdAccent = Color(0xFF60A5FA);
  static const Color birdAccentLight = Color(0xFFEFF6FF);
  static const Color birdAccentDark = Color(0xFF3B82F6);
  static const Color birdAccentGlow = Color(0x3360A5FA);

  /// Rabbit - Soft rose
  static const Color rabbitAccent = Color(0xFFF472B6);
  static const Color rabbitAccentLight = Color(0xFFFDF2F8);
  static const Color rabbitAccentDark = Color(0xFFEC4899);
  static const Color rabbitAccentGlow = Color(0x33F472B6);

  /// Reptile - Soft sage
  static const Color reptileAccent = Color(0xFF86EFAC);
  static const Color reptileAccentLight = Color(0xFFF0FDF4);
  static const Color reptileAccentDark = Color(0xFF4ADE80);
  static const Color reptileAccentGlow = Color(0x3386EFAC);

  /// Other - Soft gray
  static const Color otherAccent = Color(0xFFB8B4AE);
  static const Color otherAccentLight = Color(0xFFF0EFEE);
  static const Color otherAccentDark = Color(0xFF9E9A94);
  static const Color otherAccentGlow = Color(0x33B8B4AE);

  // ============ Queue Status Colors ============
  static const Color queueWaiting = Color(0xFFF59E0B);
  static const Color queueWaitingLight = Color(0xFFFEF3C7);
  static const Color queueActive = Color(0xFF10B981);
  static const Color queueActiveLight = Color(0xFFD1FAE5);
  static const Color queueCompleted = Color(0xFF667085);
  static const Color queueCompletedLight = Color(0xFFF2F4F7);

  // ============ Appointment Status Colors ============
  static const Color appointmentPending = Color(0xFFF59E0B);
  static const Color appointmentConfirmed = Color(0xFF10B981);
  static const Color appointmentInProgress = Color(0xFF3B82F6);
  static const Color appointmentCompleted = Color(0xFF8B5CF6);
  static const Color appointmentCancelled = Color(0xFFEF4444);
  static const Color appointmentNoShow = Color(0xFF98A2B3);

  // ============ Inventory Status Colors ============
  static const Color stockNormal = Color(0xFF10B981);
  static const Color stockLow = Color(0xFFF59E0B);
  static const Color stockOut = Color(0xFFEF4444);
  static const Color stockExpiring = Color(0xFFF97316);
  static const Color stockExpired = Color(0xFFDC2626);

  // ============ Dark Theme Colors ============
  static const Color backgroundDark = Color(0xFF0B0D10);
  static const Color surfaceDark = Color(0xFF16181D);
  static const Color surfaceTintedDark = Color(0xFF1E1A2A);
  static const Color surfaceVariantDark = Color(0xFF1F2128);
  static const Color surfaceContainerDark = Color(0xFF262930);
  static const Color surfaceContainerHighDark = Color(0xFF2F333C);
  static const Color surfaceContainerHighestDark = Color(0xFF3D414C);
  static const Color textPrimaryDark = Color(0xFFF2F4F7);
  static const Color textSecondaryDark = Color(0xFFD0D5DD);
  static const Color textTertiaryDark = Color(0xFF98A2B3);
  static const Color textHintDark = Color(0xFF7A869A);
  static const Color dividerDark = Color(0xFF2F333C);
  static const Color borderDark = Color(0xFF3D414C);
  static const Color borderStrongDark = Color(0xFF50596D);
  static const Color disabledDark = Color(0xFF667085);
  static const Color disabledBackgroundDark = Color(0xFF2F333C);
  static const Color shadowDark1 = Color(0x10000000);
  static const Color shadowDark2 = Color(0x15000000);
  static const Color shadowDark3 = Color(0x20000000);
  static const Color shadowDark4 = Color(0x30000000);
  static const Color shadowDark5 = Color(0x40000000);
  static const Color glassDarkOverlay = Color(0xCC14161A);
}

/// Extension to get species colors
extension PetSpeciesColors on PetSpecies {
  Color get accentColor {
    switch (this) {
      case PetSpecies.dog:
        return AppColors.dogAccent;
      case PetSpecies.cat:
        return AppColors.catAccent;
      case PetSpecies.bird:
        return AppColors.birdAccent;
      case PetSpecies.rabbit:
        return AppColors.rabbitAccent;
      case PetSpecies.reptile:
        return AppColors.reptileAccent;
      case PetSpecies.other:
        return AppColors.otherAccent;
    }
  }

  Color get accentLightColor {
    switch (this) {
      case PetSpecies.dog:
        return AppColors.dogAccentLight;
      case PetSpecies.cat:
        return AppColors.catAccentLight;
      case PetSpecies.bird:
        return AppColors.birdAccentLight;
      case PetSpecies.rabbit:
        return AppColors.rabbitAccentLight;
      case PetSpecies.reptile:
        return AppColors.reptileAccentLight;
      case PetSpecies.other:
        return AppColors.otherAccentLight;
    }
  }

  Color get accentDarkColor {
    switch (this) {
      case PetSpecies.dog:
        return AppColors.dogAccentDark;
      case PetSpecies.cat:
        return AppColors.catAccentDark;
      case PetSpecies.bird:
        return AppColors.birdAccentDark;
      case PetSpecies.rabbit:
        return AppColors.rabbitAccentDark;
      case PetSpecies.reptile:
        return AppColors.reptileAccentDark;
      case PetSpecies.other:
        return AppColors.otherAccentDark;
    }
  }
}