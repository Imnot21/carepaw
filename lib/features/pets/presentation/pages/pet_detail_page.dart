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
import 'package:carepaw/core/utils/input_formatters.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_state.dart';
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: NeuTokens.maxContentWidth,
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header with avatar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    NeuTokens.pagePadding,
                    8,
                    NeuTokens.pagePadding,
                    16,
                  ),
                  child: Column(
                    children: [
                      NeuCard(
                        padding: const EdgeInsets.all(28),
                        shape: RoundedRectangleBorder(
                          borderRadius: NeuShape.card,
                        ),
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
                                    svgAsset: PetUtils.getSpeciesSvg(
                                      _pet.species,
                                    ),
                                    backgroundColor: speciesColor.withValues(
                                      alpha: 0.14,
                                    ),
                                    foregroundColor: speciesColor,
                                  ),
                            const SizedBox(height: 20),
                            Text(
                              _pet.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                padding: const EdgeInsets.fromLTRB(
                  NeuTokens.pagePadding,
                  0,
                  NeuTokens.pagePadding,
                  40,
                ),
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
        ),
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
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
    final weightError = ValueNotifier<String?>(null);
    final currentWeight = _pet.weightKg == null
        ? 'Current weight: not set'
        : 'Current weight: ${_pet.weightKg!.toStringAsFixed(1)} kg';

    // Validates, then closes the dialog and saves. Stays open with a message
    // when the weight is not valid.
    void submit() {
      final text = weightController.text.trim();
      final error = text.isEmpty
          ? 'Enter the weight in kg'
          : Validators.weight(text);
      if (error != null) {
        weightError.value = error;
        return;
      }
      context.pop();
      _saveWeight(double.parse(text));
    }

    NeuDialog.show(
      context: context,
      title: 'Add Weight Entry',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentWeight,
            style: AppTextStyles.bodyMedium.copyWith(
              color: ThemeColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: NeuTokens.spaceMd),
          ValueListenableBuilder<String?>(
            valueListenable: weightError,
            builder: (context, error, _) => NeuTextField(
              controller: weightController,
              label: 'New Weight (kg)',
              hint: 'e.g., 26.5',
              error: error,
              prefixIcon: ClayIconOrMaterial(
                'monitor_weight_outlined',
                fallback: Icons.monitor_weight_outlined,
                size: 20,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [DecimalInputFormatter.weightKg],
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (weightError.value != null) weightError.value = null;
              },
              onSubmitted: (_) => submit(),
            ),
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
          onPressed: submit,
        ),
      ],
    );
  }

  void _saveWeight(double weight) {
    final petId = _pet.id;
    if (petId == null) return;
    // Optimistic: the page shows the new weight at once; the loader reloads
    // the saved pet, or restores the old one and reports if the save fails.
    _updatePet(_pet.copyWith(weightKg: weight, updatedAt: DateTime.now()));
    context.read<PetBloc>().add(
      UpdatePetWeight(petId: petId, weightKg: weight),
    );
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

/// Shared error screen for the pet loaders.
class _PetLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _PetLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: NeuIconButton(
          plain: true,
          icon: Icons.arrow_back_rounded,
          svgAsset: SvgIcons.back,
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: NeuErrorState(
        title: 'Could not load pet',
        message: message,
        onRetry: onRetry,
      ),
    );
  }
}

/// Loads pet by ID and shows PetDetailPage.
///
/// Once the pet has loaded the page stays on screen while a weight or status
/// update runs; the bloc's "loading" and "success" states do not replace it.
class _PetDetailLoader extends StatefulWidget {
  final int petId;
  const _PetDetailLoader({required this.petId});

  @override
  State<_PetDetailLoader> createState() => _PetDetailLoaderState();
}

class _PetDetailLoaderState extends State<_PetDetailLoader> {
  Pet? _pet;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PetBloc, PetState>(
      listener: (context, state) {
        final bloc = context.read<PetBloc>();
        if (state is PetDetailLoaded) {
          setState(() => _pet = state.pet);
        } else if (state is PetOperationSuccess) {
          NeuToast.success(context, state.message);
        } else if (state is PetsLoaded) {
          // An update finished: fetch the saved pet so the page shows it.
          bloc.add(LoadPetsById(widget.petId));
        } else if (state is PetError && _pet != null) {
          NeuToast.error(context, state.failure.message);
          // Drop the optimistic change by reloading the saved pet.
          bloc.add(LoadPetsById(widget.petId));
        }
      },
      builder: (context, state) {
        final pet = _pet;
        if (pet != null) {
          return PetDetailPage(key: ObjectKey(pet), pet: pet);
        }
        if (state is PetError) {
          return _PetLoadError(
            message: state.failure.message,
            onRetry: () =>
                context.read<PetBloc>().add(LoadPetsById(widget.petId)),
          );
        }
        return const Scaffold(body: NeuSkeletonDetail(blocks: 4));
      },
    );
  }
}

/// Loads pet by ID and shows PetFormPage for editing.
///
/// The form stays on screen while the save runs so its listener can show the
/// result and close the page.
class _PetFormLoader extends StatefulWidget {
  final int petId;
  const _PetFormLoader({required this.petId});

  @override
  State<_PetFormLoader> createState() => _PetFormLoaderState();
}

class _PetFormLoaderState extends State<_PetFormLoader> {
  Pet? _pet;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PetBloc, PetState>(
      listenWhen: (previous, current) => _pet == null,
      listener: (context, state) {
        if (state is PetDetailLoaded) setState(() => _pet = state.pet);
      },
      builder: (context, state) {
        final pet = _pet;
        if (pet != null) {
          // Keep the pet's real owner: a clinic account must not take over
          // ownership by saving an edit.
          return PetFormPage(ownerId: pet.ownerId, pet: pet);
        }
        if (state is PetError) {
          return _PetLoadError(
            message: state.failure.message,
            onRetry: () =>
                context.read<PetBloc>().add(LoadPetsById(widget.petId)),
          );
        }
        return const Scaffold(body: NeuSkeletonDetail(blocks: 4));
      },
    );
  }
}
