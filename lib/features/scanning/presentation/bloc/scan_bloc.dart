import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/scanning/domain/repositories/scan_repository.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart'
    as domain;
import 'package:carepaw/features/scanning/presentation/bloc/scan_event.dart'
    as events;
import 'package:carepaw/features/scanning/presentation/bloc/scan_state.dart'
    as states;
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
      final records = await _scanRepository.findByStatus(
        domain.ScanStatus.pending,
      );
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
        emit(
          const states.ScanError(
            NotFoundFailure(message: 'Scan record not found'),
          ),
        );
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
      emit(
        const states.ScanOperationSuccess('Scan record created successfully'),
      );
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
      // No OCR backend is wired yet. We intentionally do NOT fabricate content:
      // writing invented OCR text/data into Firestore would store fake medical
      // info as if it were genuine. Surface that processing is unavailable until
      // a real OCR service is integrated. (See CLAUDE.md: "OCR output never
      // trusted blindly".)
      final record = await _scanRepository.findById(event.recordId);
      if (record == null) {
        emit(
          const states.ScanError(
            NotFoundFailure(message: 'Scan record not found'),
          ),
        );
        return;
      }

      emit(
        const states.ScanError(
          UnexpectedFailure(message: 'OCR service is not configured yet'),
        ),
      );
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
        emit(
          const states.ScanError(
            NotFoundFailure(message: 'Scan record not found'),
          ),
        );
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
        emit(
          const states.ScanError(
            NotFoundFailure(message: 'Scan record not found'),
          ),
        );
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
}
