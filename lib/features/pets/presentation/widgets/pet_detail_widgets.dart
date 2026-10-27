import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_divider.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';

/// Menu tile used in the bottom sheet
class MenuTile extends StatelessWidget {
  final IconData icon;
  final String? svgAsset;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const MenuTile({
    super.key,
    required this.icon,
    this.svgAsset,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: NeuTokens.radiusSm,
      variant: NeuVariant.flat,
      child: Row(
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(8),
            borderRadius: NeuTokens.radiusSm,
            variant: NeuVariant.flat,
            child: svgAsset != null
                ? NeuSvgIcon(svgAsset!, size: 20)
                : Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: ThemeColors.textPrimary(context),
              ),
            ),
          ),
          const NeuSvgIcon(SvgIcons.chevronRight, size: 20),
        ],
      ),
    );
  }
}

/// Quick info chips row using PetUtils.buildInfoChip
class QuickInfoChips extends StatelessWidget {
  final Pet pet;
  const QuickInfoChips({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        NeuChip(
          label: PetUtils.formatSpecies(pet.species),
          svgAsset: PetUtils.getSpeciesSvg(pet.species),
          selected: true,
          selectedColor: PetUtils.getSpeciesColor(pet.species),
        ),
        if (pet.breed != null)
          NeuChip(
            label: pet.breed!,
            svgAsset: SvgIcons.paw,
            selected: true,
            selectedColor: ThemeColors.primary(context),
          ),
        if (pet.birthDate != null)
          NeuChip(
            label: 'Age: ${PetUtils.calculateAge(pet.birthDate!)}',
            svgAsset: SvgIcons.calendar,
            selected: true,
            selectedColor: AppColors.tertiary,
          ),
        if (pet.weightKg != null)
          NeuChip(
            label: '${pet.weightKg!.toStringAsFixed(1)} kg',
            svgAsset: SvgIcons.weightScale,
            selected: true,
            selectedColor: ThemeColors.primary(context),
          ),
        if (pet.microchipId != null)
          NeuChip(
            label: 'Microchipped',
            icon: Icons.nfc_outlined,
            svgAsset: SvgIcons.microchip,
            selected: true,
            selectedColor: ThemeColors.success(context),
          ),
      ],
    );
  }
}

