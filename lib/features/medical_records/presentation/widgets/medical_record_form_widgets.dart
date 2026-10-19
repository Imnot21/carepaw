import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/medical_records/domain/entities/medical_record.dart';
import 'package:carepaw/features/medical_records/presentation/utils/medical_record_utils.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';

/// Header showing which pet the record is being created for.
class MedicalRecordPetHeader extends StatelessWidget {
  final Pet pet;
  final MedicalRecordType selectedType;
  final Color speciesColor;

  const MedicalRecordPetHeader({
    super.key,
    required this.pet,
    required this.selectedType,
    required this.speciesColor,
  });


  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PetUtils.buildAvatar(
          species: pet.species,
          radius: 36,
          iconSize: 36,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Creating record for',
                style: AppTextStyles.bodySmall.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                pet.name,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        NeuContainer(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          variant: NeuVariant.flat,
          color: speciesColor.withValues(alpha: 0.12),
          borderColor: speciesColor.withValues(alpha: 0.3),
          borderWidth: 1,
          child: Text(
            selectedType.displayName,
            style: AppTextStyles.labelMedium.copyWith(
              color: speciesColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Card with chips for choosing the medical record type.
class MedicalRecordTypeSelector extends StatelessWidget {
  final MedicalRecordType selectedType;
  final Color speciesColor;
  final ValueChanged<MedicalRecordType> onChanged;

  const MedicalRecordTypeSelector({
    super.key,
    required this.selectedType,
    required this.speciesColor,
    required this.onChanged,
  });


  @override
  Widget build(BuildContext context) {
    final types = MedicalRecordType.values;

    return NeuCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      borderColor: speciesColor.withValues(alpha: 0.2),
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuContainer(
                borderRadius: 14,
                padding: const EdgeInsets.all(12),
                variant: NeuVariant.flat,
                color: speciesColor.withValues(alpha: 0.12),
                child: const NeuSvgIcon(SvgIcons.category, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Record Type',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: types.map((type) {
              final typeInfo = MedicalRecordUtils.getTypeInfoCustom(context, type);
              return NeuChip(
                label: type.displayName,
                svgAsset: typeInfo.svgAsset,
                selected: selectedType == type,
                selectedColor: typeInfo.color,
                onTap: () => onChanged(type),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Neumorphic card wrapping a single form field with icon and text input.
class MedicalRecordFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? svgAsset;
  final int maxLines;
  final String? Function(String?)? validator;

  const MedicalRecordFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.svgAsset,
    this.maxLines = 1,
    this.validator,
  });


  @override
  Widget build(BuildContext context) {
    return NeuCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              svgAsset != null
                  ? NeuSvgIcon(svgAsset!, size: 20)
                  : Icon(icon, size: 20, color: ThemeColors.textSecondary(context)),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NeuTextField(
            controller: controller,
            hint: hint,
            maxLines: maxLines,
            validator: validator,
          ),
        ],
      ),
    );
  }
}

class MedicalRecordNotLoggedInView extends StatelessWidget {
  const MedicalRecordNotLoggedInView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Medical Record'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NeuContainer(
                borderRadius: 80,
                padding: const EdgeInsets.all(40),
                color: AppColors.primary,
                boxShadow: NeuShadow.color(
                  context,
                  AppColors.primary,
                  blur: 24,
                  opacity: 0.32,
                ),
                child: const NeuSvgIcon(SvgIcons.prescription, size: 80),
              ),
              const SizedBox(height: 28),
              Text(
                'Please log in to create records',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to add medical records for your pet',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              NeuButton(
                text: 'Log In',
                onPressed: () => context.go('/login'),
                icon: Icons.login_rounded,
                svgAsset: SvgIcons.login,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Access denied view for pet owners trying to access medical record creation/editing
class MedicalRecordAccessDeniedView extends StatelessWidget {
  final String petName;

  const MedicalRecordAccessDeniedView({super.key, required this.petName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Record'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NeuContainer(
                borderRadius: 80,
                padding: const EdgeInsets.all(40),
                color: AppColors.error,
                boxShadow: NeuShadow.color(
                  context,
                  AppColors.error,
                  blur: 24,
                  opacity: 0.28,
                ),
                child: const NeuSvgIcon(SvgIcons.block, size: 80),
              ),
              const SizedBox(height: 28),
              Text(
                'Access Denied',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.error(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Only veterinarians and clinic staff can create or edit medical records for $petName.\n\nMedical records are created during consultations and will appear here automatically.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              NeuButton(
                text: 'Go Back',
                onPressed: () => context.pop(),
                icon: Icons.arrow_back_rounded,
                svgAsset: SvgIcons.back,
                variant: NeuButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
