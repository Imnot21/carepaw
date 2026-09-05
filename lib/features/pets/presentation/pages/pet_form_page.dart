import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_text_field.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/core/widgets/effects/floating_animation.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';
import 'package:carepaw/core/widgets/effects/scale_on_tap.dart';

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

/// Page for adding or editing a pet with premium design.
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

class _PetFormPageState extends State<PetFormPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _microchipController = TextEditingController();
  final _weightController = TextEditingController();

  PetSpecies _selectedSpecies = PetSpecies.dog;
  DateTime? _selectedBirthDate;
  bool _isActive = true;
  final int _currentStep = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _populateForm(widget.pet!);
    }
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _microchipController.dispose();
    _weightController.dispose();
    _animationController.dispose();
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
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else if (state is PetOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Pet' : 'Add Pet'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: PremiumShadows.level(context, 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: AnimatedGradientBackground(
          colors: [
            speciesColor.withValues(alpha: 0.08),
            Theme.of(context).colorScheme.surface,
          ],
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Header with avatar and progress
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Column(
                            children: [
                              if (!isEditing) ...[
                                _ProgressIndicator(currentStep: _currentStep, totalSteps: 3),
                                const SizedBox(height: 24),
                              ],
                              // Species-themed avatar with PulsingGlow
                              PulsingGlow(
                                glowColor: speciesColor,
                                maxRadius: 30,
                                duration: const Duration(seconds: 3),
                                child: PetUtils.buildAvatar(
                                  species: _selectedSpecies,
                                  radius: 60,
                                  iconSize: 60,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isEditing ? 'Update ${widget.pet!.name}' : 'Add a new pet',
                                style: AppTextStyles.bodyLarge.subtle,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Form fields grouped into steps/sections
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList.separated(
                          itemCount: _getFormSections().length,
                          separatorBuilder: (_, _) => const SizedBox(height: 20),
                          itemBuilder: (context, index) {
                            final section = _getFormSections()[index];
                            return FloatingAnimation(
                              delay: Duration(milliseconds: 100 * (index + 1)),
                              child: _buildSection(context, section, speciesColor),
                            );
                          },
                        ),
                      ),

                      // Submit button
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                        sliver: SliverToBoxAdapter(
                          child: BlocBuilder<PetBloc, PetState>(
                            builder: (context, state) {
                              final isLoading = state is PetLoading;
                              return ScaleOnTap(
                                onTap: isLoading ? null : _onSubmit,
                                child: CpButton(
                                  text: isEditing ? 'Save Changes' : 'Add Pet',
                                  onPressed: isLoading ? null : _onSubmit,
                                  isLoading: isLoading,
                                  expanded: true,
                                  size: ButtonSize.large,
                                  icon: isEditing ? Icons.save_outlined : Icons.add_rounded,
                                  variant: ButtonVariant.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      blur: 20,
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.glassBorderDark
          : AppColors.glassBorderLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: speciesColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(section.icon, size: 22, color: speciesColor),
              ),
              const SizedBox(width: 12),
              Text(
                section.title,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
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
          _PetFormField(
            label: 'Pet Name *',
            hint: 'e.g., Buddy',
            controller: _nameController,
            validator: Validators.requiredWith(
              [(value) => Validators.maxLength(value, 50, 'Name')],
              'Name',
            ),
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.pets_outlined,
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
          _PetFormField(
            label: 'Color',
            hint: 'e.g., Golden',
            controller: _colorController,
            validator: (value) => Validators.maxLength(value, 30, 'Color'),
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.palette_outlined,
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
          _PetFormField(
            label: 'Weight (kg)',
            hint: 'Optional - e.g., 25.5',
            controller: _weightController,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                return Validators.positiveNumber(value);
              }
              return null;
            },
            textInputAction: TextInputAction.next,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.monitor_weight_outlined,
          ),
          const SizedBox(height: 16),
          // Microchip
          _PetFormField(
            label: 'Microchip ID',
            hint: 'Optional - e.g., 985112000123456',
            controller: _microchipController,
            validator: (value) => Validators.maxLength(value, 20, 'Microchip ID'),
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.nfc_outlined,
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

/// Progress indicator for add pet flow
class _ProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _ProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index <= currentStep;
        final isLast = index == totalSteps - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (!isLast)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

/// Form field wrapper with consistent styling
class _PetFormField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  const _PetFormField({
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.textInputAction,
    this.keyboardType,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return CpTextField(
      controller: controller,
      label: label,
      hint: hint,
      validator: validator,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
          : null,
    );
  }
}

/// Species selector with icons
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
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        // Horizontal species chips for easier selection
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PetSpecies.values.map((species) {
            final isSelected = species == selectedSpecies;
            final color = PetUtils.getSpeciesColor(species);
            return ScaleOnTap(
              onTap: () => onChanged(species),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: FilterChip(
                  selected: isSelected,
                  onSelected: (_) => onChanged(species),
                  avatar: Icon(
                    PetUtils.getSpeciesIcon(species),
                    size: 20,
                    color: isSelected ? Colors.white : color,
                  ),
                  label: Text(
                    PetUtils.formatSpecies(species),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  selectedColor: color,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? color : Theme.of(context).colorScheme.outlineVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Birth date picker field
class _PetBirthDateField extends StatefulWidget {
  final String label;
  final String? hint;
  final DateTime? initialDate;
  final ValueChanged<DateTime> onDateSelected;

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
          widget.label + (widget.hint != null ? ' (${widget.hint})' : ''),
          style: AppTextStyles.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ScaleOnTap(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasDate
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: hasDate ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayText,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: hasDate
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (hasDate)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20, color: AppColors.textSecondary),
                    onPressed: () {
                      setState(() => _selectedDate = null);
                      widget.onDateSelected(DateTime.now());
                    },
                    tooltip: 'Clear date',
                  )
                else
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              ],
            ),
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
              primary: AppColors.primary,
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
          widget.label + (_isCustomBreed ? '' : ' *'),
          style: AppTextStyles.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedBreed,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Select breed',
            prefixIcon: Icon(
              Icons.category_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          hint: Text('Select breed', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint)),
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
        if (showCustomField) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customController,
            decoration: InputDecoration(
              labelText: 'Custom Breed',
              hintText: 'Enter breed name',
              prefixIcon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: AppTextStyles.bodyLarge,
            onChanged: (value) {
              widget.controller.text = value;
            },
            textInputAction: TextInputAction.next,
          ),
        ],
      ],
    );
  }
}

/// Active status switch
class _PetActiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PetActiveSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: value ? AppColors.success.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                value ? Icons.check_circle_outline_rounded : Icons.archive_outlined,
                size: 22,
                color: value ? AppColors.success : AppColors.warning,
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
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ? 'Pet is active and visible' : 'Pet is inactive (archived)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.success,
              activeTrackColor: AppColors.success.withValues(alpha: 0.3),
              inactiveThumbColor: AppColors.warning,
              inactiveTrackColor: AppColors.warning.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}