import 'package:flutter/material.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/app/theme/app_colors.dart';

/// Shared pet presentation utilities.
///
/// Eliminates duplication of species-specific formatting, icons, and colors
/// across pet_list_page, pet_form_page, and pet_detail_page.
class PetUtils {
  PetUtils._();

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
  static Widget buildAvatarPlaceholder(PetSpecies species, {double radius = 32, double? iconSize}) {
    final color = getSpeciesColor(species);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(
        getSpeciesIcon(species),
        size: iconSize ?? radius,
        color: color,
      ),
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
      return CircleAvatar(
        radius: radius,
        backgroundColor: color.withValues(alpha: 0.2),
        backgroundImage: NetworkImage(avatarUrl),
        child: buildAvatarPlaceholder(species, radius: radius, iconSize: iconSize),
      );
    }
    return buildAvatarPlaceholder(species, radius: radius, iconSize: iconSize);
  }

  /// Build an info chip for pet attributes.
  static Widget buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    double fontSize = 13,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}