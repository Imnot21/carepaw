import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_text_field.dart';
import 'package:carepaw/core/widgets/common/cp_loader.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/core/widgets/effects/floating_animation.dart';
import 'package:carepaw/core/widgets/effects/scale_on_tap.dart';

/// Appointment form page for creating or editing appointments
class AppointmentFormPage extends StatefulWidget {
  final int? appointmentId;
  final int? petId;
  final int? veterinarianId;
  final UserRole? userRole; // Role of the current user to determine UI

  const AppointmentFormPage({
    super.key,
    this.appointmentId,
    this.petId,
    this.veterinarianId,
    this.userRole,
  });

  @override
  State<AppointmentFormPage> createState() => _AppointmentFormPageState();
}

class _AppointmentFormPageState extends State<AppointmentFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDateTime;
  int _durationMinutes = 30;
  int? _selectedPetId;
  int? _selectedVeterinarianId;
  bool _isLoading = false;
  late Future<List<User>> _veterinariansFuture;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Determine if current user is vet/staff (can see advanced fields)
  bool get _isVetOrStaff => widget.userRole == UserRole.veterinarian || widget.userRole == UserRole.staff || widget.userRole == UserRole.admin;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.petId;
    _selectedVeterinarianId = widget.veterinarianId;

    // Load pets and veterinarians
    _loadPetsAndVets();

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

  void _loadPetsAndVets() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final ownerId = authState.user.id!;
      context.read<PetBloc>().add(LoadPets(ownerId: ownerId));
      // Only load veterinarians if user is vet/staff/admin
      if (_isVetOrStaff) {
        _veterinariansFuture = getIt<UserRepository>().findVeterinarians();
      } else {
        // For pet owners in single vet clinic - auto-assign the single vet
        _loadSingleVeterinarian();
      }
    }
  }

  Future<void> _loadSingleVeterinarian() async {
    try {
      final veterinarians = await getIt<UserRepository>().findVeterinarians();
      if (veterinarians.isNotEmpty) {
        // Single vet clinic - auto-assign the first/only veterinarian
        setState(() {
          _selectedVeterinarianId = veterinarians.first.id;
        });
      }
    } catch (_) {
      // Ignore - will show error in UI if no vet found
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.appointmentId != null;

    return MultiBlocListener(
      listeners: [
        BlocListener<AppointmentBloc, AppointmentState>(
          listener: (context, state) {
            if (state is AppointmentCreated || state is AppointmentUpdated) {
              _isLoading = false;
              if (mounted) {
                context.go(Routes.appointments);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing ? 'Appointment updated' : 'Appointment requested'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            } else if (state is AppointmentError) {
              _isLoading = false;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            } else if (state is AppointmentLoading) {
              _isLoading = true;
            }
          },
        ),
      ],
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Appointment' : 'Request Appointment'),
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
              onPressed: () => context.pop(),
            ),
          ),
          actions: [
            if (isEditing)
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: ScaleOnTap(
                  onTap: _showDeleteConfirmation,
                  child: CpIconButton(
                    icon: Icons.delete_outline_rounded,
                    size: 24,
                    color: AppColors.error,
                    tooltip: 'Delete',
                  ),
                ),
              ),
          ],
        ),
        body: AnimatedGradientBackground(
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
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
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                        sliver: SliverList.separated(
                          itemCount: _isVetOrStaff ? 6 : 4, // Pet, [Vet], Date, [Duration], Reason, Notes
                          separatorBuilder: (_, _) => const SizedBox(height: 20),
                          itemBuilder: (context, index) {
                            return FloatingAnimation(
                              delay: Duration(milliseconds: 80 * index),
                              child: _buildFormSection(context, index, isEditing),
                            );
                          },
                        ),
                      ),
                      // Submit button at bottom
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              ScaleOnTap(
                                onTap: _isLoading ? null : _submitForm,
                                child: CpButton(
                                  text: isEditing ? 'Update Appointment' : 'Request Appointment',
                                  onPressed: _isLoading ? null : _submitForm,
                                  isLoading: _isLoading,
                                  expanded: true,
                                  size: ButtonSize.large,
                                  icon: Icons.event_available_rounded,
                                  variant: ButtonVariant.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ScaleOnTap(
                                onTap: _isLoading ? null : () => context.pop(),
                                child: CpButton(
                                  text: 'Cancel',
                                  onPressed: _isLoading ? null : () => context.pop(),
                                  expanded: true,
                                  size: ButtonSize.medium,
                                  variant: ButtonVariant.ghost,
                                ),
                              ),
                            ],
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

  Widget _buildFormSection(BuildContext context, int index, bool isEditing) {
    // Define section indices based on user role
    // Pet owners: Pet, Date/Time, Reason, Notes (no vet selection, no duration)
    // Vet/Staff/Admin: Pet, Vet, Date/Time, Duration, Reason, Notes
    if (_isVetOrStaff) {
      switch (index) {
        case 0:
          return _buildPetSelectionSection(context);
        case 1:
          return _buildVeterinarianSelectionSection(context);
        case 2:
          return _buildDateTimeSection(context);
        case 3:
          return _buildDurationSection(context);
        case 4:
          return _buildReasonSection(context);
        case 5:
          return _buildNotesSection(context);
        default:
          return const SizedBox.shrink();
      }
    } else {
      // Pet owner - simplified form
      switch (index) {
        case 0:
          return _buildPetSelectionSection(context);
        case 1:
          return _buildDateTimeSection(context);
        case 2:
          return _buildReasonSection(context);
        case 3:
          return _buildNotesSection(context);
        default:
          return const SizedBox.shrink();
      }
    }
  }

  Widget _buildPetSelectionSection(BuildContext context) {
    return BlocBuilder<PetBloc, PetState>(
      builder: (context, state) {
        List<Pet> pets = [];
        if (state is PetsLoaded) {
          pets = state.pets;
        } else if (state is PetLoading) {
          return _buildSectionCard(
            context,
            title: 'Select Pet',
            icon: Icons.pets_rounded,
            iconColor: AppColors.primary,
            child: const Center(child: CpLoader(size: 24)),
          );
        }

        // If petId was pre-selected but we don't have it in our list, set it
        if (_selectedPetId != null && pets.isNotEmpty) {
          final hasPet = pets.any((p) => p.id == _selectedPetId);
          if (!hasPet) {
            _selectedPetId = pets.isNotEmpty ? pets.first.id : null;
          }
        } else if (pets.isNotEmpty && _selectedPetId == null) {
          _selectedPetId = pets.first.id;
        }

        return _buildSectionCard(
          context,
          title: 'Select Pet',
          subtitle: 'Choose which pet is visiting',
          icon: Icons.pets_rounded,
          iconColor: AppColors.primary,
          required: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedPetId == null && pets.isNotEmpty
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedPetId,
                    hint: Text('Select a pet', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint)),
                    items: pets.map((pet) {
                      return DropdownMenuItem<int>(
                        value: pet.id,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: PetUtils.getSpeciesColor(pet.species).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                PetUtils.getSpeciesIcon(pet.species),
                                size: 18,
                                color: PetUtils.getSpeciesColor(pet.species),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(pet.name, style: AppTextStyles.bodyLarge),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedPetId = value),
                  ),
                ),
              ),
              if (_selectedPetId == null && pets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Please select a pet',
                    style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              if (pets.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'No pets found. Please add a pet first.',
                    style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVeterinarianSelectionSection(BuildContext context) {
    // Only show for vet/staff/admin users
    if (!_isVetOrStaff) {
      // For pet owners - show assigned veterinarian info (single vet clinic)
      return FutureBuilder<List<User>>(
        future: _veterinariansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSectionCard(
              context,
              title: 'Your Veterinarian',
              subtitle: 'Assigned veterinarian for this clinic',
              icon: Icons.medical_services_rounded,
              iconColor: AppColors.secondary,
              child: const Center(child: CpLoader(size: 24)),
            );
          }

          final veterinarians = snapshot.data ?? [];

          // Single vet clinic - show the assigned vet
          final assignedVet = veterinarians.isNotEmpty ? veterinarians.first : null;

          return _buildSectionCard(
            context,
            title: 'Your Veterinarian',
            subtitle: 'Assigned veterinarian for this clinic',
            icon: Icons.medical_services_rounded,
            iconColor: AppColors.secondary,
            child: GlassContainer(
              borderRadius: 12,
              padding: const EdgeInsets.all(16),
              blur: 15,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    child: Text(
                      assignedVet?.fullName.isNotEmpty == true ? assignedVet!.fullName[0].toUpperCase() : 'D',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignedVet != null ? 'Dr. ${assignedVet.fullName}' : 'Veterinarian not assigned',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: assignedVet != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.error,
                          ),
                        ),
                        if (assignedVet != null)
                          Text(
                            'Your clinic veterinarian',
                            style: AppTextStyles.bodySmall.subtle,
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

    // Vet/Staff/Admin - full veterinarian selection
    return FutureBuilder<List<User>>(
      future: _veterinariansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSectionCard(
            context,
            title: 'Select Veterinarian',
            subtitle: 'Choose your preferred veterinarian',
            icon: Icons.medical_services_rounded,
            iconColor: AppColors.secondary,
            child: const Center(child: CpLoader(size: 24)),
          );
        }

        if (snapshot.hasError) {
          return _buildSectionCard(
            context,
            title: 'Select Veterinarian',
            subtitle: 'Choose your preferred veterinarian',
            icon: Icons.medical_services_rounded,
            iconColor: AppColors.secondary,
            child: GlassContainer(
              borderRadius: 12,
              padding: const EdgeInsets.all(16),
              blur: 15,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
                  Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to load veterinarians: ${snapshot.error}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final veterinarians = snapshot.data ?? [];

        // If veterinarianId was pre-selected but we don't have it in our list, set it
        if (_selectedVeterinarianId != null && veterinarians.isNotEmpty) {
          final hasVet = veterinarians.any((v) => v.id == _selectedVeterinarianId);
          if (!hasVet) {
            _selectedVeterinarianId = veterinarians.isNotEmpty ? veterinarians.first.id : null;
          }
        } else if (veterinarians.isNotEmpty && _selectedVeterinarianId == null) {
          _selectedVeterinarianId = veterinarians.first.id;
        }

        return _buildSectionCard(
          context,
          title: 'Select Veterinarian',
          subtitle: 'Choose your preferred veterinarian',
          icon: Icons.medical_services_rounded,
          iconColor: AppColors.secondary,
          required: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedVeterinarianId == null && veterinarians.isNotEmpty
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedVeterinarianId,
                    hint: Text('Select a veterinarian', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint)),
                    items: veterinarians.map((vet) {
                      return DropdownMenuItem<int>(
                        value: vet.id,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                              child: Text(
                                vet.fullName.isNotEmpty ? vet.fullName[0] : 'D',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('Dr. ${vet.fullName}', style: AppTextStyles.bodyLarge),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedVeterinarianId = value),
                  ),
                ),
              ),
              if (_selectedVeterinarianId == null && veterinarians.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Please select a veterinarian',
                    style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              if (veterinarians.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'No veterinarians available',
                    style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateTimeSection(BuildContext context) {
    final hasDate = _selectedDateTime != null;

    return _buildSectionCard(
      context,
      title: 'Date & Time',
      subtitle: 'When would you like the appointment?',
      icon: Icons.calendar_today_rounded,
      iconColor: AppColors.info,
      required: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScaleOnTap(
            onTap: _pickDateTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !hasDate ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (hasDate ? AppColors.info : AppColors.textSecondary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: hasDate ? AppColors.info : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasDate
                          ? '${_formatDate(_selectedDateTime!)} at ${_formatTime(_selectedDateTime!)}'
                          : 'Select date and time',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: hasDate
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: hasDate ? AppColors.info : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (!hasDate)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                'Please select a date and time',
                style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDurationSection(BuildContext context) {
    return _buildSectionCard(
      context,
      title: 'Duration',
      subtitle: 'How long will the appointment take?',
      icon: Icons.timer_outlined,
      iconColor: AppColors.warning,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [15, 30, 45, 60].map((minutes) {
          final isSelected = _durationMinutes == minutes;
          return ScaleOnTap(
            onTap: () => setState(() => _durationMinutes = minutes),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: FilterChip(
                label: Text('$minutes min', style: AppTextStyles.labelLarge),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _durationMinutes = minutes);
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReasonSection(BuildContext context) {
    return _buildSectionCard(
      context,
      title: 'Reason for Visit',
      subtitle: 'What is the purpose of this appointment?',
      icon: Icons.description_rounded,
      iconColor: AppColors.success,
      required: true,
      child: CpTextField(
        controller: _reasonController,
        label: 'Reason for Visit',
        hint: 'e.g., Annual checkup, Vaccination, Illness',
        validator: (value) => Validators.required(value, 'Reason'),
        maxLines: 3,
        minLines: 2,
        prefixIcon: const Icon(Icons.description_outlined, color: AppColors.textSecondary, size: 20),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return _buildSectionCard(
      context,
      title: 'Additional Notes',
      subtitle: 'Any other information for the veterinarian',
      icon: Icons.note_alt_rounded,
      iconColor: AppColors.textSecondary,
      child: CpTextField(
        controller: _notesController,
        label: 'Additional Notes',
        hint: 'Any additional information for the veterinarian...',
        maxLines: 4,
        minLines: 3,
        prefixIcon: const Icon(Icons.note_outlined, color: AppColors.textSecondary, size: 20),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    bool required = false,
    required Widget child,
  }) {
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
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
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
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (required) ...[
                          const SizedBox(width: 4),
                          Text(
                            '*',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now().add(const Duration(hours: 1))),
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

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a pet'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // For pet owners in single vet clinic - use auto-assigned veterinarian
    // For vet/staff - require selection
    if (_selectedVeterinarianId == null) {
      if (!_isVetOrStaff) {
        // Try to get the single vet again
        _loadSingleVeterinarian();
        // Give it a moment
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_selectedVeterinarianId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('No veterinarian available for this clinic'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        });
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a veterinarian'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a date and time'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Check if appointment is in the past
    if (_selectedDateTime!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot schedule appointment in the past'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    _formKey.currentState!.save();

    // Default duration for pet owners (30 minutes)
    final duration = _isVetOrStaff ? _durationMinutes : 30;

    final appointment = Appointment(
      id: widget.appointmentId,
      petId: _selectedPetId!,
      veterinarianId: _selectedVeterinarianId!,
      scheduledAt: _selectedDateTime!,
      durationMinutes: duration,
      status: AppointmentStatus.requested,
      reason: _reasonController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.appointmentId != null) {
      context.read<AppointmentBloc>().add(AppointmentUpdateRequested(appointment));
    } else {
      context.read<AppointmentBloc>().add(AppointmentCreateRequested(appointment));
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Text('Delete Appointment', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text('Are you sure you want to delete this appointment? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ScaleOnTap(
            onTap: () {
              Navigator.pop(context);
              context.read<AppointmentBloc>().add(AppointmentDeleteRequested(widget.appointmentId!));
            },
            child: CpButton(
              text: 'Delete',
              onPressed: () {
                Navigator.pop(context);
                context.read<AppointmentBloc>().add(AppointmentDeleteRequested(widget.appointmentId!));
              },
              variant: ButtonVariant.destructive,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}