import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/features/medical_records/presentation/bloc/medical_record_bloc.dart';
import 'package:carepaw/features/medical_records/presentation/bloc/medical_record_event.dart';
import 'package:carepaw/features/medical_records/presentation/bloc/medical_record_state.dart';
import 'package:carepaw/features/medical_records/domain/entities/medical_record.dart';
import 'package:carepaw/features/medical_records/presentation/widgets/medical_record_form_widgets.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';

/// Page for creating/editing medical records with premium design.
class MedicalRecordFormPage extends StatefulWidget {
  final Pet pet;
  final MedicalRecord? existingRecord;
  final MedicalRecordType? preSelectedType;

  const MedicalRecordFormPage({
    super.key,
    required this.pet,
    this.existingRecord,
    this.preSelectedType,
  });

  @override
  State<MedicalRecordFormPage> createState() => _MedicalRecordFormPageState();
}

class _MedicalRecordFormPageState extends State<MedicalRecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _attachmentsController = TextEditingController();

  MedicalRecordType _selectedType = MedicalRecordType.visit;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.preSelectedType ?? MedicalRecordType.visit;

    if (widget.existingRecord != null) {
      _titleController.text = widget.existingRecord!.title;
      _descriptionController.text = widget.existingRecord!.description ?? '';
      _diagnosisController.text = widget.existingRecord!.diagnosis ?? '';
      _treatmentController.text = widget.existingRecord!.treatment ?? '';
      _medicationsController.text = widget.existingRecord!.medications ?? '';
      _attachmentsController.text = widget.existingRecord!.attachments ?? '';
      _selectedType = widget.existingRecord!.recordType;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _medicationsController.dispose();
    _attachmentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speciesColor = widget.pet.species.accentColor;
    final isEditing = widget.existingRecord != null;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const MedicalRecordNotLoggedInView();
        }

        final user = authState.user;
        final isVetOrStaff = user.isOwnerAdmin;

        if (!isVetOrStaff) {
          return MedicalRecordAccessDeniedView(petName: widget.pet.name);
        }

        return BlocListener<MedicalRecordBloc, MedicalRecordState>(
          listener: (context, state) {
            if (state is MedicalRecordLoading) {
              setState(() => _isLoading = true);
            } else if (state is MedicalRecordOperationSuccess) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: ThemeColors.success(context),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(NeuTokens.radiusSm),
                  ),
                ),
              );
              context.pop();
            } else if (state is MedicalRecordError) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.failure.message),
                  backgroundColor: ThemeColors.error(context),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(NeuTokens.radiusSm),
                  ),
                ),
              );
            } else if (state is MedicalRecordsLoaded ||
                state is MedicalRecordsByTypeLoaded) {
              setState(() => _isLoading = false);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                isEditing ? 'Edit Record' : 'New Record',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                  onPressed: _isLoading ? null : () => context.pop(),
                  tooltip: 'Back',
                ),
              ),
            ),
            body: Form(
              key: _formKey,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Pet header
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    sliver: SliverToBoxAdapter(
                      child: MedicalRecordPetHeader(
                        pet: widget.pet,
                        selectedType: _selectedType,
                        speciesColor: speciesColor,
                      ),
                    ),
                  ),

                  // Record type selector
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: MedicalRecordTypeSelector(
                        selectedType: _selectedType,
                        speciesColor: speciesColor,
                        onChanged: (type) => setState(() => _selectedType = type),
                      ),
                    ),
                  ),

                  // Form fields
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    sliver: SliverList.separated(
                      itemCount: _getFields().length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (context, index) => _getFields()[index],
                    ),
                  ),

                  // Submit button
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
                    sliver: SliverToBoxAdapter(
                      child: _buildSubmitButton(context, isEditing),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _getFields() {
    final fields = <Widget>[];

    // Title (required for all types)
    fields.add(
      MedicalRecordFormField(
        controller: _titleController,
        label: 'Title *',
        hint: 'e.g., Annual checkup, Vaccination, Surgery follow-up',
        icon: Icons.title_outlined,
        svgAsset: SvgIcons.note,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Title is required';
          }
          return null;
        },
      ),
    );

    // Description (optional for all types)
    fields.add(
      MedicalRecordFormField(
        controller: _descriptionController,
        label: 'Description',
        hint: 'Brief description of the visit/reason',
        icon: Icons.description_outlined,
        svgAsset: SvgIcons.note,
        maxLines: 3,
      ),
    );

    // Type-specific fields
    switch (_selectedType) {
      case MedicalRecordType.visit:
        fields.addAll([
          MedicalRecordFormField(
            controller: _diagnosisController,
            label: 'Diagnosis',
            hint: 'Clinical diagnosis',
            icon: Icons.medical_services_outlined,
            svgAsset: SvgIcons.visit,
            maxLines: 3,
          ),
          MedicalRecordFormField(
            controller: _treatmentController,
            label: 'Treatment',
            hint: 'Treatment plan or procedures performed',
            icon: Icons.healing_outlined,
            svgAsset: SvgIcons.treatment,
            maxLines: 3,
          ),
        ]);
        break;

      case MedicalRecordType.vaccination:
        fields.addAll([
          MedicalRecordFormField(
            controller: _medicationsController,
            label: 'Vaccines Given *',
            hint: 'e.g., Rabies, DHPP, Bordetella',
            icon: Icons.vaccines_outlined,
            svgAsset: SvgIcons.vaccination,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the vaccines administered';
              }
              return null;
            },
          ),
        ]);
        break;

      case MedicalRecordType.deworming:
        fields.addAll([
          MedicalRecordFormField(
            controller: _medicationsController,
            label: 'Deworming Product *',
            hint: 'e.g., Pyrantel, Fenbendazole',
            icon: Icons.medication_outlined,
            svgAsset: SvgIcons.medication,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the deworming product used';
              }
              return null;
            },
          ),
        ]);
        break;

      case MedicalRecordType.surgery:
        fields.addAll([
          MedicalRecordFormField(
            controller: _diagnosisController,
            label: 'Procedure *',
            hint: 'Surgical procedure performed',
            icon: Icons.healing_outlined,
            svgAsset: SvgIcons.treatment,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Procedure is required for surgery records';
              }
              return null;
            },
          ),
          MedicalRecordFormField(
            controller: _treatmentController,
            label: 'Post-op Care',
            hint: 'Post-operative care instructions',
            icon: Icons.medical_information_outlined,
            svgAsset: SvgIcons.prescription,
            maxLines: 3,
          ),
          MedicalRecordFormField(
            controller: _medicationsController,
            label: 'Medications Prescribed',
            hint: 'Pain meds, antibiotics, etc.',
            icon: Icons.medication_outlined,
            svgAsset: SvgIcons.medication,
            maxLines: 3,
          ),
        ]);
        break;

      case MedicalRecordType.labResult:
        fields.addAll([
          MedicalRecordFormField(
            controller: _diagnosisController,
            label: 'Test Results *',
            hint: 'Lab findings and values',
            icon: Icons.science_outlined,
            svgAsset: SvgIcons.lab,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Test results are required for lab records';
              }
              return null;
            },
          ),
          MedicalRecordFormField(
            controller: _treatmentController,
            label: 'Interpretation',
            hint: 'Clinical interpretation of results',
            icon: Icons.psychology_outlined,
            maxLines: 3,
          ),
        ]);
        break;

      case MedicalRecordType.prescription:
        fields.addAll([
          MedicalRecordFormField(
            controller: _medicationsController,
            label: 'Medications *',
            hint: 'Medication name, dosage, frequency, duration',
            icon: Icons.medication_outlined,
            svgAsset: SvgIcons.medication,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Medications are required for prescriptions';
              }
              return null;
            },
          ),
          MedicalRecordFormField(
            controller: _treatmentController,
            label: 'Instructions',
            hint: 'Special administration instructions',
            icon: Icons.medical_information_outlined,
            svgAsset: SvgIcons.prescription,
            maxLines: 3,
          ),
        ]);
        break;

      case MedicalRecordType.note:
        fields.addAll([
          MedicalRecordFormField(
            controller: _diagnosisController,
            label: 'Clinical Notes *',
            hint: 'Detailed clinical notes',
            icon: Icons.note_outlined,
            svgAsset: SvgIcons.note,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Notes are required';
              }
              return null;
            },
          ),
        ]);
        break;

      case MedicalRecordType.allergy:
        fields.addAll([
          MedicalRecordFormField(
            controller: _diagnosisController,
            label: 'Allergen *',
            hint: 'What the pet is allergic to',
            icon: Icons.warning_amber_outlined,
            svgAsset: SvgIcons.alert,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Allergen is required';
              }
              return null;
            },
          ),
          MedicalRecordFormField(
            controller: _treatmentController,
            label: 'Reaction *',
            hint: 'Description of allergic reaction',
            icon: Icons.medical_services_outlined,
            svgAsset: SvgIcons.visit,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Reaction description is required';
              }
              return null;
            },
          ),
          MedicalRecordFormField(
            controller: _medicationsController,
            label: 'Management',
            hint: 'Avoidance strategies, emergency meds',
            icon: Icons.healing_outlined,
            svgAsset: SvgIcons.treatment,
            maxLines: 3,
          ),
        ]);
        break;
    }

    // Attachments (optional for all types)
    fields.add(
      MedicalRecordFormField(
        controller: _attachmentsController,
        label: 'Attachments',
        hint: 'Photo references, document links, etc.',
        icon: Icons.attachment_outlined,
        svgAsset: SvgIcons.attach,
        maxLines: 2,
      ),
    );

    return fields;
  }

  Widget _buildSubmitButton(BuildContext context, bool isEditing) {
    return NeuButton(
      text: isEditing ? 'Update Record' : 'Create Record',
      onPressed: _isLoading ? null : _submitForm,
      icon: isEditing ? Icons.save_rounded : Icons.add_rounded,
      svgAsset: isEditing ? SvgIcons.save : SvgIcons.add,
      isLoading: _isLoading,
      expanded: true,
      size: NeuButtonSize.medium,
      variant: NeuButtonVariant.primary,
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in again'),
          backgroundColor: ThemeColors.error(context),
        ),
      );
      return;
    }

    final userId = authState.user.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in again'),
          backgroundColor: ThemeColors.error(context),
        ),
      );
      return;
    }

    context.read<MedicalRecordBloc>().add(_createEvent(userId));
  }

  MedicalRecordEvent _createEvent(int userId) {
    switch (_selectedType) {
      case MedicalRecordType.visit:
        return CreateVisitRecord(
          petId: widget.pet.id!,
          veterinarianId: userId,
          appointmentId: null,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          diagnosis: _diagnosisController.text.trim().isEmpty
              ? null
              : _diagnosisController.text.trim(),
          treatment: _treatmentController.text.trim().isEmpty
              ? null
              : _treatmentController.text.trim(),
          medications: _medicationsController.text.trim().isEmpty
              ? null
              : _medicationsController.text.trim(),
          attachments: _attachmentsController.text.trim().isEmpty
              ? null
              : _attachmentsController.text.trim(),
        );

      case MedicalRecordType.vaccination:
        return CreateVaccinationRecord(
          petId: widget.pet.id!,
          veterinarianId: userId,
          appointmentId: null,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          medications: _medicationsController.text.trim(),
        );

      case MedicalRecordType.deworming:
        return CreateDewormingRecord(
          petId: widget.pet.id!,
          veterinarianId: userId,
          appointmentId: null,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          medications: _medicationsController.text.trim(),
        );

      case MedicalRecordType.surgery:
        return CreateVisitRecord(
          petId: widget.pet.id!,
          veterinarianId: userId,
          appointmentId: null,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          diagnosis: _diagnosisController.text.trim(),
          treatment: _treatmentController.text.trim().isEmpty
              ? null
              : _treatmentController.text.trim(),
          medications: _medicationsController.text.trim().isEmpty
              ? null
              : _medicationsController.text.trim(),
          attachments: _attachmentsController.text.trim().isEmpty
              ? null
              : _attachmentsController.text.trim(),
        );

      case MedicalRecordType.labResult:
        return CreateLabResultRecord(
          petId: widget.pet.id!,
          veterinarianId: userId,
          appointmentId: null,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );

      case MedicalRecordType.prescription:
        return CreateVisitRecord(
          petId: widget.pet.id!,
          veterinarianId: userId,
          appointmentId: null,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          medications: _medicationsController.text.trim(),
          treatment: _treatmentController.text.trim().isEmpty
              ? null
              : _treatmentController.text.trim(),
        );

      case MedicalRecordType.note:
        return CreateVisitRecord(
          petId: widget.pet.id!,
          veterinarianId: userId,
          appointmentId: null,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          diagnosis: _diagnosisController.text.trim(),
        );

      case MedicalRecordType.allergy:
        return CreateAllergyRecord(
          petId: widget.pet.id!,
          veterinarianId: userId,
          title: _titleController.text.trim(),
          description:
              '${_diagnosisController.text.trim()}\n\nReaction: ${_treatmentController.text.trim()}'
                  .trim(),
        );
    }
  }
}