import 'package:flutter/material.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_switch.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';

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

/// Species selector with filter chips
class PetSpeciesSelector extends StatelessWidget {
  final PetSpecies selectedSpecies;
  final ValueChanged<PetSpecies> onChanged;

  const PetSpeciesSelector({
    super.key,
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
              svgAsset: PetUtils.getSpeciesSvg(species),
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

/// Sex selector with filter chips
class PetSexSelector extends StatelessWidget {
  final PetSex? selectedSex;
  final ValueChanged<PetSex?> onChanged;

  const PetSexSelector({super.key, required this.selectedSex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sex',
          style: AppTextStyles.labelLarge.copyWith(
            color: ThemeColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: PetSex.values.map((sex) {
            final isSelected = sex == selectedSex;
            return NeuChip(
              label: sex.displayName,
              icon: sex == PetSex.male
                  ? Icons.male_outlined
                  : Icons.female_outlined,
              svgAsset: sex == PetSex.male ? SvgIcons.male : SvgIcons.female,
              selected: isSelected,
              selectedColor: ThemeColors.primary(context),
              onTap: () => onChanged(isSelected ? null : sex),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Birth date picker field with the CarePaw surface system
class PetBirthDateField extends StatefulWidget {
  final String label;
  final String? hint;
  final DateTime? initialDate;
  final ValueChanged<DateTime?> onDateSelected;

  const PetBirthDateField({
    super.key,
    required this.label,
    this.hint,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<PetBirthDateField> createState() => _PetBirthDateFieldState();
}

class _PetBirthDateFieldState extends State<PetBirthDateField> {
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
          borderRadius: NeuTokens.radiusSm,
          onTap: _pickDate,
          child: Row(
            children: [
              const NeuSvgIcon(SvgIcons.calendar, size: 22),
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
                  svgAsset: SvgIcons.close,
                  size: 18,
                  tooltip: 'Clear date',
                  onPressed: () {
                    setState(() => _selectedDate = null);
                    widget.onDateSelected(null);
                  },
                )
              else
                const NeuSvgIcon(SvgIcons.chevronDown, size: 24),
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
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: ThemeColors.primary(context)),
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
class PetBreedSelector extends StatefulWidget {
  final String label;
  final PetSpecies selectedSpecies;
  final TextEditingController controller;

  const PetBreedSelector({
    super.key,
    required this.label,
    required this.selectedSpecies,
    required this.controller,
  });

  @override
  State<PetBreedSelector> createState() => _PetBreedSelectorState();
}

class _PetBreedSelectorState extends State<PetBreedSelector> {
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
  void didUpdateWidget(covariant PetBreedSelector oldWidget) {
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
          borderRadius: NeuTokens.radiusSm,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedBreed,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Select breed',
              prefixIcon: ClayIconOrMaterial(
                'category_outlined',
                fallback: Icons.category_outlined,
                size: 20,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            hint: Text(
              'Select breed',
              style: AppTextStyles.bodyLarge.copyWith(
                color: ThemeColors.textTertiary(context),
              ),
            ),
            items: [
              ...breeds.map(
                (breed) => DropdownMenuItem(
                  value: breed,
                  child: Text(breed, style: AppTextStyles.bodyLarge),
                ),
              ),
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
                    return Validators.maxLength(
                      _customController.text,
                      50,
                      'Breed',
                    );
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
            prefixIcon: ClayIconOrMaterial(
              'edit_outlined',
              fallback: Icons.edit_outlined,
              size: 20,
            ),
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

/// Active status switch with the CarePaw surface system
class PetActiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const PetActiveSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(16),
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(10),
            borderRadius: NeuTokens.radiusSm,
            variant: NeuVariant.flat,
            child: value
                ? const NeuSvgIcon(SvgIcons.success, size: 22)
                : const NeuSvgIcon(SvgIcons.archive, size: 22),
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
                  value
                      ? 'Pet is active and visible'
                      : 'Pet is inactive (archived)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          NeuSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}