import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shapes.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_switch.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';

// Common dog breeds by species
const Map<PetSpecies, List<String>> _commonBreedsBySpecies = {
  PetSpecies.dog: [
    'Mixed Breed',
    'Labrador Retriever',
    'Golden Retriever',
    'German Shepherd',
    'Bulldog',
    'Poodle',
    'Beagle',
    'Rottweiler',
    'Yorkshire Terrier',
    'Dachshund',
    'Siberian Husky',
    'Boxer',
    'Shih Tzu',
    'Pomeranian',
    'Chihuahua',
    'Border Collie',
    'Australian Shepherd',
    'Cocker Spaniel',
    'Bichon Frise',
    'Maltese',
    'Other (specify)',
  ],
  PetSpecies.cat: [
    'Mixed Breed',
    'Domestic Shorthair',
    'Domestic Longhair',
    'Persian',
    'Maine Coon',
    'Siamese',
    'Ragdoll',
    'Bengal',
    'British Shorthair',
    'Sphynx',
    'Scottish Fold',
    'Abyssinian',
    'Russian Blue',
    'Other (specify)',
  ],
  PetSpecies.bird: [
    'Budgerigar (Budgie)',
    'Cockatiel',
    'African Grey',
    'Cockatoo',
    'Macaw',
    'Lovebird',
    'Conure',
    'Canary',
    'Finch',
    'Other (specify)',
  ],
  PetSpecies.rabbit: [
    'Mixed Breed',
    'Holland Lop',
    'Netherland Dwarf',
    'Mini Rex',
    'Lionhead',
    'Flemish Giant',
    'English Angora',
    'Other (specify)',
  ],
  PetSpecies.reptile: [
    'Bearded Dragon',
    'Leopard Gecko',
    'Ball Python',
    'Corn Snake',
    'Red-eared Slider',
    'Crested Gecko',
    'Blue-tongued Skink',
    'Other (specify)',
  ],
  PetSpecies.other: [
    'Hamster',
    'Guinea Pig',
    'Ferret',
    'Hedgehog',
    'Chinchilla',
    'Sugar Glider',
    'Other (specify)',
  ],
};

/// Page for adding or editing a pet with neumorphic design.
class PetFormPage extends StatefulWidget {
  final int ownerId;
  final Pet? pet; // null for create, non-null for edit

  const PetFormPage({
    super.key,
    required this.ownerId,
    this.pet,
  });

  @override
  State<PetFormPage> createState() => _PetFormPageState();
}

