import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/scanning/domain/repositories/scan_repository.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart' as domain;
import 'package:carepaw/features/scanning/presentation/bloc/scan_event.dart' as events;
import 'package:carepaw/features/scanning/presentation/bloc/scan_state.dart' as states;
import 'package:carepaw/core/errors/failures.dart';

/// Scan BLoC for managing scan records and OCR processing.
class ScanBloc extends Bloc<events.ScanEvent, states.ScanState> {
  final ScanRecordRepository _scanRepository;

  ScanBloc({required ScanRecordRepository scanRepository})
      : _scanRepository = scanRepository,
        super(const states.ScanInitial()) {
    on<events.LoadScanRecords>(_onLoadScanRecords);
    on<events.LoadScanRecordsByType>(_onLoadScanRecordsByType);
    on<events.LoadPendingScans>(_onLoadPendingScans);
    on<events.LoadScanRecordDetails>(_onLoadScanRecordDetails);
    on<events.CreateScanRecord>(_onCreateScanRecord);
    on<events.ProcessScanOcr>(_onProcessScanOcr);
    on<events.ConfirmScanRecord>(_onConfirmScanRecord);
    on<events.RejectScanRecord>(_onRejectScanRecord);
    on<events.RetryOcrProcessing>(_onRetryOcrProcessing);
    on<events.DeleteScanRecord>(_onDeleteScanRecord);
  }

