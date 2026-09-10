import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/presentation/pages/pet_form_page.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';

/// Page showing detailed pet information with neumorphic design.
class PetDetailPage extends StatefulWidget {
  final Pet pet;

  const PetDetailPage({super.key, required this.pet});

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  late Pet _pet;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  void _updatePet(Pet updatedPet) {
    setState(() => _pet = updatedPet);
  }

  @override
  Widget build(BuildContext context) {
    final speciesColor = PetUtils.getSpeciesColor(_pet.species);

    return Scaffold(
      backgroundColor: _isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: NeuIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          NeuIconButton(
            icon: Icons.more_vert_rounded,
            onPressed: () => _showMenu(context),
            tooltip: 'More',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with avatar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  NeuCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _pet.avatarUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.network(
                                  _pet.avatarUrl!,
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      PetUtils.buildAvatarPlaceholder(
                                    _pet.species,
                                    radius: 55,
                                    iconSize: 55,
                                  ),
                                ),
                              )
                            : PetUtils.buildAvatarPlaceholder(
                                _pet.species,
                                radius: 55,
                                iconSize: 55,
                              ),
                        const SizedBox(height: 16),
                        Text(
                          _pet.name,
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: _isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: speciesColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PetUtils.getSpeciesIcon(_pet.species),
                                size: 16,
                                color: speciesColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                PetUtils.formatSpecies(_pet.species),
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: speciesColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick info chips
                  const SizedBox(height: 16),
                  _QuickInfoChips(pet: _pet),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Basic info section
                _buildSection(
                  context,
                  title: 'Basic Information',
                  icon: Icons.info_outline_rounded,
                  iconColor: speciesColor,
                  child: _BasicInfoCard(pet: _pet),
                ),
                const SizedBox(height: 20),

                // Weight tracking section
                _buildSection(
                  context,
                  title: 'Weight Tracking',
                  icon: Icons.monitor_weight_outlined,
                  iconColor: ThemeColors.primary(context),
                  child: _WeightTrackingCard(
                    pet: _pet,
                    onAddWeight: _showAddWeightDialog,
                  ),
                ),
                const SizedBox(height: 20),

                // Quick actions
                _buildSection(
                  context,
                  title: 'Quick Actions',
                  icon: Icons.flash_on_rounded,
                  iconColor: ThemeColors.textSecondary(context),
                  child: _QuickActionsCard(pet: _pet),
                ),
                const SizedBox(height: 20),

                // Medical records
                _buildSection(
                  context,
                  title: 'Medical Records',
                  icon: Icons.medical_services_outlined,
                  iconColor: AppColors.tertiary,
                  child: _MedicalRecordsCard(pet: _pet),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(10),
                borderRadius: 12,
                variant: NeuVariant.flat,
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => NeuCard(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MenuTile(
              icon: Icons.edit_outlined,
              title: 'Edit Pet',
              color: ThemeColors.primary(sheetContext),
              onTap: () {
                Navigator.pop(sheetContext);
                _navigateToEdit(context);
              },
            ),
            _MenuTile(
              icon: Icons.monitor_weight_outlined,
              title: 'Add Weight Entry',
              color: ThemeColors.primary(sheetContext),
              onTap: () {
                Navigator.pop(sheetContext);
                _showAddWeightDialog(context);
              },
            ),
            if (_pet.isActive)
              _MenuTile(
                icon: Icons.archive_outlined,
                title: 'Deactivate',
                color: Theme.of(sheetContext).brightness == Brightness.dark
                    ? AppColors.warningOnDark
                    : AppColors.warning,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showDeactivateDialog(context);
                },
              )
            else
              _MenuTile(
                icon: Icons.unarchive_outlined,
                title: 'Activate',
                color: Theme.of(sheetContext).brightness == Brightness.dark
                    ? AppColors.successOnDark
                    : AppColors.success,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showActivateDialog(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    // Router route wraps the form in a BlocProvider<PetBloc> and loads the
    // pet by ID; pushing PetFormPage directly would crash with
    // ProviderNotFoundException.
    context.push(Routes.petEdit.replaceAll(':id', '${_pet.id}'));
  }

  void _showAddWeightDialog(BuildContext context) {
    final weightController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _isDark ? AppColors.backgroundDark : AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Weight Entry',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: _isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current weight: ${_pet.weightKg?.toStringAsFixed(1) ?? 'Not set'} kg',
              style: AppTextStyles.bodyMedium.copyWith(
                color: _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            NeuTextField(
              controller: weightController,
              label: 'New Weight (kg)',
              hint: 'e.g., 26.5',
              prefixIcon: const Icon(Icons.monitor_weight_outlined),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveWeight(dialogContext, weightController),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary),
            ),
          ),
          NeuButton(
            text: 'Save',
            variant: NeuButtonVariant.primary,
            icon: Icons.save,
            onPressed: () => _saveWeight(dialogContext, weightController),
          ),
        ],
      ),
    );
  }

  void _saveWeight(BuildContext dialogContext, TextEditingController controller) {
    final weight = double.tryParse(controller.text);
    if (weight != null && weight > 0) {
      Navigator.of(dialogContext).pop();
      final updatedPet = _pet.copyWith(weightKg: weight, updatedAt: DateTime.now());
      _updatePet(updatedPet);
      context.read<PetBloc>().add(UpdatePetWeight(petId: _pet.id!, weightKg: weight));
    }
  }

  void _showDeactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _isDark ? AppColors.backgroundDark : AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Deactivate ${_pet.name}?',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: ThemeColors.warning(context),
          ),
        ),
        content: Text(
          'This will archive ${_pet.name}. The pet will no longer appear in active lists but can be restored later.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: _isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary),
            ),
          ),
          NeuButton(
            text: 'Deactivate',
            variant: NeuButtonVariant.destructive,
            icon: Icons.archive,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              final updatedPet = _pet.copyWith(isActive: false);
              _updatePet(updatedPet);
              context.read<PetBloc>().add(UpdatePet(pet: updatedPet));
            },
          ),
        ],
      ),
    );
  }

  void _showActivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _isDark ? AppColors.backgroundDark : AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Activate ${_pet.name}?',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: ThemeColors.success(context),
          ),
        ),
        content: Text(
          'This will restore ${_pet.name} to active status.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: _isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary),
            ),
          ),
          NeuButton(
            text: 'Activate',
            variant: NeuButtonVariant.primary,
            icon: Icons.unarchive,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              final updatedPet = _pet.copyWith(isActive: true);
              _updatePet(updatedPet);
              context.read<PetBloc>().add(UpdatePet(pet: updatedPet));
            },
          ),
        ],
      ),
    );
  }
}

