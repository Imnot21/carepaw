import 'package:flutter/material.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';

/// Shared visual mappings for the inventory surfaces.
///
/// Category colors and icon assets are one voice across the list, detail,
/// form, and sheet surfaces — keep the mappings here so they stay in sync.
Color inventoryCategoryColor(InventoryCategory category) {
  switch (category) {
    case InventoryCategory.medicine:
      return AppColors.categoryMedicine;
    case InventoryCategory.vaccine:
      return AppColors.categoryVaccine;
    case InventoryCategory.supply:
      return AppColors.categorySupply;
    case InventoryCategory.equipment:
      return AppColors.categoryEquipment;
    case InventoryCategory.food:
      return AppColors.categoryFood;
  }
}

String inventoryCategorySvg(InventoryCategory category) {
  switch (category) {
    case InventoryCategory.medicine:
      return SvgIcons.medication;
    case InventoryCategory.vaccine:
      return SvgIcons.vaccination;
    case InventoryCategory.supply:
      return SvgIcons.inventory;
    case InventoryCategory.equipment:
      return SvgIcons.microscope;
    case InventoryCategory.food:
      return SvgIcons.foodBowl;
  }
}

String inventoryTransactionSvg(TransactionType type) {
  switch (type) {
    case TransactionType.in_:
      return SvgIcons.add;
    case TransactionType.out:
      return SvgIcons.remove;
    case TransactionType.adjustment:
      return SvgIcons.filter;
  }
}