class _PetFormPageState extends State<PetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _microchipController = TextEditingController();
  final _weightController = TextEditingController();

  PetSpecies _selectedSpecies = PetSpecies.dog;
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
    _microchipController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _populateForm(Pet pet) {
    _nameController.text = pet.name;
    _selectedSpecies = pet.species;
    _breedController.text = pet.breed ?? '';
    _colorController.text = pet.color ?? '';
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure.message),
              backgroundColor: ThemeColors.error(context),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else if (state is PetOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: ThemeColors.success(context),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: ThemeColors.background(context),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: NeuIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            isEditing ? 'Edit Pet' : 'Add Pet',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: ThemeColors.textPrimary(context),
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
                        icon: PetUtils.getSpeciesIcon(_selectedSpecies),
                        backgroundColor: PetUtils.getSpeciesColor(_selectedSpecies).withValues(alpha: 0.2),
                        foregroundColor: PetUtils.getSpeciesColor(_selectedSpecies),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isEditing ? 'Update ${widget.pet!.name}' : 'Add a new pet',
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
                        icon: isEditing ? Icons.save_outlined : Icons.add_rounded,
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
      padding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: NeuShape.cardFlow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(10),
                borderRadius: 12,
                variant: NeuVariant.flat,
                child: Icon(section.icon, size: 22, color: speciesColor),
              ),
              const SizedBox(width: 12),
              Text(
                section.title,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.textPrimary(context),
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
        breed: _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
        birthDate: _selectedBirthDate,
        weightKg: _weightController.text.isEmpty
            ? null
            : double.tryParse(_weightController.text),
        color: _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim(),
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
        buildFields: (context) => [
          // Name field (required)
          NeuTextField(
            controller: _nameController,
            label: 'Pet Name *',
            hint: 'e.g., Buddy',
            prefixIcon: const Icon(Icons.pets_outlined),
            validator: Validators.requiredWith(
              [(value) => Validators.maxLength(value, 50, 'Name')],
              'Name',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          // Species selector (affects breed options)
          _PetSpeciesSelector(
            selectedSpecies: _selectedSpecies,
            onChanged: (value) => setState(() => _selectedSpecies = value),
          ),
          const SizedBox(height: 16),
          // Breed selector with common breeds (depends on species)
          _PetBreedSelector(
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
            prefixIcon: const Icon(Icons.palette_outlined),
            validator: (value) => Validators.maxLength(value, 30, 'Color'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          // Birth date
          _PetBirthDateField(
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
        buildFields: (context) => [
          // Weight
          NeuTextField(
            controller: _weightController,
            label: 'Weight (kg)',
            hint: 'Optional - e.g., 25.5',
            prefixIcon: const Icon(Icons.monitor_weight_outlined),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                return Validators.positiveNumber(value);
              }
              return null;
            },
            textInputAction: TextInputAction.next,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          // Microchip
          NeuTextField(
            controller: _microchipController,
            label: 'Microchip ID',
            hint: 'Optional - e.g., 985112000123456',
            prefixIcon: const Icon(Icons.nfc_outlined),
            validator: (value) => Validators.maxLength(value, 20, 'Microchip ID'),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          // Active status (only for editing)
          if (widget.pet != null)
            _PetActiveSwitch(
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
  final List<Widget> Function(BuildContext) buildFields;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.buildFields,
  });
}

/// Species selector with neumorphic chips
class _PetSpeciesSelector extends StatelessWidget {
  final PetSpecies selectedSpecies;
  final ValueChanged<PetSpecies> onChanged;

  const _PetSpeciesSelector({
    required this.selectedSpecies,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Species *',
          style: AppTextStyles.labelLarge.copyWith(
            color: ThemeColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: PetSpecies.values.map((species) {
            final isSelected = species == selectedSpecies;
            final color = PetUtils.getSpeciesColor(species);
            return NeuChip(
              label: PetUtils.formatSpecies(species),
              icon: PetUtils.getSpeciesIcon(species),
              selected: isSelected,
              selectedColor: color,
              onTap: () => onChanged(species),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Birth date picker field with neumorphic design
class _PetBirthDateField extends StatefulWidget {
  final String label;
  final String? hint;
  final DateTime? initialDate;
  final ValueChanged<DateTime?> onDateSelected;

  const _PetBirthDateField({
    required this.label,
    this.hint,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<_PetBirthDateField> createState() => _PetBirthDateFieldState();
}

class _PetBirthDateFieldState extends State<_PetBirthDateField> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = _selectedDate != null;
    final displayText = hasDate
        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
        : 'Select birth date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.label}${widget.hint != null ? ' (${widget.hint})' : ''}',
          style: AppTextStyles.labelLarge.copyWith(
            color: ThemeColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        NeuContainer(
          variant: NeuVariant.flat,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          borderRadius: 16,
          onTap: _pickDate,
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: hasDate ? ThemeColors.primary(context) : ThemeColors.textSecondary(context),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayText,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: hasDate
                        ? ThemeColors.textPrimary(context)
                        : ThemeColors.textTertiary(context),
                  ),
                ),
              ),
              if (hasDate)
                NeuIconButton(
                  icon: Icons.clear,
                  size: 18,
                  onPressed: () {
                    setState(() => _selectedDate = null);
                    widget.onDateSelected(null);
                  },
                )
              else
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: ThemeColors.textTertiary(context),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.subtract(const Duration(days: 365)),
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: ThemeColors.primary(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      setState(() => _selectedDate = date);
      widget.onDateSelected(date);
    }
  }
}

/// Breed selector with common breeds dropdown + custom entry
class _PetBreedSelector extends StatefulWidget {
  final String label;
  final PetSpecies selectedSpecies;
  final TextEditingController controller;

  const _PetBreedSelector({
    required this.label,
    required this.selectedSpecies,
    required this.controller,
  });

  @override
  State<_PetBreedSelector> createState() => _PetBreedSelectorState();
}

class _PetBreedSelectorState extends State<_PetBreedSelector> {
  String? _selectedBreed;
  bool _isCustomBreed = false;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.controller.text.isNotEmpty) {
      final breeds = _commonBreedsBySpecies[widget.selectedSpecies] ?? [];
      if (breeds.contains(widget.controller.text)) {
        _selectedBreed = widget.controller.text;
      } else {
        _isCustomBreed = true;
        _customController.text = widget.controller.text;
      }
    }
  }

  @override
  void didUpdateWidget(covariant _PetBreedSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSpecies != widget.selectedSpecies) {
      _selectedBreed = null;
      _isCustomBreed = false;
      _customController.clear();
      widget.controller.clear();
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breeds = _commonBreedsBySpecies[widget.selectedSpecies] ?? [];
    final otherOption = 'Other (specify)';
    final showCustomField = _isCustomBreed || _selectedBreed == otherOption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.label}${_isCustomBreed ? '' : ' *'}',
          style: AppTextStyles.labelLarge.copyWith(
            color: ThemeColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        NeuContainer(
          variant: NeuVariant.inset,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedBreed,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Select breed',
              prefixIcon: Icon(
                Icons.category_outlined,
                color: ThemeColors.textSecondary(context),
                size: 20,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            hint: Text(
              'Select breed',
              style: AppTextStyles.bodyLarge.copyWith(
                color: ThemeColors.textTertiary(context),
              ),
            ),
            items: [
              ...breeds.map((breed) => DropdownMenuItem(
                value: breed,
                child: Text(breed, style: AppTextStyles.bodyLarge),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedBreed = value;
                _isCustomBreed = value == otherOption;
                if (!_isCustomBreed && value != null) {
                  widget.controller.text = value;
                } else if (_isCustomBreed) {
                  widget.controller.text = _customController.text;
                }
              });
            },
            validator: (_isCustomBreed || _selectedBreed == otherOption)
                ? (value) {
                    if (_customController.text.trim().isEmpty) {
                      return 'Please enter breed';
                    }
                    return Validators.maxLength(_customController.text, 50, 'Breed');
                  }
                : (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a breed';
                    }
                    return null;
                  },
          ),
        ),
        if (showCustomField) ...[
          const SizedBox(height: 16),
          NeuTextField(
            controller: _customController,
            label: 'Custom Breed',
            hint: 'Enter breed name',
            prefixIcon: const Icon(Icons.edit_outlined),
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              widget.controller.text = value;
            },
          ),
        ],
      ],
    );
  }
}

/// Active status switch with neumorphic design
class _PetActiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PetActiveSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(16),
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(10),
            borderRadius: 12,
            variant: NeuVariant.flat,
            child: Icon(
              value ? Icons.check_circle_outline_rounded : Icons.archive_outlined,
              size: 22,
              color: value ? ThemeColors.success(context) : ThemeColors.warning(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Status',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ? 'Pet is active and visible' : 'Pet is inactive (archived)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          NeuSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
