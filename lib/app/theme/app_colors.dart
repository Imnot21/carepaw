import 'package:flutter/material.dart';
import '../../../features/pets/domain/entities/pet.dart';

/// CarePaw color palette - Professional blue primary with silver accents.
///
/// Design principles:
/// - Professional blue primary for trust and medical credibility
/// - Silver/gray accents for modern, clean aesthetic
/// - Multi-layered surface system for depth effects
/// - High contrast for accessibility (WCAG AA minimum)
/// - Pet-inspired accent colors with refined saturation
class AppColors {
  AppColors._();

  /// Transparent color for cases where no color is desired
  static const Color transparent = Color(0x00000000);

  // ============ Primary Colors - Professional Blue ============
  /// Primary brand color - Professional medical blue
  static const Color primary = Color(0xFF0066CC);

  /// Primary variant - Deeper for emphasis and pressed states
  static const Color primaryDark = Color(0xFF0052A3);

  /// Primary variant - Lighter for hover/focus states
  static const Color primaryLight = Color(0xFF3385D6);

  /// Primary glow - For subtle glow effects
  static const Color primaryGlow = Color(0x330066CC);

  /// Primary container - Very light for chips, badges
  static const Color primaryContainer = Color(0xFFE6F0FA);
  static const Color onPrimaryContainer = Color(0xFF003D7A);

  // ============ Secondary Colors - Silver/Gray ============
  /// Secondary brand color - Silver for secondary actions
  static const Color secondary = Color(0xFF8A929E);

  /// Secondary variant - Darker silver
  static const Color secondaryDark = Color(0xFF6B7280);

  /// Secondary variant - Lighter silver
  static const Color secondaryLight = Color(0xFFD1D5DB);

  /// Secondary container - Very light for chips, badges
  static const Color secondaryContainer = Color(0xFFF3F4F6);
  static const Color onSecondaryContainer = Color(0xFF374151);

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