/// Menu tile used in the bottom sheet
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: NeuContainer(
        padding: const EdgeInsets.all(8),
        borderRadius: 10,
        variant: NeuVariant.flat,
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Quick info chips row using PetUtils.buildInfoChip
class _QuickInfoChips extends StatelessWidget {
  final Pet pet;
  const _QuickInfoChips({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        PetUtils.buildInfoChip(
          icon: PetUtils.getSpeciesIcon(pet.species),
          label: PetUtils.formatSpecies(pet.species),
          color: PetUtils.getSpeciesColor(pet.species),
        ),
        if (pet.breed != null)
          PetUtils.buildInfoChip(
            icon: Icons.pets,
            label: pet.breed!,
            color: ThemeColors.primary(context),
          ),
        if (pet.birthDate != null)
          PetUtils.buildInfoChip(
            icon: Icons.cake_outlined,
            label: 'Age: ${PetUtils.calculateAge(pet.birthDate!)}',
            color: AppColors.tertiary,
          ),
        if (pet.weightKg != null)
          PetUtils.buildInfoChip(
            icon: Icons.monitor_weight_outlined,
            label: '${pet.weightKg!.toStringAsFixed(1)} kg',
            color: ThemeColors.primary(context),
          ),
        if (pet.microchipId != null)
          PetUtils.buildInfoChip(
            icon: Icons.nfc_outlined,
            label: 'Microchipped',
            color: ThemeColors.success(context),
          ),
      ],
    );
  }
}

