import 'package:flutter/material.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';

/// One accent per scan type, shared by the scan list, camera and detail
/// screens so a receipt is the same colour wherever it appears.
Color scanTypeColor(BuildContext context, ScanType type) {
  switch (type) {
    case ScanType.receipt:
      return ThemeColors.success(context);
    case ScanType.medicineBox:
      return AppColors.categoryMedicine;
    case ScanType.prescription:
      return AppColors.categorySupply;
    case ScanType.labReport:
      return AppColors.categoryVaccine;
    case ScanType.other:
      return ThemeColors.textSecondary(context);
  }
}
