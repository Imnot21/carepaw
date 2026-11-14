import 'package:flutter/material.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:carepaw/features/appointments/domain/clinic_schedule.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
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
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_state.dart';

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
  final _addressController = TextEditingController();
  DateTime? _selectedDateTime;
  int _durationMinutes = 30;
  int? _selectedPetId;
  int? _selectedVeterinarianId;
  String? _selectedService;
  bool _isLoading = false;
  bool _triedSubmit = false;
  late Future<List<User>> _veterinariansFuture;

  /// The booking being edited, loaded once so the form opens filled in.
  Appointment? _existing;
  bool _loadingExisting = false;
  bool _loadFailed = false;

  bool get _isVetOrStaff => widget.userRole == UserRole.ownerAdmin;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.petId;
    _selectedVeterinarianId = widget.veterinarianId;
    _loadPetsAndVets();
    if (widget.appointmentId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() {
      _loadingExisting = true;
      _loadFailed = false;
    });
    try {
      final existing = await getIt<AppointmentRepository>().findById(
        widget.appointmentId!,
      );
      if (!mounted) return;
      if (existing == null) {
        setState(() {
          _loadingExisting = false;
          _loadFailed = true;
        });
        return;
      }
      setState(() {
        _existing = existing;
        _selectedPetId = existing.petId;
        _selectedVeterinarianId = existing.veterinarianId;
        _selectedDateTime = existing.scheduledAt;
        _durationMinutes = existing.durationMinutes;
        _selectedService = existing.service;
        _addressController.text = existing.serviceAddress ?? '';
        _reasonController.text = existing.reason ?? '';
        _notesController.text = existing.notes ?? '';
        _loadingExisting = false;
      });
    } catch (e) {
      debugPrint('[appointment_form] could not load booking: $e');
      if (!mounted) return;
      setState(() {
        _loadingExisting = false;
        _loadFailed = true;
      });
    }
  }

  void _loadPetsAndVets() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final ownerId = authState.user.id!;
      // Chapter 1: clients book by phone or Facebook, so the clinic books
      // for any client's pet. The booking takes the pet owner's id (the
      // repository stamps it from the pet), not the clinic's.
      context.read<PetBloc>().add(
        _isVetOrStaff ? const LoadAllPets() : LoadPets(ownerId: ownerId),
      );
      if (_isVetOrStaff) _loadOwnerNames();
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

  /// Owner names by user id, shown on each pet when the clinic books.
  /// Empty (not null) for the clinic until loaded, so the pet list already
  /// works in clinic mode; null for a pet owner.
  Map<int, String>? _ownerNames;

  Future<void> _loadOwnerNames() async {
    setState(() => _ownerNames = const {});
    try {
      final repo = getIt<UserRepository>();
      final results = await Future.wait([
        repo.findByRole(UserRole.petOwner),
        repo.findByRole(UserRole.ownerAdmin),
      ]);
      if (!mounted) return;
      setState(() {
        _ownerNames = {
          for (final user in results.expand((users) => users))
            if (user.id != null) user.id!: user.fullName,
        };
      });
    } catch (e) {
      debugPrint('[appointment_form] owner names unavailable: $e');
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.appointmentId != null;

    return MultiBlocListener(
      listeners: [
        BlocListener<AppointmentBloc, AppointmentState>(
          listener: (context, state) {
            if (state is AppointmentDeleted) {
              if (mounted) {
                setState(() => _isLoading = false);
                context.go(
                  _isVetOrStaff
                      ? Routes.staffAppointments
                      : Routes.appointments,
                );
                NeuToast.success(context, 'Booking deleted.');
              }
            } else if (state is AppointmentCreated ||
                state is AppointmentUpdated) {
              if (mounted) {
                setState(() => _isLoading = false);
                context.go(
                  _isVetOrStaff
                      ? Routes.staffAppointments
                      : Routes.appointments,
                );
                NeuToast.success(
                  context,
                  isEditing ? 'Appointment updated' : 'Appointment requested',
                );
              }
            } else if (state is AppointmentError) {
              if (mounted) {
                setState(() => _isLoading = false);
                NeuToast.error(
                  context,
                  "Couldn't save the booking. Check your connection and try again.",
                );
              }
            } else if (state is AppointmentLoading && mounted) {
              setState(() => _isLoading = true);
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Change booking' : 'Book a visit'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(NeuTokens.spaceXs),
            child: NeuIconButton(
              plain: true,
              icon: Icons.arrow_back_ios_new_rounded,
              svgAsset: SvgIcons.back,
              onPressed: () => context.pop(),
              tooltip: 'Back',
            ),
          ),
          actions: [
            if (isEditing && _isVetOrStaff && _existing != null)
              Padding(
                padding: const EdgeInsets.only(right: NeuTokens.spaceXs),
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
        body: _loadingExisting
            ? const NeuSkeletonDetail(blocks: 4)
            : _loadFailed
            ? NeuErrorState(
                title: "Couldn't load this booking",
                message: 'Check your connection and try again.',
                svgAsset: SvgIcons.error,
                onRetry: _loadExisting,
              )
            : SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: NeuTokens.maxContentWidth,
                    ),
                    child: Form(
                      key: _formKey,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              NeuTokens.pagePadding,
                              NeuTokens.pagePadding,
                              NeuTokens.pagePadding,
                              NeuTokens.spaceMd,
                            ),
                            sliver: SliverList.separated(
                              itemCount: _isVetOrStaff ? 7 : 5,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: NeuTokens.spaceLg),
                              itemBuilder: (context, index) =>
                                  _buildFormSection(context, index, isEditing),
                            ),
                          ),
                          // Submit button at bottom
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              NeuTokens.pagePadding,
                              0,
                              NeuTokens.pagePadding,
                              NeuTokens.pagePadding,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  NeuButton(
                                    text: isEditing
                                        ? 'Save Changes'
                                        : 'Send booking request',
                                    onPressed: _isLoading ? null : _submitForm,
                                    isLoading: _isLoading,
                                    expanded: true,
                                    size: NeuButtonSize.medium,
                                    icon: Icons.event_available_rounded,
                                    svgAsset: SvgIcons.eventAvailable,
                                    variant: NeuButtonVariant.primary,
                                  ),
                                  const SizedBox(height: NeuTokens.tightGap),
                                  NeuButton(
                                    text: 'Discard',
                                    onPressed: _isLoading
                                        ? null
                                        : () => context.pop(),
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
            ownerNames: _ownerNames,
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
            showError: _triedSubmit,
          );
        case 3:
          return ServiceSelectionSection(
            selectedService: _selectedService,
            onServiceChanged: _onServiceChanged,
            addressController: _addressController,
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
            ownerNames: _ownerNames,
          );
        case 1:
          return DateTimeSelectionSection(
            dateTimeText: _selectedDateTime != null
                ? '${_formatDate(_selectedDateTime!)} at ${_formatTime(_selectedDateTime!)}'
                : null,
            onTap: _pickDateTime,
            showError: _triedSubmit,
          );
        case 2:
          return ServiceSelectionSection(
            selectedService: _selectedService,
            onServiceChanged: _onServiceChanged,
            addressController: _addressController,
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

  void _onServiceChanged(String? value) {
    // Prefill a home visit with the owner's saved address; the clinic books
    // for other owners, so it types the address in.
    if (value == homeServiceLabel &&
        !_isVetOrStaff &&
        _addressController.text.trim().isEmpty) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _addressController.text = authState.user.address ?? '';
      }
    }
    setState(() => _selectedService = value);
  }

  Future<void> _pickDateTime() async {
    final initialDate = ClinicSchedule.nextOpenDay(
      _selectedDateTime ?? DateTime.now().add(const Duration(days: 1)),
    );

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
    if (!_triedSubmit) setState(() => _triedSubmit = true);
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPetId == null) {
      NeuToast.error(context, 'Pick which pet is coming in.');
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
          NeuToast.error(context, 'No veterinarian is available right now.');
          return;
        }
      } else {
        NeuToast.error(context, 'Pick a veterinarian for the visit.');
        return;
      }
    }

    if (_selectedDateTime == null) {
      NeuToast.error(context, 'Pick a date and time for the visit.');
      return;
    }

    if (!ClinicSchedule.isOpenDay(_selectedDateTime!)) {
      NeuToast.error(
        context,
        'The clinic is open on ${ClinicSchedule.openDaysLabel} only. '
        'Pick a weekend day.',
      );
      return;
    }

    if (_selectedDateTime!.isBefore(DateTime.now())) {
      NeuToast.error(
        context,
        'That time has already passed. Pick a later one.',
      );
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
      serviceAddress: _selectedService == homeServiceLabel
          ? _addressController.text.trim()
          : null,
      reason: _reasonController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: _existing?.createdAt ?? DateTime.now(),
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

  String _formatDate(DateTime date) => DateFormat('MMM d, y').format(date);

  String _formatTime(DateTime date) => DateFormat.jm().format(date);
}