/// Basic info card using PetUtils for species formatting
class BasicInfoCard extends StatelessWidget {
  final Pet pet;
  const BasicInfoCard({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(
          icon: Icons.badge_outlined,
          svgAsset: SvgIcons.badge,
          label: 'Name',
          value: pet.name,
          valueStyle: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        _InfoRow(
          svgAsset: PetUtils.getSpeciesSvg(pet.species),
          label: 'Species',
          value: PetUtils.formatSpecies(pet.species),
          valueStyle: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: PetUtils.getSpeciesColor(pet.species),
          ),
        ),
        if (pet.breed != null)
          _InfoRow(
            icon: Icons.category_outlined,
            svgAsset: SvgIcons.category,
            label: 'Breed',
            value: pet.breed!,
          ),
        if (pet.sex != null)
          _InfoRow(
            icon: pet.sex == PetSex.male
                ? Icons.male_outlined
                : Icons.female_outlined,
            svgAsset: pet.sex == PetSex.male ? SvgIcons.male : SvgIcons.female,
            label: 'Sex',
            value: pet.sex!.displayName,
          ),
        if (pet.color != null)
          _InfoRow(
            icon: Icons.palette_outlined,
            svgAsset: SvgIcons.palette,
            label: 'Color',
            value: pet.color!,
          ),
        if (pet.markings != null)
          _InfoRow(
            icon: Icons.brush_outlined,
            svgAsset: SvgIcons.brush,
            label: 'Markings',
            value: pet.markings!,
          ),
        if (pet.birthDate != null)
          _InfoRow(
            icon: Icons.cake_outlined,
            svgAsset: SvgIcons.cake,
            label: 'Birth Date',
            value:
                '${pet.birthDate!.day}/${pet.birthDate!.month}/${pet.birthDate!.year}',
          ),
        if (pet.microchipId != null)
          _InfoRow(
            icon: Icons.nfc_outlined,
            svgAsset: SvgIcons.microchip,
            label: 'Microchip ID',
            value: pet.microchipId!,
          ),
        _InfoRow(
          icon: Icons.flag_outlined,
          svgAsset: SvgIcons.flag,
          label: 'Status',
          value: pet.isActive ? 'Active' : 'Inactive',
          valueStyle: AppTextStyles.bodyMedium.copyWith(
            color: pet.isActive
                ? ThemeColors.success(context)
                : ThemeColors.warning(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        _InfoRow(
          icon: Icons.access_time_outlined,
          svgAsset: SvgIcons.schedule,
          label: 'Created',
          value:
              '${pet.createdAt.day}/${pet.createdAt.month}/${pet.createdAt.year}',
        ),
        _InfoRow(
          icon: Icons.update_outlined,
          svgAsset: SvgIcons.refresh,
          label: 'Last Updated',
          value:
              '${pet.updatedAt.day}/${pet.updatedAt.month}/${pet.updatedAt.year}',
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _InfoRow({
    this.icon,
    this.svgAsset,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(10),
            borderRadius: NeuTokens.radiusSm,
            variant: NeuVariant.flat,
            child: svgAsset != null
                ? NeuSvgIcon(svgAsset!, size: 22)
                : Icon(
                    icon!,
                    size: 22,
                    color: ThemeColors.textSecondary(context),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
            ),
          ),
          Text(
            value,
            style:
                valueStyle ??
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Weight tracking card
class WeightTrackingCard extends StatelessWidget {
  final Pet pet;
  final void Function(BuildContext) onAddWeight;
  const WeightTrackingCard({
    super.key,
    required this.pet,
    required this.onAddWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pet.weightKg != null) ...[
          Row(
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(12),
                borderRadius: NeuTokens.radiusSm,
                variant: NeuVariant.flat,
                child: const NeuSvgIcon(SvgIcons.weightScale, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Weight',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: ThemeColors.textSecondary(context),
                      ),
                    ),
                    Text(
                      '${pet.weightKg!.toStringAsFixed(1)} kg',
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.primary(context),
                      ),
                    ),
                  ],
                ),
              ),
              NeuButton(
                text: 'Add Entry',
                onPressed: () => onAddWeight(context),
                icon: Icons.add,
                svgAsset: SvgIcons.add,
                size: NeuButtonSize.medium,
              ),
            ],
          ),
        ] else ...[
          Center(
            child: Column(
              children: [
                NeuContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: NeuTokens.radiusMd,
                  variant: NeuVariant.flat,
                  child: const NeuSvgIcon(SvgIcons.weightScale, size: 56),
                ),
                const SizedBox(height: 16),
                Text(
                  'No weight recorded yet',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Add a weight entry to track your pet's health",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                NeuButton(
                  text: 'Add First Weight',
                  onPressed: () => onAddWeight(context),
                  icon: Icons.add,
                  svgAsset: SvgIcons.add,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Quick actions card
class QuickActionsCard extends StatelessWidget {
  final Pet pet;
  const QuickActionsCard({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.calendar_today_outlined,
          svgAsset: SvgIcons.calendar,
          title: 'Book Appointment',
          subtitle: 'Schedule a vet visit',
          color: ThemeColors.primary(context),
          onTap: () {
            final petId = pet.id;
            if (petId == null) return;
            context.push('${Routes.appointmentRequest}?petId=$petId');
          },
        ),
        NeuDivider(thickness: 1, indent: 56),
        _ActionTile(
          icon: Icons.medical_services_outlined,
          svgAsset: SvgIcons.visit,
          title: 'View Medical Records',
          subtitle: 'Vaccinations, treatments, notes',
          color: ThemeColors.progress(context),
          onTap: () {
            final petId = pet.id;
            if (petId == null) return;
            context.push('${Routes.medicalRecords}?petId=$petId');
          },
        ),
        NeuDivider(thickness: 1, indent: 56),
        _ActionTile(
          icon: Icons.vaccines_outlined,
          svgAsset: SvgIcons.vaccination,
          title: 'Vaccination Schedule',
          subtitle: 'Track upcoming vaccines',
          color: ThemeColors.textSecondary(context),
          onTap: () {
            final petId = pet.id;
            if (petId == null) return;
            context.push('${Routes.medicalRecords}?petId=$petId');
          },
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String? svgAsset;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    this.svgAsset,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: NeuTokens.radiusSm,
      variant: NeuVariant.flat,
      child: Row(
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(8),
            borderRadius: NeuTokens.radiusSm,
            variant: NeuVariant.flat,
            child: svgAsset != null
                ? NeuSvgIcon(svgAsset!, size: 22)
                : Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          const NeuSvgIcon(SvgIcons.chevronRight, size: 20),
        ],
      ),
    );
  }
}

/// Medical records card
class MedicalRecordsCard extends StatelessWidget {
  final Pet pet;
  const MedicalRecordsCard({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            NeuContainer(
              padding: const EdgeInsets.all(12),
              borderRadius: NeuTokens.radiusSm,
              variant: NeuVariant.flat,
              child: const NeuSvgIcon(SvgIcons.visit, size: 26),
            ),
            const SizedBox(width: 16),
            Text(
              'Medical Records',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: ThemeColors.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: NeuTokens.radiusMd,
                variant: NeuVariant.flat,
                child: const NeuSvgIcon(SvgIcons.folder, size: 56),
              ),
              const SizedBox(height: 16),
              Text(
                'No medical records yet',
                style: AppTextStyles.titleSmall.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Medical records will appear here after vet visits',
                style: AppTextStyles.bodySmall.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              NeuButton(
                text: 'View Medical Records',
                variant: NeuButtonVariant.secondary,
                onPressed: () {
                  final petId = pet.id;
                  if (petId == null) return;
                  context.push('${Routes.medicalRecords}?petId=$petId');
                },
                icon: Icons.arrow_forward_rounded,
                svgAsset: SvgIcons.forward,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
