import 'package:carepaw/features/medical_records/domain/entities/medical_record.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/core/widgets/neomorphism/index.dart';
import 'package:flutter/material.dart';

/// Utility class for medical record presentation logic.
class MedicalRecordUtils {
  /// Get type-specific custom icon type and color for a medical record type.
  static TypeInfoCustom getTypeInfoCustom(BuildContext context, MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.visit:
        return TypeInfoCustom(
          customIcon: NeuIconType.visit,
          svgAsset: SvgIcons.visit,
          color: ThemeColors.primaryText(context),
        );
      case MedicalRecordType.vaccination:
        return TypeInfoCustom(
          customIcon: NeuIconType.vaccination,
          svgAsset: SvgIcons.vaccination,
          color: ThemeColors.success(context),
        );
      case MedicalRecordType.deworming:
        return TypeInfoCustom(
          customIcon: NeuIconType.medication,
          svgAsset: SvgIcons.medication,
          color: ThemeColors.success(context),
        );
      case MedicalRecordType.surgery:
        return TypeInfoCustom(
          customIcon: NeuIconType.treatment,
          svgAsset: SvgIcons.treatment,
          color: ThemeColors.warning(context),
        );
      case MedicalRecordType.labResult:
        return TypeInfoCustom(
          customIcon: NeuIconType.labTest,
          svgAsset: SvgIcons.lab,
          color: ThemeColors.info(context),
        );
      case MedicalRecordType.prescription:
        return TypeInfoCustom(
          customIcon: NeuIconType.prescription,
          svgAsset: SvgIcons.prescription,
          color: ThemeColors.progress(context),
        );
      case MedicalRecordType.note:
        return TypeInfoCustom(
          customIcon: NeuIconType.note,
          svgAsset: SvgIcons.note,
          color: ThemeColors.textSecondary(context),
        );
      case MedicalRecordType.allergy:
        return TypeInfoCustom(
          customIcon: NeuIconType.alert,
          svgAsset: SvgIcons.alert,
          color: ThemeColors.error(context),
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
      case MedicalRecordType.deworming:
        return 'Deworming treatment';
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} at '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Get record type color.
  static Color getTypeColor(BuildContext context, MedicalRecordType type) {
    return getTypeInfoCustom(context, type).color;
  }
}

/// Type information for medical record types (custom neumorphic icons).
class TypeInfoCustom {
  final NeuIconType customIcon;
  final String svgAsset;
  final Color color;

  TypeInfoCustom({
    required this.customIcon,
    required this.svgAsset,
    required this.color,
  });
}