  /// Load all scan records
  Future<void> _onLoadScanRecords(
    events.LoadScanRecords event,
    Emitter<states.ScanState> emit,
  ) async {
    emit(const states.ScanLoading());
    try {
      final records = await _scanRepository.findAll();
      emit(states.ScanRecordsLoaded(records));
    } on Failure catch (failure) {
      emit(states.ScanError(failure));
    } catch (e) {
      emit(states.ScanError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load scan records by type
  Future<void> _onLoadScanRecordsByType(
    events.LoadScanRecordsByType event,
    Emitter<states.ScanState> emit,
  ) async {
    emit(const states.ScanLoading());
    try {
      final records = await _scanRepository.findByType(event.scanType);
      emit(states.ScanRecordsByTypeLoaded(records, event.scanType));
    } on Failure catch (failure) {
      emit(states.ScanError(failure));
    } catch (e) {
      emit(states.ScanError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load pending scans
  Future<void> _onLoadPendingScans(
    events.LoadPendingScans event,
    Emitter<states.ScanState> emit,
  ) async {
    emit(const states.ScanLoading());
    try {
      final records = await _scanRepository.findByStatus(domain.ScanStatus.pending);
      emit(states.PendingScansLoaded(records));
    } on Failure catch (failure) {
      emit(states.ScanError(failure));
    } catch (e) {
      emit(states.ScanError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load scan record details
  Future<void> _onLoadScanRecordDetails(
    events.LoadScanRecordDetails event,
    Emitter<states.ScanState> emit,
  ) async {
    emit(const states.ScanLoading());
    try {
      final record = await _scanRepository.findById(event.recordId);
      if (record != null) {
        emit(states.ScanRecordDetailLoaded(record));
      } else {
        emit(const states.ScanError(NotFoundFailure(
          message: 'Scan record not found',
        )));
      }
    } on Failure catch (failure) {
      emit(states.ScanError(failure));
    } catch (e) {
      emit(states.ScanError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Create scan record
  Future<void> _onCreateScanRecord(
    events.CreateScanRecord event,
    Emitter<states.ScanState> emit,
  ) async {
    emit(const states.ScanLoading());
    try {
      final record = domain.ScanRecord(
        id: null,
        scanType: event.scanType,
        imagePath: event.imagePath,
        status: domain.ScanStatus.pending,
        createdAt: DateTime.now(),
      );
      await _scanRepository.save(record);
      emit(const states.ScanOperationSuccess('Scan record created successfully'));
      final records = await _scanRepository.findAll();
      emit(states.ScanRecordsLoaded(records));
    } on Failure catch (failure) {
      emit(states.ScanError(failure));
    } catch (e) {
      emit(states.ScanError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Process OCR for scan record
  Future<void> _onProcessScanOcr(
    events.ProcessScanOcr event,
    Emitter<states.ScanState> emit,
  ) async {
    emit(states.ScanOcrProcessing(event.recordId));
    try {
      // Simulate OCR processing (in real app, this would call OCR service)
      await Future.delayed(const Duration(seconds: 2));

      // Mock OCR result - in real implementation, this would come from OCR service
      final record = await _scanRepository.findById(event.recordId);
      if (record == null) {
        emit(const states.ScanError(NotFoundFailure(
          message: 'Scan record not found',
        )));
        return;
      }

      // Simulate OCR extraction
      final mockOcrText = _generateMockOcrText(record.scanType);
      final mockExtractedData = _generateMockExtractedData(record.scanType);
      final mockConfidence = 0.85 + (DateTime.now().millisecond % 10) / 100.0;

      final updatedRecord = record.copyWith(
        rawOcrText: mockOcrText,
        extractedData: mockExtractedData,
        confidenceScore: mockConfidence.clamp(0.0, 1.0),
        status: domain.ScanStatus.pending,
      );

      await _scanRepository.save(updatedRecord);
      emit(states.ScanOcrCompleted(updatedRecord));
    } on Failure catch (failure) {
      emit(states.ScanError(failure));
    } catch (e) {
      emit(states.ScanError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Confirm scan record
  Future<void> _onConfirmScanRecord(
    events.ConfirmScanRecord event,
    Emitter<states.ScanState> emit,
  ) async {
    emit(const states.ScanLoading());
    try {
      final record = await _scanRepository.findById(event.recordId);
      if (record == null) {
        emit(const states.ScanError(NotFoundFailure(
          message: 'Scan record not found',
        )));
        return;
      }

      final updatedRecord = record.copyWith(
        status: domain.ScanStatus.confirmed,
        confirmedBy: 1, // TODO: Get from auth state
        confirmedAt: DateTime.now(),
        corrections: event.corrections,
      );
      await _scanRepository.save(updatedRecord);
      emit(const states.ScanConfirmed('Scan record confirmed successfully'));
      final records = await _scanRepository.findAll();
      emit(states.ScanRecordsLoaded(records));
    } on Failure catch (failure) {
      emit(states.ScanError(failure));
    } catch (e) {
      emit(states.ScanError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Reject scan record
  Future<void> _onRejectScanRecord(
    events.RejectScanRecord event,
    Emitter<states.ScanState> emit,
  ) async {
    emit(const states.ScanLoading());
    try {
      final record = await _scanRepository.findById(event.recordId);
      if (record == null) {
        emit(const states.ScanError(NotFoundFailure(
          message: 'Scan record not found',
        )));
        return;
      }

      final updatedRecord = record.copyWith(
        status: domain.ScanStatus.rejected,
        corrections: event.reason,
      );
      await _scanRepository.save(updatedRecord);
      emit(const states.ScanRejected('Scan record rejected'));
      final records = await _scanRepository.findAll();
      emit(states.ScanRecordsLoaded(records));
    } on Failure catch (failure) {
      emit(states.ScanError(failure));
    } catch (e) {
      emit(states.ScanError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Retry OCR processing
  Future<void> _onRetryOcrProcessing(
    events.RetryOcrProcessing event,
    Emitter<states.ScanState> emit,
  ) async {
    add(events.ProcessScanOcr(event.recordId));
  }

  /// Delete scan record
  Future<void> _onDeleteScanRecord(
    events.DeleteScanRecord event,
    Emitter<states.ScanState> emit,
  ) async {
    emit(const states.ScanLoading());
    try {
      await _scanRepository.delete(event.recordId);
      emit(const states.ScanOperationSuccess('Scan record deleted'));
      final records = await _scanRepository.findAll();
      emit(states.ScanRecordsLoaded(records));
    } on Failure catch (failure) {
      emit(states.ScanError(failure));
    } catch (e) {
      emit(states.ScanError(UnexpectedFailure(message: e.toString())));
    }
  }

  String _generateMockOcrText(domain.ScanType type) {
    switch (type) {
      case domain.ScanType.receipt:
        return '''PET CARE PHARMACY
123 Main Street
City, State 12345

RECEIPT
Date: 2024-01-15
Time: 14:30

ITEMS:
Amoxicillin 250mg x 30 tabs  \$45.00
Vitamin B Complex x 100 tabs  \$22.50
Syringe 3ml x 10 pcs  \$15.00

SUBTOTAL: \$82.50
TAX: \$6.60
TOTAL: \$89.10

THANK YOU!''';
      case domain.ScanType.medicineBox:
        return '''MEDICINE LABEL
Product: Amoxicillin 250mg Capsules
Batch: AMX2024001
Mfg Date: 2024-01-01
Exp Date: 2026-01-01
Qty: 30 capsules
Mfg by: PharmaCorp Ltd.''';
      case domain.ScanType.prescription:
        return '''PRESCRIPTION
Dr. Smith Veterinary Clinic
Patient: Max (Dog)
Medication: Amoxicillin 250mg
Dosage: 1 capsule twice daily
Duration: 7 days
Refills: 0
Date: 2024-01-15''';
      case domain.ScanType.labReport:
        return '''LAB REPORT
Clinic: CarePaw Veterinary
Patient: Luna (Cat)
Test: Complete Blood Count
Date: 2024-01-15
WBC: 12.5 K/uL (Normal)
RBC: 6.8 M/uL (Normal)
HGB: 14.2 g/dL (Normal)
PLT: 280 K/uL (Normal)''';
      default:
        return 'Scanned document text content...';
    }
  }

  String _generateMockExtractedData(domain.ScanType type) {
    switch (type) {
      case domain.ScanType.receipt:
        return '{"items":[{"name":"Amoxicillin 250mg","quantity":30,"unit":"tabs","price":45.00},{"name":"Vitamin B Complex","quantity":100,"unit":"tabs","price":22.50}],"total":89.10}';
      case domain.ScanType.medicineBox:
        return '{"name":"Amoxicillin 250mg","batch":"AMX2024001","expiry":"2026-01-01","quantity":30,"unit":"capsules"}';
      case domain.ScanType.prescription:
        return '{"medication":"Amoxicillin 250mg","dosage":"1 capsule twice daily","duration":"7 days"}';
      case domain.ScanType.labReport:
        return '{"test":"CBC","results":{"WBC":"12.5","RBC":"6.8","HGB":"14.2","PLT":"280"}}';
      default:
        return '{}';
    }
  }
}