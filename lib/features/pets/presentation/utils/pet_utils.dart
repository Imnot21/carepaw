import 'package:flutter/material.dart';
import 'package:carepaw/app/theme/design_tokens.dart';

import 'package:carepaw/core/widgets/neomorphism/index.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';

/// Shared pet presentation utilities.
///
/// Eliminates duplication of species-specific formatting, icons, and colors
/// across pet_list_page, pet_form_page, and pet_detail_page.
class PetUtils {
  PetUtils._();

  static const _dogAccent = Color(0xFF7A6C5D);
  static const _catAccent = Color(0xFF8B7D5B);
  static const _birdAccent = Color(0xFF4A8B6E);
  static const _rabbitAccent = Color(0xFF9C7BA8);
  static const _reptileAccent = Color(0xFF5C8A6E);
  static const _otherAccent = Color(0xFF5B8BC0);

  /// Get the icon for a pet species.
  static IconData getSpeciesIcon(PetSpecies species) {
    switch (species) {
      case PetSpecies.dog:
        return Icons.pets;
      case PetSpecies.cat:
        return Icons.pets_outlined;
      case PetSpecies.bird:
        return Icons.flutter_dash;
      case PetSpecies.rabbit:
        return Icons.landscape_outlined;
      case PetSpecies.reptile:
        return Icons.eco_outlined;
      case PetSpecies.other:
        return Icons.help_outline;
    }
  }

  /// Get the color for a pet species.
  static Color getSpeciesColor(PetSpecies species) {
    switch (species) {
      case PetSpecies.dog:
        return _dogAccent;
      case PetSpecies.cat:
        return _catAccent;
      case PetSpecies.bird:
        return _birdAccent;
      case PetSpecies.rabbit:
        return _rabbitAccent;
      case PetSpecies.reptile:
        return _reptileAccent;
      case PetSpecies.other:
        return _otherAccent;
    }
  }

  /// Get the display name for a pet species.
  static String formatSpecies(PetSpecies species) {
    return species.displayName;
  }

  /// Format pet age from birth date.
  static String calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    if (months < 0 || (months == 0 && now.day < birthDate.day)) {
      years--;
      months += 12;
    }
    if (years > 0) {
      return '$years year${years > 1 ? 's' : ''}${months > 0 ? ' $months month${months > 1 ? 's' : ''}' : ''}';
    } else {
      return '$months month${months > 1 ? 's' : ''}';
    }
  }

  /// Build a species-themed avatar placeholder.
  ///
  /// An extruded disc tinted to the species hue. See [NeuAvatar] for the
  /// extrusion reasoning.
  static Widget buildAvatarPlaceholder(
    PetSpecies species, {
    double radius = 32,
    double? iconSize,
  }) {
    final color = getSpeciesColor(species);
    return NeuAvatar(
      radius: radius,
      icon: getSpeciesIcon(species),
      backgroundColor: color.withValues(alpha: 0.14),
      foregroundColor: color,
    );
  }

  /// Build a species-themed avatar with optional image.
  static Widget buildAvatar({
    required PetSpecies species,
    String? avatarUrl,
    double radius = 32,
    double? iconSize,
  }) {
    final color = getSpeciesColor(species);
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return NeuAvatar(
        radius: radius,
        image: NetworkImage(avatarUrl),
        backgroundColor: color.withValues(alpha: 0.14),
        foregroundColor: color,
      );
    }
    return buildAvatarPlaceholder(species, radius: radius, iconSize: iconSize);
  }

  /// Build an info pill for pet attributes.
  ///
  /// Sunken (pressed), not bordered. A tag is a category, not a state, and
  /// should look inset relative to the card it sits in rather than floating
  /// above it.
  static Widget buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    double fontSize = 13,
  }) {
    return NeuContainer(
      variant: NeuVariant.pressed,
      padding: const EdgeInsets.symmetric(
        horizontal: NeuTokens.spaceSm,
        vertical: NeuTokens.spaceXxs + 2,
      ),
      shape: const StadiumBorder(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
