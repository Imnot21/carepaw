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
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shapes.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_divider.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';

/// Page showing detailed pet information with the CarePaw surface system.
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

  void _updatePet(Pet updatedPet) {
    setState(() => _pet = updatedPet);
  }

  @override
  Widget build(BuildContext context) {
    final speciesColor = PetUtils.getSpeciesColor(_pet.species);

    return Scaffold(
      backgroundColor: ThemeColors.background(context),
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
                    padding: const EdgeInsets.all(28),
                    shape: RoundedRectangleBorder(borderRadius: NeuShape.card),
                    child: Column(
                      children: [
                        _pet.avatarUrl != null
                            ? NeuAvatar(
                                radius: 55,
                                image: NetworkImage(_pet.avatarUrl!),
                                backgroundColor: speciesColor.withValues(
                                  alpha: 0.14,
                                ),
                                foregroundColor: speciesColor,
                              )
                            : NeuAvatar(
                                radius: 55,
                                icon: PetUtils.getSpeciesIcon(_pet.species),
                                backgroundColor: speciesColor.withValues(
                                  alpha: 0.14,
                                ),
                                foregroundColor: speciesColor,
                              ),
                        const SizedBox(height: 20),
                        Text(
                          _pet.name,
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        NeuChip(
                          label: PetUtils.formatSpecies(_pet.species),
                          icon: PetUtils.getSpeciesIcon(_pet.species),
                          selected: true,
                          selectedColor: speciesColor,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuContainer(
                variant: NeuVariant.pressed,
                borderRadius: NeuTokens.radiusSm,
                padding: const EdgeInsets.all(NeuTokens.spaceXs),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: NeuTokens.spaceXs),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: NeuTokens.spaceMd),
          child,
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    NeuBottomSheet.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MenuTile(
              icon: Icons.edit_outlined,
              title: 'Edit Pet',
              color: ThemeColors.primary(context),
              onTap: () {
                context.pop();
                _navigateToEdit(context);
              },
            ),
            _MenuTile(
              icon: Icons.monitor_weight_outlined,
              title: 'Add Weight Entry',
              color: ThemeColors.primary(context),
              onTap: () {
                context.pop();
                _showAddWeightDialog(context);
              },
            ),
            if (_pet.isActive)
              _MenuTile(
                icon: Icons.archive_outlined,
                title: 'Deactivate',
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.warningOnDark
                    : AppColors.warning,
                onTap: () {
                  context.pop();
                  _showDeactivateDialog(context);
                },
              )
            else
              _MenuTile(
                icon: Icons.unarchive_outlined,
                title: 'Activate',
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.successOnDark
                    : AppColors.success,
                onTap: () {
                  context.pop();
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
    NeuDialog.show(
      context: context,
      title: 'Add Weight Entry',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current weight: ${_pet.weightKg?.toStringAsFixed(1) ?? 'Not set'} kg',
            style: AppTextStyles.bodyMedium.copyWith(
              color: ThemeColors.textSecondary(context),
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
            onSubmitted: (_) => _saveWeight(context, weightController),
          ),
        ],
      ),
      actions: [
        NeuButton(
          text: 'Cancel',
          variant: NeuButtonVariant.ghost,
          onPressed: () => context.pop(),
        ),
        NeuButton(
          text: 'Save',
          variant: NeuButtonVariant.primary,
          icon: Icons.save,
          onPressed: () => _saveWeight(context, weightController),
        ),
      ],
    );
  }

  void _saveWeight(BuildContext context, TextEditingController controller) {
    final weight = double.tryParse(controller.text);
    if (weight != null && weight > 0) {
      context.pop();
      final updatedPet = _pet.copyWith(
        weightKg: weight,
        updatedAt: DateTime.now(),
      );
      _updatePet(updatedPet);
      context.read<PetBloc>().add(
        UpdatePetWeight(petId: _pet.id!, weightKg: weight),
      );
    }
  }

  void _showDeactivateDialog(BuildContext context) {
    NeuConfirmDialog.show(
      context: context,
      title: 'Deactivate ${_pet.name}?',
      message:
          'This will archive ${_pet.name}. The pet will no longer appear in active lists but can be restored later.',
      confirmText: 'Deactivate',
      cancelText: 'Cancel',
      confirmVariant: NeuButtonVariant.destructive,
      onConfirm: () {
        final updatedPet = _pet.copyWith(isActive: false);
        _updatePet(updatedPet);
        context.read<PetBloc>().add(UpdatePet(pet: updatedPet));
      },
    );
  }

  void _showActivateDialog(BuildContext context) {
    NeuConfirmDialog.show(
      context: context,
      title: 'Activate ${_pet.name}?',
      message: 'This will restore ${_pet.name} to active status.',
      confirmText: 'Activate',
      cancelText: 'Cancel',
      confirmVariant: NeuButtonVariant.primary,
      onConfirm: () {
        final updatedPet = _pet.copyWith(isActive: true);
        _updatePet(updatedPet);
        context.read<PetBloc>().add(UpdatePet(pet: updatedPet));
      },
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
    return NeuContainer(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 14,
      variant: NeuVariant.flat,
      child: Row(
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(8),
            borderRadius: 10,
            variant: NeuVariant.flat,
            child: Icon(icon, color: color, size: 20),
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
          Icon(
            Icons.chevron_right_rounded,
            color: ThemeColors.textTertiary(context),
            size: 20,
          ),
        ],
      ),
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
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        NeuChip(
          label: PetUtils.formatSpecies(pet.species),
          icon: PetUtils.getSpeciesIcon(pet.species),
          selected: true,
          selectedColor: PetUtils.getSpeciesColor(pet.species),
        ),
        if (pet.breed != null)
          NeuChip(
            label: pet.breed!,
            icon: Icons.pets,
            selected: true,
            selectedColor: ThemeColors.primary(context),
          ),
        if (pet.birthDate != null)
          NeuChip(
            label: 'Age: ${PetUtils.calculateAge(pet.birthDate!)}',
            icon: Icons.cake_outlined,
            selected: true,
            selectedColor: AppColors.tertiary,
          ),
        if (pet.weightKg != null)
          NeuChip(
            label: '${pet.weightKg!.toStringAsFixed(1)} kg',
            icon: Icons.monitor_weight_outlined,
            selected: true,
            selectedColor: ThemeColors.primary(context),
          ),
        if (pet.microchipId != null)
          NeuChip(
            label: 'Microchipped',
            icon: Icons.nfc_outlined,
            selected: true,
            selectedColor: ThemeColors.success(context),
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
          valueStyle: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
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
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Breed',
            value: pet.breed!,
          ),
        if (pet.color != null)
          _InfoRow(
            icon: Icons.palette_outlined,
            label: 'Color',
            value: pet.color!,
          ),
        if (pet.birthDate != null)
          _InfoRow(
            icon: Icons.cake_outlined,
            label: 'Birth Date',
            value:
                '${pet.birthDate!.day}/${pet.birthDate!.month}/${pet.birthDate!.year}',
          ),
        if (pet.microchipId != null)
          _InfoRow(
            icon: Icons.nfc_outlined,
            label: 'Microchip ID',
            value: pet.microchipId!,
          ),
        _InfoRow(
          icon: Icons.flag_outlined,
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
          label: 'Created',
          value:
              '${pet.createdAt.day}/${pet.createdAt.month}/${pet.createdAt.year}',
        ),
        _InfoRow(
          icon: Icons.update_outlined,
          label: 'Last Updated',
          value:
              '${pet.updatedAt.day}/${pet.updatedAt.month}/${pet.updatedAt.year}',
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
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(10),
            borderRadius: 10,
            variant: NeuVariant.flat,
            child: Icon(
              icon,
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
class _WeightTrackingCard extends StatelessWidget {
  final Pet pet;
  final void Function(BuildContext) onAddWeight;
  const _WeightTrackingCard({required this.pet, required this.onAddWeight});

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
                    color: ThemeColors.textTertiary(
                      context,
                    ).withValues(alpha: 0.5),
                  ),
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
        NeuDivider(thickness: 1, indent: 56),
        _ActionTile(
          icon: Icons.medical_services_outlined,
          title: 'View Medical Records',
          subtitle: 'Vaccinations, treatments, notes',
          color: AppColors.tertiary,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medical records coming soon')),
          ),
        ),
        NeuDivider(thickness: 1, indent: 56),
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
    return NeuContainer(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 14,
      variant: NeuVariant.flat,
      child: Row(
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(8),
            borderRadius: 10,
            variant: NeuVariant.flat,
            child: Icon(icon, color: color, size: 22),
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
          Icon(
            Icons.chevron_right_rounded,
            color: ThemeColors.textTertiary(context),
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Medical records card
class _MedicalRecordsCard extends StatelessWidget {
  final Pet pet;
  const _MedicalRecordsCard({required this.pet});

  @override
  Widget build(BuildContext context) {
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
                borderRadius: 24,
                variant: NeuVariant.flat,
                child: Icon(
                  Icons.folder_outlined,
                  size: 56,
                  color: ThemeColors.textTertiary(
                    context,
                  ).withValues(alpha: 0.6),
                ),
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
      create: (context) =>
          PetBloc(petRepository: context.read<PetRepository>())
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
      create: (context) =>
          PetBloc(petRepository: context.read<PetRepository>())
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
        if (state is PetLoading)
          return const Scaffold(body: NeuSkeletonDetail(blocks: 4));
        if (state is PetDetailLoaded) return PetDetailPage(pet: state.pet);
        if (state is PetError)
          return _buildError(context, state.failure.message);
        return const Scaffold(body: NeuSkeletonDetail(blocks: 4));
      },
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
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
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: ThemeColors.error(context),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error Loading Pet',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                NeuButton(
                  text: 'Retry',
                  onPressed: () =>
                      context.read<PetBloc>().add(LoadPetsById(petId)),
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
        if (state is PetLoading)
          return const Scaffold(body: NeuSkeletonDetail(blocks: 4));
        if (state is PetDetailLoaded) {
          final authState = context.read<AuthBloc>().state;
          final ownerId = authState is AuthAuthenticated
              ? authState.user.id!
              : 0;
          return PetFormPage(ownerId: ownerId, pet: state.pet);
        }
        if (state is PetError)
          return _buildError(context, state.failure.message);
        return const Scaffold(body: NeuSkeletonDetail(blocks: 4));
      },
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
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
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: ThemeColors.error(context),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error Loading Pet',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                NeuButton(
                  text: 'Retry',
                  onPressed: () =>
                      context.read<PetBloc>().add(LoadPetsById(petId)),
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
