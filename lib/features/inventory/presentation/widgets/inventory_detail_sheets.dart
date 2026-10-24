import 'package:flutter/material.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/utils/formatters.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:carepaw/features/inventory/presentation/widgets/inventory_detail_widgets.dart';
import 'package:carepaw/features/inventory/presentation/widgets/inventory_visuals.dart';

/// Batch details bottom sheet.
///
/// [onAddTransaction] runs after the sheet closes so the caller can open the
/// transaction sheet from the page context.
void showBatchDetailSheet(
  BuildContext context, {
  required InventoryItem item,
  required InventoryBatch batch,
  required VoidCallback onAddTransaction,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => NeuContainer(
      margin: const EdgeInsets.all(20),
      borderRadius: NeuTokens.radiusMd,
      variant: NeuVariant.raised,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: NeuContainer(
                  borderRadius: NeuTokens.radiusSm,
                  variant: NeuVariant.raised,
                  color: inventoryCategoryColor(item.category),
                  boxShadow: NeuShadow.color(
                    context,
                    inventoryCategoryColor(item.category),
                    blur: 14,
                    opacity: 0.3,
                  ),
                  child: NeuSvgIcon(
                    inventoryCategorySvg(item.category),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch Details',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      batch.batchNumber,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryOnDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (batch.isExpired)
                InventoryStatusChip(
                  text: 'Expired',
                  color: ThemeColors.error(context),
                )
              else if (batch.isExpiringSoon)
                InventoryStatusChip(
                  text: 'Expiring Soon',
                  color: ThemeColors.warning(context),
                ),
            ],
          ),
          const SizedBox(height: 24),
          InventoryDetailRow(
            label: 'Quantity',
            value: '${formatNumber(batch.quantity)} ${item.unit}',
          ),
          InventoryDetailRow(
            label: 'Received',
            value: formatDate(batch.receivedAt),
          ),
          if (batch.expiresAt != null)
            InventoryDetailRow(
              label: 'Expires',
              value: formatDate(batch.expiresAt!),
            ),
          if (batch.costPerUnit != null)
            InventoryDetailRow(
              label: 'Cost/Unit',
              value: formatCurrency(batch.costPerUnit!),
            ),
          if (batch.supplier != null)
            InventoryDetailRow(label: 'Supplier', value: batch.supplier!),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: NeuButton(
                  text: 'Close',
                  variant: NeuButtonVariant.secondary,
                  onPressed: () => Navigator.pop(context),
                  expanded: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeuButton(
                  text: 'Add Transaction',
                  variant: NeuButtonVariant.primary,
                  icon: Icons.add_rounded,
                  svgAsset: SvgIcons.add,
                  onPressed: () {
                    Navigator.pop(context);
                    onAddTransaction();
                  },
                  expanded: true,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Stock transaction bottom sheet for [batch].
void showTransactionSheet(
  BuildContext context, {
  required InventoryItem item,
  required InventoryBatch batch,
}) {
  final bloc = context.read<InventoryBloc>();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final quantityController = TextEditingController();
  final reasonController = TextEditingController();
  final notesController = TextEditingController();
  TransactionType selectedType = TransactionType.in_;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => NeuContainer(
        margin: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
        ),
        borderRadius: NeuTokens.radiusMd,
        variant: NeuVariant.raised,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record Transaction',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryOnDark
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Batch: ${batch.batchNumber}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryOnDark
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TransactionType.values.map((type) {
                final isSelected = selectedType == type;
                return NeuChip(
                  label: type.displayName,
                  svgAsset: inventoryTransactionSvg(type),
                  selected: isSelected,
                  selectedColor: inventoryCategoryColor(item.category),
                  onTap: () => setState(() => selectedType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            NeuTextField(
              controller: quantityController,
              hint: 'Quantity',
              keyboardType: TextInputType.number,
              prefixIcon: NeuSvgIcon(SvgIcons.numbers, size: 20),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            NeuTextField(
              controller: reasonController,
              hint: 'Reason (e.g., Restock, Sale, Adjustment)',
              prefixIcon: NeuSvgIcon(SvgIcons.note, size: 20),
            ),
            const SizedBox(height: 12),
            NeuTextField(
              controller: notesController,
              hint: 'Notes (optional)',
              prefixIcon: NeuSvgIcon(SvgIcons.note, size: 20),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: NeuButton(
                    text: 'Cancel',
                    variant: NeuButtonVariant.ghost,
                    onPressed: () => Navigator.pop(context),
                    expanded: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeuButton(
                    text: 'Record',
                    variant: NeuButtonVariant.primary,
                    icon: Icons.save_rounded,
                    svgAsset: SvgIcons.save,
                    onPressed: () {
                      final quantity = double.tryParse(quantityController.text);
                      if (quantity == null || quantity <= 0) {
                        NeuToast.error(
                          context,
                          'Please enter a valid quantity',
                        );
                        return;
                      }
                      final authState = context.read<AuthBloc>().state;
                      final userId = authState is AuthAuthenticated
                          ? authState.user.id
                          : null;
                      if (userId == null) {
                        NeuToast.error(context, 'Please log in again');
                        return;
                      }
                      Navigator.pop(context);
                      _recordTransaction(
                        bloc,
                        batch,
                        selectedType,
                        quantity,
                        reasonController.text.trim(),
                        notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        userId,
                      );
                    },
                    expanded: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Sends the recorded transaction to the bloc.
void _recordTransaction(
  InventoryBloc bloc,
  InventoryBatch batch,
  TransactionType type,
  double quantity,
  String reason,
  String? notes,
  int userId,
) {
  switch (type) {
    case TransactionType.in_:
      bloc.add(
        CreateStockInTransaction(
          batchId: batch.id!,
          quantity: quantity,
          reason: reason,
          performedBy: userId,
          notes: notes,
        ),
      );
      break;
    case TransactionType.out:
      bloc.add(
        CreateStockOutTransaction(
          batchId: batch.id!,
          quantity: quantity,
          reason: reason,
          performedBy: userId,
          notes: notes,
        ),
      );
      break;
    case TransactionType.adjustment:
      bloc.add(
        CreateAdjustmentTransaction(
          batchId: batch.id!,
          quantityChange: quantity,
          reason: reason,
          performedBy: userId,
          notes: notes,
        ),
      );
      break;
  }
}

/// Add-batch bottom sheet: create a new batch for [item].
///
/// [initialBatchNumber] and [initialExpiry] prefill the form, e.g. with
/// values read from a confirmed scan; the person can still change them.
/// [scanRecordId] links the batch's opening transaction to that scan.
void showAddBatchSheet(
  BuildContext context, {
  required InventoryItem item,
  String? initialBatchNumber,
  DateTime? initialExpiry,
  int? scanRecordId,
}) {
  final bloc = context.read<InventoryBloc>();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final batchNumberController = TextEditingController(
    text: initialBatchNumber,
  );
  final quantityController = TextEditingController();
  final costController = TextEditingController();
  final supplierController = TextEditingController();
  DateTime? expiryDate = initialExpiry;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => NeuContainer(
        margin: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
        ),
        borderRadius: NeuTokens.radiusMd,
        variant: NeuVariant.raised,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Batch',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryOnDark
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            NeuTextField(
              controller: batchNumberController,
              hint: 'Batch Number',
              prefixIcon: NeuSvgIcon(SvgIcons.ticket, size: 20),
            ),
            const SizedBox(height: 12),
            NeuTextField(
              controller: quantityController,
              hint: 'Quantity',
              keyboardType: TextInputType.number,
              prefixIcon: NeuSvgIcon(SvgIcons.numbers, size: 20),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            NeuTextField(
              controller: costController,
              hint: 'Cost per Unit (optional)',
              keyboardType: TextInputType.number,
              prefixIcon: NeuSvgIcon(SvgIcons.money, size: 20),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            const SizedBox(height: 12),
            NeuTextField(
              controller: supplierController,
              hint: 'Supplier (optional)',
              prefixIcon: NeuSvgIcon(SvgIcons.truck, size: 20),
            ),
            const SizedBox(height: 12),
            NeuTextField(
              readOnly: true,
              onTap: () async {
                final date = await NeuDialog.show<DateTime?>(
                  context: context,
                  title: 'Select Expiry Date',
                  content: SizedBox(
                    height: 300,
                    child: CalendarDatePicker(
                      initialDate:
                          expiryDate != null &&
                              expiryDate!.isAfter(DateTime.now())
                          ? expiryDate!
                          : DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      onDateChanged: (date) => Navigator.pop(context, date),
                    ),
                  ),
                  actions: [
                    NeuButton(
                      text: 'Cancel',
                      variant: NeuButtonVariant.ghost,
                      onPressed: () => Navigator.pop(context),
                      expanded: true,
                    ),
                  ],
                );
                if (date != null) {
                  setState(() => expiryDate = date);
                }
              },
              hint: expiryDate != null
                  ? 'Expiry: ${formatDate(expiryDate!)}'
                  : 'Set Expiry Date (optional)',
              prefixIcon: NeuSvgIcon(SvgIcons.calendar, size: 20),
              suffixIcon: NeuSvgIcon(SvgIcons.chevronDown, size: 24),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: NeuButton(
                    text: 'Cancel',
                    variant: NeuButtonVariant.ghost,
                    onPressed: () => Navigator.pop(context),
                    expanded: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeuButton(
                    text: 'Add Batch',
                    variant: NeuButtonVariant.primary,
                    icon: Icons.add_rounded,
                    svgAsset: SvgIcons.add,
                    onPressed: () {
                      final batchNumber = batchNumberController.text.trim();
                      final quantity = double.tryParse(quantityController.text);
                      final cost = costController.text.isEmpty
                          ? null
                          : double.tryParse(costController.text);
                      if (batchNumber.isEmpty || quantity == null) {
                        NeuToast.error(context, 'Please fill required fields');
                        return;
                      }
                      final authState = context.read<AuthBloc>().state;
                      final userId = authState is AuthAuthenticated
                          ? authState.user.id
                          : null;
                      if (userId == null) {
                        NeuToast.error(context, 'Please log in again');
                        return;
                      }
                      Navigator.pop(context);
                      bloc.add(
                        CreateBatch(
                          inventoryId: item.id!,
                          batchNumber: batchNumber,
                          quantity: quantity,
                          receivedAt: DateTime.now(),
                          performedBy: userId,
                          referenceType: scanRecordId == null ? null : 'SCAN',
                          referenceId: scanRecordId,
                          expiresAt: expiryDate,
                          costPerUnit: cost,
                          supplier: supplierController.text.trim().isEmpty
                              ? null
                              : supplierController.text.trim(),
                        ),
                      );
                    },
                    expanded: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
