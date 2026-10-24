import 'package:bloc_test/bloc_test.dart';
import 'package:carepaw/features/medical_records/domain/entities/medical_record.dart';
import 'package:carepaw/features/medical_records/domain/repositories/medical_record_repository.dart';
import 'package:carepaw/features/medical_records/presentation/bloc/medical_record_bloc.dart';
import 'package:carepaw/features/medical_records/presentation/bloc/medical_record_event.dart';
import 'package:carepaw/features/medical_records/presentation/bloc/medical_record_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRecords extends Mock implements MedicalRecordRepository {}

void main() {
  final visitDay = DateTime(2026, 10, 1);
  final now = DateTime(2026, 10, 25);
  final original = MedicalRecord(
    id: 40,
    petId: 5,
    veterinarianId: 3,
    appointmentId: 12,
    recordType: MedicalRecordType.prescription,
    title: 'Amoxicillin course',
    medications: 'Amoxicillin 500mg twice daily',
    recordedAt: visitDay,
    createdAt: visitDay,
  );

  late _MockRecords records;

  setUpAll(() => registerFallbackValue(original));

  setUp(() {
    records = _MockRecords();
    when(() => records.create(any())).thenAnswer(
      (inv) async =>
          (inv.positionalArguments.first as MedicalRecord).copyWith(id: 41),
    );
    when(() => records.findByPet(5)).thenAnswer((_) async => [original]);
  });

  MedicalRecordBloc build() =>
      MedicalRecordBloc(medicalRecordRepository: records);

  group('CreateMedicalRecord', () {
    blocTest<MedicalRecordBloc, MedicalRecordState>(
      'keeps the chosen type and every field',
      build: build,
      act: (bloc) => bloc.add(
        CreateMedicalRecord(
          MedicalRecord(
            petId: 5,
            veterinarianId: 3,
            recordType: MedicalRecordType.labResult,
            title: 'CBC panel',
            diagnosis: 'WBC 18.2 (high)',
            treatment: 'Likely infection',
            recordedAt: now,
            createdAt: now,
          ),
        ),
      ),
      expect: () => [
        isA<MedicalRecordLoading>(),
        isA<MedicalRecordOperationSuccess>().having(
          (s) => s.message,
          'message',
          'Lab Result record saved',
        ),
        isA<MedicalRecordsLoaded>(),
      ],
      verify: (_) {
        final saved =
            verify(() => records.create(captureAny())).captured.single
                as MedicalRecord;
        expect(saved.recordType, MedicalRecordType.labResult);
        expect(saved.diagnosis, 'WBC 18.2 (high)');
        expect(saved.treatment, 'Likely infection');
        expect(saved.isCorrection, isFalse);
      },
    );

    blocTest<MedicalRecordBloc, MedicalRecordState>(
      'a correction is a new record pointing at the original',
      build: build,
      act: (bloc) => bloc.add(
        CreateMedicalRecord(
          original.copyWith(
            medications: 'Amoxicillin 250mg twice daily',
            createdAt: now,
          ).withoutId(supersedes: 40, reason: 'Wrong dosage entered'),
        ),
      ),
      expect: () => [
        isA<MedicalRecordLoading>(),
        isA<MedicalRecordOperationSuccess>().having(
          (s) => s.message,
          'message',
          contains('Correction saved'),
        ),
        isA<MedicalRecordsLoaded>(),
      ],
      verify: (_) {
        final saved =
            verify(() => records.create(captureAny())).captured.single
                as MedicalRecord;
        expect(saved.id, isNull, reason: 'never overwrites the original');
        expect(saved.supersedesId, 40);
        expect(saved.correctionReason, 'Wrong dosage entered');
        expect(saved.recordedAt, visitDay);
        expect(saved.medications, 'Amoxicillin 250mg twice daily');
      },
    );
  });
}

extension on MedicalRecord {
  /// Same record as a new, unsaved correction of [supersedes].
  MedicalRecord withoutId({required int supersedes, required String reason}) =>
      MedicalRecord(
        petId: petId,
        veterinarianId: veterinarianId,
        appointmentId: appointmentId,
        recordType: recordType,
        title: title,
        medications: medications,
        recordedAt: recordedAt,
        createdAt: createdAt,
        supersedesId: supersedes,
        correctionReason: reason,
      );
}
