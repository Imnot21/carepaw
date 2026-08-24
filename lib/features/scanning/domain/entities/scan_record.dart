import 'package:equatable/equatable.dart';

/// Scan record entity - domain layer representation
class ScanRecord extends Equatable {
  final int? id;
  final ScanType scanType;
  final String imagePath;
  final String? rawOcrText;
  final String? extractedData;
  final double? confidenceScore;
  final ScanStatus status;
  final int? confirmedBy;
  final DateTime? confirmedAt;
  final String? corrections;
  final DateTime createdAt;

  const ScanRecord({
    this.id,
    required this.scanType,
    required this.imagePath,
    this.rawOcrText,
    this.extractedData,
    this.confidenceScore,
    this.status = ScanStatus.pending,
    this.confirmedBy,
    this.confirmedAt,
    this.corrections,
    required this.createdAt,
  });

  /// Check if scan is pending confirmation
  bool get isPending => status == ScanStatus.pending;

  /// Check if scan is confirmed
  bool get isConfirmed => status == ScanStatus.confirmed;

  /// Check if scan is rejected
  bool get isRejected => status == ScanStatus.rejected;

  /// Check if scan has high confidence
  bool get hasHighConfidence => confidenceScore != null && confidenceScore! >= 0.8;

  @override
  List<Object?> get props => [
        id,
        scanType,
        imagePath,
        rawOcrText,
        extractedData,
        confidenceScore,
        status,
        confirmedBy,
        confirmedAt,
        corrections,
        createdAt,
      ];

  ScanRecord copyWith({
    int? id,
    ScanType? scanType,
    String? imagePath,
    String? rawOcrText,
    String? extractedData,
    double? confidenceScore,
    ScanStatus? status,
    int? confirmedBy,
    DateTime? confirmedAt,
    String? corrections,
    DateTime? createdAt,
  }) {
    return ScanRecord(
      id: id ?? this.id,
      scanType: scanType ?? this.scanType,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      extractedData: extractedData ?? this.extractedData,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      status: status ?? this.status,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      corrections: corrections ?? this.corrections,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Scan type enum
enum ScanType {
  receipt('RECEIPT'),
  medicineBox('MEDICINE_BOX'),
  prescription('PRESCRIPTION'),
  labReport('LAB_REPORT'),
  other('OTHER');

  final String value;
  const ScanType(this.value);

  static ScanType fromString(String value) {
    return ScanType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ScanType.other,
    );
  }

  String get displayName {
    switch (this) {
      case ScanType.receipt:
        return 'Receipt';
      case ScanType.medicineBox:
        return 'Medicine Box';
      case ScanType.prescription:
        return 'Prescription';
      case ScanType.labReport:
        return 'Lab Report';
      case ScanType.other:
        return 'Other';
    }
  }
}

/// Scan status enum
enum ScanStatus {
  pending('PENDING'),
  confirmed('CONFIRMED'),
  rejected('REJECTED');

  final String value;
  const ScanStatus(this.value);

  static ScanStatus fromString(String value) {
    return ScanStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ScanStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case ScanStatus.pending:
        return 'Pending';
      case ScanStatus.confirmed:
        return 'Confirmed';
      case ScanStatus.rejected:
        return 'Rejected';
    }
  }
}