import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/features/pets/presentation/widgets/pet_form_widgets.dart';
import 'package:carepaw/core/utils/input_formatters.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';

import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';

/// Page for adding or editing a pet with the CarePaw surface system.
class PetFormPage extends StatefulWidget {
  final int ownerId;
  final Pet? pet; // null for create, non-null for edit

  const PetFormPage({super.key, required this.ownerId, this.pet});

  @override
  State<PetFormPage> createState() => _PetFormPageState();
}

class _PetFormPageState extends State<PetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _markingsController = TextEditingController();
  final _microchipController = TextEditingController();
  final _weightController = TextEditingController();

  PetSpecies _selectedSpecies = PetSpecies.dog;
  PetSex? _selectedSex;
  DateTime? _selectedBirthDate;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _populateForm(widget.pet!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _markingsController.dispose();
    _microchipController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _populateForm(Pet pet) {
    _nameController.text = pet.name;
    _selectedSpecies = pet.species;
    _selectedSex = pet.sex;
    _breedController.text = pet.breed ?? '';
    _colorController.text = pet.color ?? '';
    _markingsController.text = pet.markings ?? '';
    _microchipController.text = pet.microchipId ?? '';
    _weightController.text = pet.weightKg?.toStringAsFixed(1) ?? '';
    _selectedBirthDate = pet.birthDate;
    _isActive = pet.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.pet != null;
    final speciesColor = PetUtils.getSpeciesColor(_selectedSpecies);

    return BlocListener<PetBloc, PetState>(
      listener: (context, state) {
        if (state is PetError) {
          NeuToast.error(context, state.failure.message);
        } else if (state is PetOperationSuccess) {
          NeuToast.success(context, state.message);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: ThemeColors.background(context),
        appBar: AppBar(
          backgroundColor: ThemeColors.surface(context),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: NeuIconButton(
            plain: true,
            icon: Icons.arrow_back_rounded,
            svgAsset: SvgIcons.back,
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            isEditing ? 'Edit pet' : 'Add pet',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header with avatar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    children: [
                      NeuAvatar(
                        radius: 50,
                        customIcon: PetUtils.getSpeciesCustomIcon(_selectedSpecies),
                        svgAsset: PetUtils.getSpeciesSvg(_selectedSpecies),
                        backgroundColor: PetUtils.getSpeciesColor(
                          _selectedSpecies,
                        ).withValues(alpha: 0.14),
                        foregroundColor: PetUtils.getSpeciesColor(
                          _selectedSpecies,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isEditing
                            ? 'Update ${widget.pet!.name}'
                            : 'Add a new pet',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: ThemeColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Form fields grouped into sections
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: _getFormSections().length,
                  separatorBuilder: (_, _) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final section = _getFormSections()[index];
                    return _buildSection(context, section, speciesColor);
                  },
                ),
              ),

              // Submit button
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 48),
                sliver: SliverToBoxAdapter(
                  child: BlocBuilder<PetBloc, PetState>(
                    builder: (context, state) {
                      final isLoading = state is PetLoading;
                      return NeuButton(
                        text: isEditing ? 'Save Changes' : 'Add Pet',
                        variant: NeuButtonVariant.primary,
                        icon: isEditing
                            ? Icons.save_outlined
                            : Icons.add_rounded,
                        svgAsset: isEditing ? SvgIcons.save : SvgIcons.add,
                        onPressed: isLoading ? null : _onSubmit,
                        expanded: true,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    _FormSection section,
    Color speciesColor,
  ) {
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
                child: section.svgAsset != null
                    ? NeuSvgIcon(section.svgAsset!, size: 20)
                    : Icon(section.icon, size: 20, color: speciesColor),
              ),
              const SizedBox(width: NeuTokens.spaceXs),
              Text(
                section.title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...section.buildFields(context),
        ],
      ),
    );
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final pet = Pet(
        id: widget.pet?.id,
        ownerId: widget.ownerId,
        name: _nameController.text.trim(),
        species: _selectedSpecies,
        sex: _selectedSex,
        breed: _breedController.text.trim().isEmpty
            ? null
            : _breedController.text.trim(),
        birthDate: _selectedBirthDate,
        weightKg: _weightController.text.isEmpty
            ? null
            : double.tryParse(_weightController.text),
        color: _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim(),
        markings: _markingsController.text.trim().isEmpty
            ? null
            : _markingsController.text.trim(),
        microchipId: _microchipController.text.trim().isEmpty
            ? null
            : _microchipController.text.trim(),
        avatarUrl: widget.pet?.avatarUrl,
        isActive: _isActive,
        createdAt: widget.pet?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.pet != null) {
        context.read<PetBloc>().add(UpdatePet(pet: pet));
      } else {
        context.read<PetBloc>().add(CreatePet(pet: pet));
      }
    }
  }

  /// Get all form sections - 2 sections: Basic Info + Health/ID
  List<_FormSection> _getFormSections() {
    return [
      _FormSection(
        title: 'Basic Information',
        icon: Icons.info_outline_rounded,
        svgAsset: SvgIcons.info,
        buildFields: (context) => [
          // Name field (required)
          NeuTextField(
            controller: _nameController,
            label: 'Pet Name *',
            hint: 'e.g., Buddy',
            prefixIcon: ClayIconOrMaterial(
              'pets_outlined',
              fallback: Icons.pets_outlined,
              size: 20,
            ),
            validator: Validators.requiredWith([
              (value) => Validators.maxLength(value, 50, 'Name'),
            ], 'Name'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          // Species selector (affects breed options)
          PetSpeciesSelector(
            selectedSpecies: _selectedSpecies,
            onChanged: (value) => setState(() => _selectedSpecies = value),
          ),
          const SizedBox(height: 16),
          // Sex selector (thesis paper lists sex as a required field)
          PetSexSelector(
            selectedSex: _selectedSex,
            onChanged: (value) => setState(() => _selectedSex = value),
          ),
          const SizedBox(height: 16),
          // Breed selector with common breeds (depends on species)
          PetBreedSelector(
            label: 'Breed',
            selectedSpecies: _selectedSpecies,
            controller: _breedController,
          ),
          const SizedBox(height: 16),
          // Color
          NeuTextField(
            controller: _colorController,
            label: 'Color',
            hint: 'e.g., Golden',
            prefixIcon: ClayIconOrMaterial(
              'palette_outlined',
              fallback: Icons.palette_outlined,
              size: 20,
            ),
            validator: (value) => Validators.maxLength(value, 30, 'Color'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          // Markings
          NeuTextField(
            controller: _markingsController,
            label: 'Markings',
            hint: 'e.g. white patch on left ear',
            maxLines: 2,
            prefixIcon: ClayIconOrMaterial(
              'brush_outlined',
              fallback: Icons.brush_outlined,
              size: 20,
            ),
            validator: (value) => Validators.maxLength(value, 100, 'Markings'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          // Birth date
          PetBirthDateField(
            label: 'Birth Date',
            hint: 'Optional',
            initialDate: _selectedBirthDate,
            onDateSelected: (date) => setState(() => _selectedBirthDate = date),
          ),
        ],
      ),
      _FormSection(
        title: 'Health & ID (Optional)',
        icon: Icons.medical_services_outlined,
        svgAsset: SvgIcons.visit,
        buildFields: (context) => [
          // Weight
          NeuTextField(
            controller: _weightController,
            label: 'Weight (kg)',
            hint: 'Optional - e.g., 25.5',
            prefixIcon: ClayIconOrMaterial(
              'monitor_weight_outlined',
              fallback: Icons.monitor_weight_outlined,
              size: 20,
            ),
            validator: Validators.weight,
            textInputAction: TextInputAction.next,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [DecimalInputFormatter.weightKg],
          ),
          const SizedBox(height: 16),
          // Microchip
          NeuTextField(
            controller: _microchipController,
            label: 'Microchip ID',
            hint: 'Optional - e.g., 985112000123456',
            prefixIcon: ClayIconOrMaterial(
              'nfc_outlined',
              fallback: Icons.nfc_outlined,
              size: 20,
            ),
            validator: (value) =>
                Validators.maxLength(value, 20, 'Microchip ID'),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          // Active status (only for editing)
          if (widget.pet != null)
            PetActiveSwitch(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
        ],
      ),
    ];
  }
}

/// Form section data
class _FormSection {
  final String title;
  final IconData icon;
  final String? svgAsset;
  final List<Widget> Function(BuildContext) buildFields;

  const _FormSection({
    required this.title,
    required this.icon,
    this.svgAsset,
    required this.buildFields,
  });
}

