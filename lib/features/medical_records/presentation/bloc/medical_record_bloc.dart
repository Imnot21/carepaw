import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/medical_records/domain/repositories/medical_record_repository.dart';
import 'package:carepaw/features/medical_records/presentation/bloc/medical_record_event.dart'
    as events;
import 'package:carepaw/features/medical_records/presentation/bloc/medical_record_state.dart'
    as states;
import 'package:carepaw/core/errors/failures.dart';

/// Medical Record BLoC for managing medical record state.
///
/// Handles loading, creating medical records, and filtering by type.
class MedicalRecordBloc
    extends Bloc<events.MedicalRecordEvent, states.MedicalRecordState> {
  final MedicalRecordRepository _medicalRecordRepository;

  MedicalRecordBloc({required MedicalRecordRepository medicalRecordRepository})
      : _medicalRecordRepository = medicalRecordRepository,
        super(const states.MedicalRecordInitial()) {
    on<events.LoadMedicalRecords>(_onLoadMedicalRecords);
    on<events.LoadMedicalRecordsByType>(_onLoadMedicalRecordsByType);
    on<events.LoadMedicalRecordDetails>(_onLoadMedicalRecordDetails);
    on<events.CreateVisitRecord>(_onCreateVisitRecord);
    on<events.CreateVaccinationRecord>(_onCreateVaccinationRecord);
    on<events.CreateAllergyRecord>(_onCreateAllergyRecord);
    on<events.CreateLabResultRecord>(_onCreateLabResultRecord);
    on<events.LoadRecentRecords>(_onLoadRecentRecords);
  }

  /// Load all medical records for a pet
  Future<void> _onLoadMedicalRecords(
    events.LoadMedicalRecords event,
    Emitter<states.MedicalRecordState> emit,
  ) async {
    emit(const states.MedicalRecordLoading());
    try {
      final records = await _medicalRecordRepository.findByPet(event.petId);
      emit(states.MedicalRecordsLoaded(records));
    } on Failure catch (failure) {
      emit(states.MedicalRecordError(failure));
    } catch (e) {
      emit(states.MedicalRecordError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load medical records filtered by type
  Future<void> _onLoadMedicalRecordsByType(
    events.LoadMedicalRecordsByType event,
    Emitter<states.MedicalRecordState> emit,
  ) async {
    emit(const states.MedicalRecordLoading());
    try {
      final records = await _medicalRecordRepository.findByType(
        event.petId,
        event.recordType,
      );
      emit(states.MedicalRecordsByTypeLoaded(records, event.recordType));
    } on Failure catch (failure) {
      emit(states.MedicalRecordError(failure));
    } catch (e) {
      emit(states.MedicalRecordError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load a single record with details
  Future<void> _onLoadMedicalRecordDetails(
    events.LoadMedicalRecordDetails event,
    Emitter<states.MedicalRecordState> emit,
  ) async {
    emit(const states.MedicalRecordLoading());
    try {
      final record = await _medicalRecordRepository.findWithDetails(event.recordId);
      if (record != null) {
        emit(states.MedicalRecordDetailLoaded(record));
      } else {
        emit(const states.MedicalRecordError(NotFoundFailure(
          message: 'Medical record not found',
        )));
      }
    } on Failure catch (failure) {
      emit(states.MedicalRecordError(failure));
    } catch (e) {
      emit(states.MedicalRecordError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Create visit record
  Future<void> _onCreateVisitRecord(
    events.CreateVisitRecord event,
    Emitter<states.MedicalRecordState> emit,
  ) async {
    emit(const states.MedicalRecordLoading());
    try {
      await _medicalRecordRepository.createVisitRecord(
        petId: event.petId,
        veterinarianId: event.veterinarianId,
        appointmentId: event.appointmentId ?? 0,
        title: event.title,
        description: event.description,
        diagnosis: event.diagnosis,
        treatment: event.treatment,
        medications: event.medications,
        attachments: event.attachments,
      );
      emit(const states.MedicalRecordOperationSuccess(
        'Visit record created successfully',
      ));
      // Reload records for the pet
      final records = await _medicalRecordRepository.findByPet(event.petId);
      emit(states.MedicalRecordsLoaded(records));
    } on Failure catch (failure) {
      emit(states.MedicalRecordError(failure));
    } catch (e) {
      emit(states.MedicalRecordError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Create vaccination record
  Future<void> _onCreateVaccinationRecord(
    events.CreateVaccinationRecord event,
    Emitter<states.MedicalRecordState> emit,
  ) async {
    emit(const states.MedicalRecordLoading());
    try {
      await _medicalRecordRepository.createVaccinationRecord(
        petId: event.petId,
        veterinarianId: event.veterinarianId,
        appointmentId: event.appointmentId,
        title: event.title,
        description: event.description,
        medications: event.medications,
      );
      emit(const states.MedicalRecordOperationSuccess(
        'Vaccination record created successfully',
      ));
      final records = await _medicalRecordRepository.findByPet(event.petId);
      emit(states.MedicalRecordsLoaded(records));
    } on Failure catch (failure) {
      emit(states.MedicalRecordError(failure));
    } catch (e) {
      emit(states.MedicalRecordError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Create allergy record
  Future<void> _onCreateAllergyRecord(
    events.CreateAllergyRecord event,
    Emitter<states.MedicalRecordState> emit,
  ) async {
    emit(const states.MedicalRecordLoading());
    try {
      await _medicalRecordRepository.createAllergyRecord(
        petId: event.petId,
        veterinarianId: event.veterinarianId,
        title: event.title,
        description: event.description,
      );
      emit(const states.MedicalRecordOperationSuccess(
        'Allergy record created successfully',
      ));
      final records = await _medicalRecordRepository.findByPet(event.petId);
      emit(states.MedicalRecordsLoaded(records));
    } on Failure catch (failure) {
      emit(states.MedicalRecordError(failure));
    } catch (e) {
      emit(states.MedicalRecordError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Create lab result record
  Future<void> _onCreateLabResultRecord(
    events.CreateLabResultRecord event,
    Emitter<states.MedicalRecordState> emit,
  ) async {
    emit(const states.MedicalRecordLoading());
    try {
      await _medicalRecordRepository.createLabResultRecord(
        petId: event.petId,
        veterinarianId: event.veterinarianId,
        appointmentId: event.appointmentId,
        title: event.title,
        description: event.description,
      );
      emit(const states.MedicalRecordOperationSuccess(
        'Lab result record created successfully',
      ));
      final records = await _medicalRecordRepository.findByPet(event.petId);
      emit(states.MedicalRecordsLoaded(records));
    } on Failure catch (failure) {
      emit(states.MedicalRecordError(failure));
    } catch (e) {
      emit(states.MedicalRecordError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load recent records
  Future<void> _onLoadRecentRecords(
    events.LoadRecentRecords event,
    Emitter<states.MedicalRecordState> emit,
  ) async {
    emit(const states.MedicalRecordLoading());
    try {
      final records = await _medicalRecordRepository.getRecent(limit: event.limit);
      emit(states.RecentRecordsLoaded(records));
    } on Failure catch (failure) {
      emit(states.MedicalRecordError(failure));
    } catch (e) {
      emit(states.MedicalRecordError(UnexpectedFailure(message: e.toString())));
    }
  }
}