/// Basic info card using PetUtils for species formatting
class _BasicInfoCard extends StatelessWidget {
  final Pet pet;
  const _BasicInfoCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(
          icon: Icons.badge_outlined,
          label: 'Name',
          value: pet.name,
          valueStyle: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        _InfoRow(
          icon: PetUtils.getSpeciesIcon(pet.species),
          label: 'Species',
          value: PetUtils.formatSpecies(pet.species),
          valueStyle: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: PetUtils.getSpeciesColor(pet.species),
          ),
        ),
        if (pet.breed != null)
          _InfoRow(icon: Icons.category_outlined, label: 'Breed', value: pet.breed!),
        if (pet.color != null)
          _InfoRow(icon: Icons.palette_outlined, label: 'Color', value: pet.color!),
        if (pet.birthDate != null)
          _InfoRow(
            icon: Icons.cake_outlined,
            label: 'Birth Date',
            value: '${pet.birthDate!.day}/${pet.birthDate!.month}/${pet.birthDate!.year}',
          ),
        if (pet.microchipId != null)
          _InfoRow(icon: Icons.nfc_outlined, label: 'Microchip ID', value: pet.microchipId!),
        _InfoRow(
          icon: Icons.flag_outlined,
          label: 'Status',
          value: pet.isActive ? 'Active' : 'Inactive',
          valueStyle: AppTextStyles.bodyMedium.copyWith(
            color: pet.isActive ? ThemeColors.success(context) : ThemeColors.warning(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        _InfoRow(
          icon: Icons.access_time_outlined,
          label: 'Created',
          value: '${pet.createdAt.day}/${pet.createdAt.month}/${pet.createdAt.year}',
        ),
        _InfoRow(
          icon: Icons.update_outlined,
          label: 'Last Updated',
          value: '${pet.updatedAt.day}/${pet.updatedAt.month}/${pet.updatedAt.year}',
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(10),
            borderRadius: 10,
            variant: NeuVariant.flat,
            child: Icon(
              icon,
              size: 22,
              color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: valueStyle ?? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Weight tracking card
class _WeightTrackingCard extends StatelessWidget {
  final Pet pet;
  final void Function(BuildContext) onAddWeight;
  const _WeightTrackingCard({required this.pet, required this.onAddWeight});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pet.weightKg != null) ...[
          Row(
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(12),
                borderRadius: 14,
                variant: NeuVariant.flat,
                child: Icon(
                  Icons.monitor_weight_outlined,
                  size: 26,
                  color: ThemeColors.primary(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Weight',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
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
                  borderRadius: 24,
                  variant: NeuVariant.flat,
                  child: Icon(
                    Icons.monitor_weight_outlined,
                    size: 56,
                    color: (isDark ? AppColors.textTertiaryOnDark : AppColors.textTertiary).withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No weight recorded yet',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Add a weight entry to track your pet's health",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                NeuButton(
                  text: 'Add First Weight',
                  onPressed: () => onAddWeight(context),
                  icon: Icons.add,
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
class _QuickActionsCard extends StatelessWidget {
  final Pet pet;
  const _QuickActionsCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.calendar_today_outlined,
          title: 'Book Appointment',
          subtitle: 'Schedule a vet visit',
          color: ThemeColors.primary(context),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment booking coming soon')),
          ),
        ),
        const Divider(height: 1, indent: 56),
        _ActionTile(
          icon: Icons.medical_services_outlined,
          title: 'View Medical Records',
          subtitle: 'Vaccinations, treatments, notes',
          color: AppColors.tertiary,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medical records coming soon')),
          ),
        ),
        const Divider(height: 1, indent: 56),
        _ActionTile(
          icon: Icons.vaccines_outlined,
          title: 'Vaccination Schedule',
          subtitle: 'Track upcoming vaccines',
          color: ThemeColors.textSecondary(context),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vaccination schedule coming soon')),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: NeuContainer(
        padding: const EdgeInsets.all(8),
        borderRadius: 10,
        variant: NeuVariant.flat,
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? AppColors.textTertiaryOnDark : AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }
}

/// Medical records card
class _MedicalRecordsCard extends StatelessWidget {
  final Pet pet;
  const _MedicalRecordsCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            NeuContainer(
              padding: const EdgeInsets.all(12),
              borderRadius: 14,
              variant: NeuVariant.flat,
              child: Icon(
                Icons.medical_services_outlined,
                size: 26,
                color: AppColors.tertiary,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Medical Records',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
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
                borderRadius: 24,
                variant: NeuVariant.flat,
                child: Icon(
                  Icons.folder_outlined,
                  size: 56,
                  color: (isDark ? AppColors.textTertiaryOnDark : AppColors.textTertiary).withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No medical records yet',
                style: AppTextStyles.titleSmall.copyWith(
                  color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Medical records will appear here after vet visits',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              NeuButton(
                text: 'View Medical Records',
                variant: NeuButtonVariant.secondary,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medical records coming soon')),
                ),
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Wrapper page that provides PetBloc and fetches pet by ID for detail view
class PetDetailPageWithBloc extends StatelessWidget {
  final int petId;
  const PetDetailPageWithBloc({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PetBloc(petRepository: context.read<PetRepository>())
        ..add(LoadPetsById(petId)),
      child: _PetDetailLoader(petId: petId),
    );
  }
}

/// Wrapper page that provides PetBloc and fetches pet by ID for edit view
class PetFormPageWithBloc extends StatelessWidget {
  final int petId;
  const PetFormPageWithBloc({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PetBloc(petRepository: context.read<PetRepository>())
        ..add(LoadPetsById(petId)),
      child: _PetFormLoader(petId: petId),
    );
  }
}

/// Loads pet by ID and shows PetDetailPage
class _PetDetailLoader extends StatelessWidget {
  final int petId;
  const _PetDetailLoader({required this.petId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetBloc, PetState>(
      builder: (context, state) {
        if (state is PetLoading) return const Scaffold(body: NeuSkeletonDetail(blocks: 4));
        if (state is PetDetailLoaded) return PetDetailPage(pet: state.pet);
        if (state is PetError) return _buildError(context, state.failure.message);
        return const Scaffold(body: NeuSkeletonDetail(blocks: 4));
      },
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: NeuIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: NeuCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeuContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 24,
                  variant: NeuVariant.flat,
                  child: Icon(Icons.error_outline, size: 64, color: ThemeColors.error(context)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error Loading Pet',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                NeuButton(
                  text: 'Retry',
                  onPressed: () => context.read<PetBloc>().add(LoadPetsById(petId)),
                  icon: Icons.refresh_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loads pet by ID and shows PetFormPage for editing
class _PetFormLoader extends StatelessWidget {
  final int petId;
  const _PetFormLoader({required this.petId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetBloc, PetState>(
      builder: (context, state) {
        if (state is PetLoading) return const Scaffold(body: NeuSkeletonDetail(blocks: 4));
        if (state is PetDetailLoaded) {
          final authState = context.read<AuthBloc>().state;
          final ownerId = authState is AuthAuthenticated ? authState.user.id! : 0;
          return PetFormPage(ownerId: ownerId, pet: state.pet);
        }
        if (state is PetError) return _buildError(context, state.failure.message);
        return const Scaffold(body: NeuSkeletonDetail(blocks: 4));
      },
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: NeuIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: NeuCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeuContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 24,
                  variant: NeuVariant.flat,
                  child: Icon(Icons.error_outline, size: 64, color: ThemeColors.error(context)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error Loading Pet',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                NeuButton(
                  text: 'Retry',
                  onPressed: () => context.read<PetBloc>().add(LoadPetsById(petId)),
                  icon: Icons.refresh_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
