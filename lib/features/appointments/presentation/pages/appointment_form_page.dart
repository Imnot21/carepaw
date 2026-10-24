import 'package:flutter/material.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/presentation/widgets/appointment_form_widgets.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';

/// Appointment form page for creating or editing appointments
class AppointmentFormPage extends StatefulWidget {
  final int? appointmentId;
  final int? petId;
  final int? veterinarianId;
  final UserRole? userRole;

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

class _AppointmentFormPageState extends State<AppointmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDateTime;
  int _durationMinutes = 30;
  int? _selectedPetId;
  int? _selectedVeterinarianId;
  String? _selectedService;
  bool _isLoading = false;
  late Future<List<User>> _veterinariansFuture;

  bool get _isVetOrStaff => widget.userRole == UserRole.ownerAdmin;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.petId;
    _selectedVeterinarianId = widget.veterinarianId;
    _loadPetsAndVets();
  }

  void _loadPetsAndVets() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final ownerId = authState.user.id!;
      context.read<PetBloc>().add(LoadPets(ownerId: ownerId));
      _veterinariansFuture = getIt<UserRepository>().findVeterinarians();
      if (!_isVetOrStaff) {
        _veterinariansFuture
            .then((vets) {
              if (!mounted) return;
              if (vets.isNotEmpty && _selectedVeterinarianId == null) {
                setState(() => _selectedVeterinarianId = vets.first.id);
              }
            })
            .catchError((_) {});
      }
    } else {
      _veterinariansFuture = Future.value(const <User>[]);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
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
                NeuToast.success(
                  context,
                  isEditing ? 'Appointment updated' : 'Appointment requested',
                );
              }
            } else if (state is AppointmentError) {
              _isLoading = false;
              if (mounted) {
                NeuToast.error(context, state.message);
              }
            } else if (state is AppointmentLoading) {
              _isLoading = true;
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Appointment' : 'Request Appointment'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: NeuIconButton(
              plain: true,
              icon: Icons.arrow_back_ios_new_rounded,
              svgAsset: SvgIcons.back,
              onPressed: () => context.pop(),
              tooltip: 'Back',
            ),
          ),
          actions: [
            if (isEditing)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: NeuIconButton(
                  plain: true,
                  icon: Icons.delete_outline_rounded,
                  svgAsset: SvgIcons.delete,
                  onPressed: _showDeleteConfirmation,
                  color: ThemeColors.error(context),
                  tooltip: 'Delete',
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  sliver: SliverList.separated(
                    itemCount: _isVetOrStaff ? 7 : 5,
                    separatorBuilder: (_, _) => const SizedBox(height: 20),
                    itemBuilder: (context, index) =>
                        _buildFormSection(context, index, isEditing),
                  ),
                ),
                // Submit button at bottom
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        NeuButton(
                          text: isEditing
                              ? 'Update Appointment'
                              : 'Request Appointment',
                          onPressed: _isLoading ? null : _submitForm,
                          isLoading: _isLoading,
                          expanded: true,
                          size: NeuButtonSize.medium,
                          icon: Icons.event_available_rounded,
                          svgAsset: SvgIcons.eventAvailable,
                          variant: NeuButtonVariant.primary,
                        ),
                        const SizedBox(height: 12),
                        NeuButton(
                          text: 'Cancel',
                          onPressed: _isLoading ? null : () => context.pop(),
                          expanded: true,
                          size: NeuButtonSize.medium,
                          variant: NeuButtonVariant.ghost,
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
    );
  }

  Widget _buildFormSection(BuildContext context, int index, bool isEditing) {
    if (_isVetOrStaff) {
      switch (index) {
        case 0:
          return PetSelectionSection(
            selectedPetId: _selectedPetId,
            onPetSelected: (id) => setState(() => _selectedPetId = id),
            onAutoSelect: (id) => _selectedPetId = id,
          );
        case 1:
          return VeterinarianSelectionSection(
            isVetOrStaff: _isVetOrStaff,
            veterinariansFuture: _veterinariansFuture,
            selectedVeterinarianId: _selectedVeterinarianId,
            onVetSelected: (id) => setState(() => _selectedVeterinarianId = id),
            onAutoSelect: (id) => _selectedVeterinarianId = id,
          );
        case 2:
          return DateTimeSelectionSection(
            dateTimeText: _selectedDateTime != null
                ? '${_formatDate(_selectedDateTime!)} at ${_formatTime(_selectedDateTime!)}'
                : null,
            onTap: _pickDateTime,
          );
        case 3:
          return ServiceSelectionSection(
            selectedService: _selectedService,
            onServiceChanged: (value) =>
                setState(() => _selectedService = value),
          );
        case 4:
          return DurationSelectionSection(
            durationMinutes: _durationMinutes,
            onDurationChanged: (minutes) =>
                setState(() => _durationMinutes = minutes),
          );
        case 5:
          return ReasonSection(reasonController: _reasonController);
        case 6:
          return NotesSection(notesController: _notesController);
        default:
          return const SizedBox.shrink();
      }
    } else {
      switch (index) {
        case 0:
          return PetSelectionSection(
            selectedPetId: _selectedPetId,
            onPetSelected: (id) => setState(() => _selectedPetId = id),
            onAutoSelect: (id) => _selectedPetId = id,
          );
        case 1:
          return DateTimeSelectionSection(
            dateTimeText: _selectedDateTime != null
                ? '${_formatDate(_selectedDateTime!)} at ${_formatTime(_selectedDateTime!)}'
                : null,
            onTap: _pickDateTime,
          );
        case 2:
          return ServiceSelectionSection(
            selectedService: _selectedService,
            onServiceChanged: (value) =>
                setState(() => _selectedService = value),
          );
        case 3:
          return ReasonSection(reasonController: _reasonController);
        case 4:
          return NotesSection(notesController: _notesController);
        default:
          return const SizedBox.shrink();
      }
    }
  }

  Future<void> _pickDateTime() async {
    final initialDate =
        _selectedDateTime ?? DateTime.now().add(const Duration(days: 1));

    await NeuBottomSheet.show(
      context: context,
      isScrollControlled: true,
      maxHeight: MediaQuery.of(context).size.height * 0.6,
      child: DateTimePickerSheet(
        initialDate: initialDate,
        onDateTimeSelected: (dateTime) {
          setState(() => _selectedDateTime = dateTime);
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPetId == null) {
      NeuToast.error(context, 'Please select a pet');
      return;
    }

    if (_selectedVeterinarianId == null) {
      if (!_isVetOrStaff) {
        try {
          final vets = await getIt<UserRepository>().findVeterinarians();
          if (!mounted) return;
          if (vets.isNotEmpty) {
            setState(() => _selectedVeterinarianId = vets.first.id);
          }
        } catch (_) {}
        if (_selectedVeterinarianId == null) {
          if (!mounted) return;
          NeuToast.error(context, 'No veterinarian available for this clinic');
          return;
        }
      } else {
        NeuToast.error(context, 'Please select a veterinarian');
        return;
      }
    }

    if (_selectedDateTime == null) {
      NeuToast.error(context, 'Please select a date and time');
      return;
    }

    if (_selectedDateTime!.isBefore(DateTime.now())) {
      NeuToast.error(context, 'Cannot schedule appointment in the past');
      return;
    }

    _formKey.currentState!.save();

    final duration = _isVetOrStaff ? _durationMinutes : 30;
    final isEditing = widget.appointmentId != null;

    final appointment = Appointment(
      id: widget.appointmentId,
      petId: _selectedPetId!,
      veterinarianId: _selectedVeterinarianId!,
      scheduledAt: _selectedDateTime!,
      durationMinutes: duration,
      // Editing date/time after booking = rescheduled (thesis status).
      status: isEditing
          ? AppointmentStatus.rescheduled
          : AppointmentStatus.requested,
      service: _selectedService,
      reason: _reasonController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.appointmentId != null) {
      context.read<AppointmentBloc>().add(
        AppointmentUpdateRequested(appointment),
      );
    } else {
      context.read<AppointmentBloc>().add(
        AppointmentCreateRequested(appointment),
      );
    }
  }

  void _showDeleteConfirmation() {
    NeuConfirmDialog.show(
      context: context,
      title: 'Delete Appointment',
      message:
          'Are you sure you want to delete this appointment? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmVariant: NeuButtonVariant.destructive,
      onConfirm: () => context.read<AppointmentBloc>().add(
        AppointmentDeleteRequested(widget.appointmentId!),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