  /// Info - Professional blue (matches primary family)
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF2563EB);
  static const Color infoGlow = Color(0x333B82F6);

  // ============ Neutral Colors - Silver/Gray System ============
  /// Background - Clean off-white for professional feel
  static const Color background = Color(0xFFFAFAFA);

  /// Surface - Pure white for cards
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface tinted - Subtle blue tint for depth
  static const Color surfaceTinted = Color(0xFFF0F5FA);

  /// Surface variant - Subtle silver/gray for sections
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  /// Surface container - Slightly elevated
  static const Color surfaceContainer = Color(0xFFE5E7EB);

  /// Surface container high - For hover states
  static const Color surfaceContainerHigh = Color(0xFFD1D5DB);

  /// Surface container highest - For pressed states
  static const Color surfaceContainerHighest = Color(0xFF9CA3AF);

  /// Text colors - Rich dark gray (not harsh black)
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  /// Divider and border - Refined subtle silver/grays
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderFocus = Color(0xFF0066CC);
  static const Color borderStrong = Color(0xFF9CA3AF);

  /// Disabled state
  static const Color disabled = Color(0xFF9CA3AF);
  static const Color disabledBackground = Color(0xFFF3F4F6);

  // ============ Premium Shadow System ============
  /// Shadow level 1 - Subtle (cards, inputs)
  static const Color shadow1 = Color(0x0A111827);
  /// Shadow level 2 - Low (buttons, chips)
  static const Color shadow2 = Color(0x10111827);
  /// Shadow level 3 - Medium (modals, dropdowns)
  static const Color shadow3 = Color(0x15111827);
  /// Shadow level 4 - High (tooltips, popovers)
  static const Color shadow4 = Color(0x20111827);
  /// Shadow level 5 - Maximum (drawers, sheets)
  static const Color shadow5 = Color(0x28111827);

  /// Colored shadows for premium effects
  static const Color shadowPrimary = Color(0x330066CC);
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
    colors: [Color(0xFF0066CC), Color(0xFF3385D6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Primary gradient reverse
  static const LinearGradient gradientPrimaryReverse = LinearGradient(
    colors: [Color(0xFF3385D6), Color(0xFF0066CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Secondary gradient
  static const LinearGradient gradientSecondary = LinearGradient(
    colors: [Color(0xFF6B7280), Color(0xFF8A929E)],
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
    colors: [Color(0xFFFFFFFF), Color(0xFFF0F5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dark surface gradient
  static const LinearGradient gradientSurfaceDark = LinearGradient(
    colors: [Color(0xFF1F2937), Color(0xFF111827)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Hero gradient - For splash screens, onboarding
  static const LinearGradient gradientHero = LinearGradient(
    colors: [Color(0xFF0066CC), Color(0xFF3385D6), Color(0xFF14B8A6)],
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

  /// Other - Soft silver
  static const Color otherAccent = Color(0xFF9CA3AF);
  static const Color otherAccentLight = Color(0xFFF3F4F6);
  static const Color otherAccentDark = Color(0xFF6B7280);
  static const Color otherAccentGlow = Color(0x339CA3AF);

  // ============ Queue Status Colors ============
  static const Color queueWaiting = Color(0xFFF59E0B);
  static const Color queueWaitingLight = Color(0xFFFEF3C7);
  static const Color queueActive = Color(0xFF10B981);
  static const Color queueActiveLight = Color(0xFFD1FAE5);
  static const Color queueCompleted = Color(0xFF6B7280);
  static const Color queueCompletedLight = Color(0xFFF3F4F6);

  // ============ Appointment Status Colors ============
  static const Color appointmentPending = Color(0xFFF59E0B);
  static const Color appointmentConfirmed = Color(0xFF10B981);
  static const Color appointmentInProgress = Color(0xFF0066CC);
  static const Color appointmentCompleted = Color(0xFF8A929E);
  static const Color appointmentCancelled = Color(0xFFEF4444);
  static const Color appointmentNoShow = Color(0xFF9CA3AF);

  // ============ Inventory Status Colors ============
  static const Color stockNormal = Color(0xFF10B981);
  static const Color stockLow = Color(0xFFF59E0B);
  static const Color stockOut = Color(0xFFEF4444);
  static const Color stockExpiring = Color(0xFFF97316);
  static const Color stockExpired = Color(0xFFDC2626);

  // ============ Inventory Category Colors ============
  static const Color categoryMedicine = Color(0xFF0066CC); // Primary blue
  static const Color categoryMedicineDark = Color(0xFF3385D6);
  static const Color categoryVaccine = Color(0xFF06B6D4);  // Cyan
  static const Color categoryVaccineDark = Color(0xFF0891B2);
  static const Color categorySupply = Color(0xFF3B82F6);   // Blue (replaces purple)
  static const Color categorySupplyDark = Color(0xFF2563EB);
  static const Color categoryEquipment = Color(0xFF6366F1); // Indigo
  static const Color categoryEquipmentDark = Color(0xFF4F46E5);
  static const Color categoryFood = Color(0xFFF59E0B);     // Amber
  static const Color categoryFoodDark = Color(0xFFD97706);

  // ============ Dark Theme Colors ============
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceTintedDark = Color(0xFF1E3A5F);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color surfaceContainerDark = Color(0xFF475569);
  static const Color surfaceContainerHighDark = Color(0xFF64748B);
  static const Color surfaceContainerHighestDark = Color(0xFF94A3B8);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFE2E8F0);
  static const Color textTertiaryDark = Color(0xFF94A3B8);
  static const Color textHintDark = Color(0xFF64748B);
  static const Color dividerDark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF475569);
  static const Color borderStrongDark = Color(0xFF64748B);
  static const Color disabledDark = Color(0xFF64748B);
  static const Color disabledBackgroundDark = Color(0xFF334155);
  static const Color shadowDark1 = Color(0x10000000);
  static const Color shadowDark2 = Color(0x15000000);
  static const Color shadowDark3 = Color(0x20000000);
  static const Color shadowDark4 = Color(0x30000000);
  static const Color shadowDark5 = Color(0x40000000);
  static const Color glassDarkOverlay = Color(0xCC0F172A);
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