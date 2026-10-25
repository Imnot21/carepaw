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
import 'package:carepaw/features/pets/presentation/widgets/pet_detail_widgets.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/core/utils/input_formatters.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shapes.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
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
          plain: true,
          icon: Icons.arrow_back_rounded,
          svgAsset: SvgIcons.back,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          NeuIconButton(
            plain: true,
            icon: Icons.more_vert_rounded,
            svgAsset: SvgIcons.more,
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
                                svgAsset: PetUtils.getSpeciesSvg(_pet.species),
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
                          svgAsset: PetUtils.getSpeciesSvg(_pet.species),
                          selected: true,
                          selectedColor: speciesColor,
                        ),
                      ],
                    ),
                  ),

                  // Quick info chips
                  const SizedBox(height: 16),
                  QuickInfoChips(pet: _pet),
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
                  svgAsset: SvgIcons.info,
                  iconColor: speciesColor,
                  child: BasicInfoCard(pet: _pet),
                ),
                const SizedBox(height: 20),

                // Weight tracking section
                _buildSection(
                  context,
                  title: 'Weight Tracking',
                  icon: Icons.monitor_weight_outlined,
                  svgAsset: SvgIcons.weightScale,
                  iconColor: ThemeColors.primary(context),
                  child: WeightTrackingCard(
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
                  svgAsset: SvgIcons.bolt,
                  iconColor: ThemeColors.textSecondary(context),
                  child: QuickActionsCard(pet: _pet),
                ),
                const SizedBox(height: 20),

                // Medical records
                _buildSection(
                  context,
                  title: 'Medical Records',
                  icon: Icons.medical_services_outlined,
                  svgAsset: SvgIcons.visit,
                  iconColor: ThemeColors.progress(context),
                  child: MedicalRecordsCard(pet: _pet),
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
    String? svgAsset,
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
                child: svgAsset != null
                    ? NeuSvgIcon(svgAsset, size: 20)
                    : Icon(icon, size: 20, color: iconColor),
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
            MenuTile(
              icon: Icons.edit_outlined,
              svgAsset: SvgIcons.edit,
              title: 'Edit Pet',
              color: ThemeColors.primary(context),
              onTap: () {
                context.pop();
                _navigateToEdit(context);
              },
            ),
            MenuTile(
              icon: Icons.monitor_weight_outlined,
              svgAsset: SvgIcons.weightScale,
              title: 'Add Weight Entry',
              color: ThemeColors.primary(context),
              onTap: () {
                context.pop();
                _showAddWeightDialog(context);
              },
            ),
            if (_pet.isActive)
              MenuTile(
                icon: Icons.archive_outlined,
                svgAsset: SvgIcons.archive,
                title: 'Deactivate',
                color: ThemeColors.warning(context),
                onTap: () {
                  context.pop();
                  _showDeactivateDialog(context);
                },
              )
            else
              MenuTile(
                icon: Icons.unarchive_outlined,
                svgAsset: SvgIcons.unarchive,
                title: 'Activate',
                color: ThemeColors.success(context),
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
            prefixIcon: ClayIconOrMaterial(
              'monitor_weight_outlined',
              fallback: Icons.monitor_weight_outlined,
              size: 20,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [DecimalInputFormatter.weightKg],
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
          svgAsset: SvgIcons.save,
          onPressed: () => _saveWeight(context, weightController),
        ),
      ],
    );
  }

  void _saveWeight(BuildContext context, TextEditingController controller) {
    final weight = double.tryParse(controller.text);
    if (weight != null && Validators.weight(controller.text) == null) {
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
        if (state is PetLoading) {
          return const Scaffold(body: NeuSkeletonDetail(blocks: 4));
        }
        if (state is PetDetailLoaded) return PetDetailPage(pet: state.pet);
        if (state is PetError) {
          return _buildError(context, state.failure.message);
        }
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
          plain: true,
          icon: Icons.arrow_back_rounded,
          svgAsset: SvgIcons.back,
          tooltip: 'Back',
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
                  borderRadius: NeuTokens.radiusMd,
                  variant: NeuVariant.flat,
                  child: const NeuSvgIcon(SvgIcons.error, size: 64),
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
                  svgAsset: SvgIcons.refresh,
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
        if (state is PetLoading) {
          return const Scaffold(body: NeuSkeletonDetail(blocks: 4));
        }
        if (state is PetDetailLoaded) {
          final authState = context.read<AuthBloc>().state;
          final ownerId = authState is AuthAuthenticated
              ? authState.user.id!
              : 0;
          return PetFormPage(ownerId: ownerId, pet: state.pet);
        }
        if (state is PetError) {
          return _buildError(context, state.failure.message);
        }
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
          plain: true,
          icon: Icons.arrow_back_rounded,
          svgAsset: SvgIcons.back,
          tooltip: 'Back',
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
                  borderRadius: NeuTokens.radiusMd,
                  variant: NeuVariant.flat,
                  child: const NeuSvgIcon(SvgIcons.error, size: 64),
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
                  svgAsset: SvgIcons.refresh,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
