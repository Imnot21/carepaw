import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/theme_colors.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shapes.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';

class PetSelectionSection extends StatelessWidget {
  final int? selectedPetId;
  final ValueChanged<int?> onPetSelected;
  final ValueChanged<int?> onAutoSelect;

  const PetSelectionSection({
    super.key,
    required this.selectedPetId,
    required this.onPetSelected,
    required this.onAutoSelect,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetBloc, PetState>(
      builder: (context, state) {
        List<Pet> pets = [];
        var effectiveSelectedId = selectedPetId;
        if (state is PetsLoaded) {
          pets = state.pets;
        } else if (state is PetLoading) {
          return _SectionCard(
            title: 'Select Pet',
            icon: Icons.pets_rounded,
            svgAsset: SvgIcons.paw,
            iconColor: ThemeColors.primaryText(context),
            child: const Center(child: NeuCircularProgress(size: 24)),
          );
        }

        if (effectiveSelectedId != null && pets.isNotEmpty) {
          final hasPet = pets.any((p) => p.id == effectiveSelectedId);
          if (!hasPet) {
            effectiveSelectedId = pets.isNotEmpty ? pets.first.id : null;
            onAutoSelect(effectiveSelectedId);
          }
        } else if (pets.isNotEmpty && effectiveSelectedId == null) {
          effectiveSelectedId = pets.first.id;
          onAutoSelect(effectiveSelectedId);
        }

        return _SectionCard(
          title: 'Select Pet',
          subtitle: 'Choose which pet is visiting',
          icon: Icons.pets_rounded,
          svgAsset: SvgIcons.paw,
          iconColor: ThemeColors.primaryText(context),
          isRequired: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: pets.map((pet) {
                  final isSelected = effectiveSelectedId == pet.id;
                  final speciesColor = PetUtils.getSpeciesColor(pet.species);
                  return NeuChip(
                    label: pet.name,
                    svgAsset: PetUtils.getSpeciesSvg(pet.species),
                    selected: isSelected,
                    selectedColor: speciesColor,
                    onTap: () => onPetSelected(pet.id),
                    unselectedVariant: NeuVariant.raised,
                  );
                }).toList(),
              ),
              if (effectiveSelectedId == null && pets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Please select a pet',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ThemeColors.error(context),
                    ),
                  ),
                ),
              if (pets.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'No pets found. Please add a pet first.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ThemeColors.error(context),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class VeterinarianSelectionSection extends StatelessWidget {
  final bool isVetOrStaff;
  final Future<List<User>> veterinariansFuture;
  final int? selectedVeterinarianId;
  final ValueChanged<int?> onVetSelected;
  final ValueChanged<int?> onAutoSelect;

  const VeterinarianSelectionSection({
    super.key,
    required this.isVetOrStaff,
    required this.veterinariansFuture,
    required this.selectedVeterinarianId,
    required this.onVetSelected,
    required this.onAutoSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVetOrStaff) {
      return FutureBuilder<List<User>>(
        future: veterinariansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _SectionCard(
              title: 'Your Veterinarian',
              subtitle: 'Assigned veterinarian for this clinic',
              icon: Icons.medical_services_rounded,
            svgAsset: SvgIcons.visit,
              iconColor: ThemeColors.textSecondary(context),
              child: const Center(child: NeuCircularProgress(size: 24)),
            );
          }

          // Repo failure used to leave the spinner up forever — the submit
          // path already blocks with a snackbar, but the owner deserves to
          // see the failure here too.
          if (snapshot.hasError) {
            return _SectionCard(
              title: 'Your Veterinarian',
              subtitle: 'Assigned veterinarian for this clinic',
              icon: Icons.medical_services_rounded,
            svgAsset: SvgIcons.visit,
              iconColor: ThemeColors.textSecondary(context),
              child: NeuContainer(
                variant: NeuVariant.inset,
                borderRadius: 12,
                padding: const EdgeInsets.all(16),
                borderColor: ThemeColors.error(context).withValues(alpha: 0.35),
                borderWidth: 1,
                child: Row(
                  children: [
                    NeuSvgIcon(
                      SvgIcons.error,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Failed to load veterinarian: ${snapshot.error}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: ThemeColors.error(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final veterinarians = snapshot.data ?? [];
          final assignedVet = veterinarians.isNotEmpty
              ? veterinarians.first
              : null;

          return _SectionCard(
            title: 'Your Veterinarian',
            subtitle: 'Assigned veterinarian for this clinic',
            icon: Icons.medical_services_rounded,
            svgAsset: SvgIcons.visit,
            iconColor: ThemeColors.textSecondary(context),
            child: NeuContainer(
              variant: NeuVariant.inset,
              borderRadius: 12,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  NeuAvatar(
                    radius: 24,
                    initials: assignedVet?.fullName.isNotEmpty == true
                        ? assignedVet!.fullName[0].toUpperCase()
                        : 'D',
                    backgroundColor: ThemeColors.primary(
                      context,
                    ).withValues(alpha: 0.15),
                    foregroundColor: ThemeColors.primaryText(context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignedVet != null
                              ? 'Dr. ${assignedVet.fullName}'
                              : 'Veterinarian not assigned',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: assignedVet != null
                                ? ThemeColors.textPrimary(context)
                                : ThemeColors.error(context),
                          ),
                        ),
                        if (assignedVet != null)
                          Text(
                            'Your clinic veterinarian',
                            style: AppTextStyles.bodySmall.subtleOf(
                              Theme.of(context).brightness,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return FutureBuilder<List<User>>(
      future: veterinariansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _SectionCard(
            title: 'Select Veterinarian',
            subtitle: 'Choose your preferred veterinarian',
            icon: Icons.medical_services_rounded,
            svgAsset: SvgIcons.visit,
            iconColor: ThemeColors.textSecondary(context),
            child: const Center(child: NeuCircularProgress(size: 24)),
          );
        }

        if (snapshot.hasError) {
          return _SectionCard(
            title: 'Select Veterinarian',
            subtitle: 'Choose your preferred veterinarian',
            icon: Icons.medical_services_rounded,
            svgAsset: SvgIcons.visit,
            iconColor: ThemeColors.textSecondary(context),
            child: NeuContainer(
              variant: NeuVariant.inset,
              borderRadius: 12,
              padding: const EdgeInsets.all(16),
              borderColor: ThemeColors.error(context).withValues(alpha: 0.35),
              borderWidth: 1,
              child: Row(
                children: [
                  NeuSvgIcon(
                    SvgIcons.error,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to load veterinarians: ${snapshot.error}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: ThemeColors.error(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final veterinarians = snapshot.data ?? [];
        var effectiveSelectedVetId = selectedVeterinarianId;

        if (effectiveSelectedVetId != null && veterinarians.isNotEmpty) {
          final hasVet = veterinarians.any(
            (v) => v.id == effectiveSelectedVetId,
          );
          if (!hasVet) {
            effectiveSelectedVetId = veterinarians.isNotEmpty
                ? veterinarians.first.id
                : null;
            onAutoSelect(effectiveSelectedVetId);
          }
        } else if (veterinarians.isNotEmpty &&
            effectiveSelectedVetId == null) {
          effectiveSelectedVetId = veterinarians.first.id;
          onAutoSelect(effectiveSelectedVetId);
        }

        return _SectionCard(
          title: 'Select Veterinarian',
          subtitle: 'Choose your preferred veterinarian',
          icon: Icons.medical_services_rounded,
          svgAsset: SvgIcons.visit,
          iconColor: ThemeColors.textSecondary(context),
          isRequired: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: veterinarians.map((vet) {
                  final isSelected = effectiveSelectedVetId == vet.id;
                  return NeuChip(
                    label: 'Dr. ${vet.fullName}',
                    icon: Icons.medical_services_rounded,
            svgAsset: SvgIcons.visit,
                    selected: isSelected,
                    selectedColor: ThemeColors.primary(context),
                    onTap: () =>
                        onVetSelected(vet.id),
                    unselectedVariant: NeuVariant.raised,
                  );
                }).toList(),
              ),
              if (effectiveSelectedVetId == null && veterinarians.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Please select a veterinarian',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ThemeColors.error(context),
                    ),
                  ),
                ),
              if (veterinarians.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'No veterinarians available',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ThemeColors.error(context),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class DateTimeSelectionSection extends StatelessWidget {
  final String? dateTimeText;
  final VoidCallback onTap;

  const DateTimeSelectionSection({
    super.key,
    required this.dateTimeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = dateTimeText != null;

    return _SectionCard(
      title: 'Date & Time',
      subtitle: 'When would you like the appointment?',
      icon: Icons.calendar_today_rounded,
      svgAsset: SvgIcons.calendar,
      iconColor: ThemeColors.info(context),
      isRequired: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeuContainer(
            onTap: onTap,
            variant: NeuVariant.inset,
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            borderColor: !hasDate ? ThemeColors.error(context) : null,
            borderWidth: !hasDate ? 1 : 0,
            child: Row(
              children: [
                NeuContainer(
                  padding: const EdgeInsets.all(8),
                  borderRadius: 10,
                  variant: NeuVariant.flat,
                  color:
                      (hasDate
                              ? ThemeColors.info(context)
                              : ThemeColors.textSecondary(context))
                          .withValues(alpha: 0.15),
                  child: NeuSvgIcon(SvgIcons.calendar, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasDate
                        ? dateTimeText!
                        : 'Select date and time',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: hasDate
                          ? ThemeColors.textPrimary(context)
                          : ThemeColors.textSecondary(context),
                    ),
                  ),
                ),
                NeuSvgIcon(SvgIcons.chevronDown, size: 24),
              ],
            ),
          ),
          if (!hasDate)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                'Please select a date and time',
                style: AppTextStyles.bodySmall.copyWith(
                  color: ThemeColors.error(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DurationSelectionSection extends StatelessWidget {
  final int durationMinutes;
  final ValueChanged<int> onDurationChanged;

  const DurationSelectionSection({
    super.key,
    required this.durationMinutes,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Duration',
      subtitle: 'How long will the appointment take?',
      icon: Icons.timer_outlined,
      svgAsset: SvgIcons.schedule,
      iconColor: ThemeColors.warning(context),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [15, 30, 45, 60].map((minutes) {
          final isSelected = durationMinutes == minutes;
          return NeuChip(
            label: '$minutes min',
            selected: isSelected,
            selectedColor: ThemeColors.primary(context),
            onTap: () => onDurationChanged(minutes),
          );
        }).toList(),
      ),
    );
  }
}

class ServiceSelectionSection extends StatelessWidget {
  final String? selectedService;
  final ValueChanged<String?> onServiceChanged;

  const ServiceSelectionSection({
    super.key,
    required this.selectedService,
    required this.onServiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Service',
      subtitle: 'Which clinic service is this visit for?',
      icon: Icons.medical_services_rounded,
      svgAsset: SvgIcons.visit,
      iconColor: ThemeColors.primaryText(context),
      isRequired: true,
      child: DropdownButtonFormField<String>(
        initialValue: selectedService,
        isExpanded: true,
        decoration: const InputDecoration(border: InputBorder.none),
        hint: const Text('Select a service'),
        items: [
          for (final service in clinicServices)
            DropdownMenuItem(value: service, child: Text(service)),
        ],
        onChanged: (value) => onServiceChanged(value),
        validator: (value) =>
            value == null || value.isEmpty ? 'Please select a service' : null,
      ),
    );
  }
}

class ReasonSection extends StatelessWidget {
  final TextEditingController reasonController;

  const ReasonSection({
    super.key,
    required this.reasonController,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Reason for Visit',
      subtitle: 'What is the purpose of this appointment?',
      icon: Icons.description_rounded,
      svgAsset: SvgIcons.note,
      iconColor: ThemeColors.success(context),
      isRequired: true,
      child: NeuTextField(
        controller: reasonController,
        label: 'Reason for Visit',
        hint: 'e.g., Annual checkup, Vaccination, Illness',
        validator: (value) => Validators.required(value, 'Reason'),
        maxLines: 3,
        minLines: 2,
        prefixIcon: ClayIconOrMaterial(
          'description_outlined',
          fallback: Icons.description_outlined,
          size: 20,
          color: ThemeColors.textSecondary(context),
        ),
      ),
    );
  }
}

class NotesSection extends StatelessWidget {
  final TextEditingController notesController;

  const NotesSection({
    super.key,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Additional Notes',
      subtitle: 'Any other information for the veterinarian',
      icon: Icons.note_alt_rounded,
      svgAsset: SvgIcons.prescription,
      iconColor: ThemeColors.textSecondary(context),
      child: NeuTextField(
        controller: notesController,
        label: 'Additional Notes',
        hint: 'Any additional information for the veterinarian...',
        maxLines: 4,
        minLines: 3,
        prefixIcon: ClayIconOrMaterial(
          'note_outlined',
          fallback: Icons.note_outlined,
          size: 20,
          color: ThemeColors.textSecondary(context),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? svgAsset;
  final Color iconColor;
  final bool isRequired;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.icon,
    this.svgAsset,
    required this.iconColor,
    this.isRequired = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: NeuShape.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(10),
                borderRadius: 12,
                variant: NeuVariant.flat,
                color: iconColor.withValues(alpha: 0.15),
                child: svgAsset != null
                    ? NeuSvgIcon(svgAsset!, size: 22)
                    : Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: ThemeColors.textPrimary(context),
                          ),
                        ),
                        if (isRequired) ...[
                          const SizedBox(width: 4),
                          Text(
                            '*',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ThemeColors.error(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: ThemeColors.textSecondary(context),
                        ),
                      ),
                  ],
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
}

/// Date/time picker sheet using the CarePaw surface system
class DateTimePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateTimeSelected;

  const DateTimePickerSheet({
    super.key,
    required this.initialDate,
    required this.onDateTimeSelected,
  });

  @override
  State<DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<DateTimePickerSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = TimeOfDay.fromDateTime(widget.initialDate);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Select Date & Time',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        // Date picker
        NeuContainer(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          variant: NeuVariant.raised,
          child: CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateChanged: (date) => setState(() => _selectedDate = date),
          ),
        ),
        const SizedBox(height: 16),
        // Time picker
        NeuContainer(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          variant: NeuVariant.raised,
          child: SizedBox(
            height: 200,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: DateTime(
                2024,
                1,
                1,
                _selectedTime.hour,
                _selectedTime.minute,
              ),
              use24hFormat: false,
              onDateTimeChanged: (dateTime) => setState(
                () => _selectedTime = TimeOfDay.fromDateTime(dateTime),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: NeuButton(
                text: 'Cancel',
                variant: NeuButtonVariant.ghost,
                onPressed: () => context.pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NeuButton(
                text: 'Confirm',
                variant: NeuButtonVariant.primary,
                onPressed: () {
                  final dateTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  );
                  widget.onDateTimeSelected(dateTime);
                  context.pop();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
