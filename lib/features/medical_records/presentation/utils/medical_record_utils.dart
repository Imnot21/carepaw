import 'package:carepaw/features/medical_records/domain/entities/medical_record.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Utility class for medical record presentation logic.
class MedicalRecordUtils {
  /// Get type-specific icon and color for a medical record type.
  static TypeInfo getTypeInfo(MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.visit:
        return TypeInfo(
          icon: Icons.local_hospital_outlined,
          color: AppColors.primary,
        );
      case MedicalRecordType.vaccination:
        return TypeInfo(
          icon: Icons.vaccines_outlined,
          color: AppColors.success,
        );
      case MedicalRecordType.surgery:
        return TypeInfo(
          icon: Icons.healing_outlined,
          color: AppColors.quaternary,
        );
      case MedicalRecordType.labResult:
        return TypeInfo(
          icon: Icons.science_outlined,
          color: AppColors.info,
        );
      case MedicalRecordType.prescription:
        return TypeInfo(
          icon: Icons.medication_outlined,
          color: AppColors.tertiary,
        );
      case MedicalRecordType.note:
        return TypeInfo(
          icon: Icons.note_outlined,
          color: AppColors.secondary,
        );
      case MedicalRecordType.allergy:
        return TypeInfo(
          icon: Icons.warning_amber_outlined,
          color: AppColors.error,
        );
    }
  }

  /// Get a short description for a record type.
  static String getTypeDescription(MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.visit:
        return 'General visit or consultation';
      case MedicalRecordType.vaccination:
        return 'Vaccination or immunization';
      case MedicalRecordType.surgery:
        return 'Surgical procedure';
      case MedicalRecordType.labResult:
        return 'Laboratory test results';
      case MedicalRecordType.prescription:
        return 'Medication prescription';
      case MedicalRecordType.note:
        return 'Clinical notes';
      case MedicalRecordType.allergy:
        return 'Allergy or adverse reaction';
    }
  }

  /// Format date for display.
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(recordDate).inDays;

    if (diff == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff == 1) {
      return 'Yesterday';
    } else if (diff < 7) {
      return '${diff}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Format full date for detail view.
  static String formatFullDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} at '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Get record type icon.
  static IconData getTypeIcon(MedicalRecordType type) {
    return getTypeInfo(type).icon;
  }

  /// Get record type color.
  static Color getTypeColor(MedicalRecordType type) {
    return getTypeInfo(type).color;
  }
}

/// Type information for medical record types.
class TypeInfo {
  final IconData icon;
  final Color color;

  TypeInfo({required this.icon, required this.color});
}