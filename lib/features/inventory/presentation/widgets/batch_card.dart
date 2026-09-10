import 'package:flutter/material.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/utils/formatters.dart';

/// Batch card widget with premium design
class BatchCard extends StatelessWidget {
  final InventoryBatch batch;
  final InventoryItem item;
  final bool highlightExpiry;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onTransaction;

  const BatchCard({
    super.key,
    required this.batch,
    required this.item,
    this.highlightExpiry = false,
    this.onTap,
    this.onEdit,
    this.onTransaction,
  });

  Color _getCategoryColor(InventoryCategory category) {
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
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = batch.isExpired;
    final isExpiringSoon = batch.isExpiringSoon;
    final categoryColor = _getCategoryColor(item.category);

    return NeuCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      borderColor: isExpired
          ? ThemeColors.error(context).withValues(alpha: 0.3)
          : isExpiringSoon || highlightExpiry
              ? ThemeColors.warning(context).withValues(alpha: 0.3)
              : categoryColor.withValues(alpha: 0.1),
      borderWidth: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                NeuContainer(
                  padding: const EdgeInsets.all(10),
                  borderRadius: 12,
                  color: categoryColor,
                  child: Icon(
                    _getCategoryIcon(item.category),
                    size: 22,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.batchNumber,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ThemeColors.textPrimary(context),
                        ),
                      ),
                      Text(
                        '${item.name} • ${item.unit}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: ThemeColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badges
                Row(
                  children: [
                    if (isExpired)
                      _buildStatusBadge(
                          'Expired',
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.errorOnDark
                              : AppColors.error)
                    else if (isExpiringSoon || highlightExpiry)
                      _buildStatusBadge(
                          isExpiringSoon ? 'Expiring Soon' : 'Track Expiry',
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.warningOnDark
                              : AppColors.warning),
                    const SizedBox(width: 8),
                    if (onEdit != null || onTransaction != null)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded,
                            color: ThemeColors.textTertiary(context)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          if (value == 'edit') onEdit?.call();
                          if (value == 'transaction') onTransaction?.call();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'transaction',
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_rounded,
                                    size: 20,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.successOnDark
                                        : AppColors.success),
                                SizedBox(width: 8),
                                Text('Add Transaction'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded,
                                    size: 20,
                                    color: ThemeColors.primary(context)),
                                SizedBox(width: 8),
                                Text('Edit Batch'),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quantity and dates
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn(
                    context,
                    'Quantity',
                    formatNumber(batch.quantity),
                    Icons.inventory_2_rounded,
                    categoryColor,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    context,
                    'Received',
                    formatDate(batch.receivedAt),
                    Icons.calendar_today_rounded,
                    Theme.of(context).brightness == Brightness.dark
                        ? AppColors.infoDark
                        : AppColors.info,
                  ),
                ),
                if (batch.expiresAt != null)
                  Expanded(
                    child: _buildInfoColumn(
                      context,
                      'Expires',
                      formatDate(batch.expiresAt!),
                      Icons.event_rounded,
                      isExpired
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.errorOnDark
                              : AppColors.error)
                          : isExpiringSoon
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.warningOnDark
                                  : AppColors.warning)
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.successOnDark
                                  : AppColors.success),
                    ),
                  )
                else
                  Expanded(
                    child: _buildInfoColumn(
                      context,
                      'Expires',
                      'No expiry',
                      Icons.event_busy_rounded,
                      ThemeColors.textTertiary(context),
                    ),
                  ),
              ],
            ),

            if (batch.costPerUnit != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_money_rounded,
                        size: 18, color: ThemeColors.textSecondary(context)),
                    const SizedBox(width: 8),
                    Text(
                      'Cost/Unit: ${formatCurrency(batch.costPerUnit!)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ThemeColors.textPrimary(context),
                      ),
                    ),
                    if (batch.supplier != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.local_shipping_rounded,
                          size: 18, color: ThemeColors.textSecondary(context)),
                      const SizedBox(width: 8),
                      Text(
                        batch.supplier!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: ThemeColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                if (onTransaction != null)
                  Expanded(
                    child: NeuButton(
                      text: 'Stock In',
                      variant: NeuButtonVariant.primary,
                      icon: Icons.add_circle_outline_rounded,
                      size: NeuButtonSize.medium,
                      onPressed: onTransaction,
                      expanded: true,
                    ),
                  ),
                if (onTransaction != null) const SizedBox(width: 8),
                if (onTransaction != null)
                  Expanded(
                    child: NeuButton(
                      text: 'Stock Out',
                      variant: NeuButtonVariant.outline,
                      icon: Icons.remove_circle_outline_rounded,
                      size: NeuButtonSize.medium,
                      onPressed: onTransaction,
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

  Widget _buildInfoColumn(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: ThemeColors.textPrimary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(InventoryCategory category) {
    switch (category) {
      case InventoryCategory.medicine:
        return Icons.medication_rounded;
      case InventoryCategory.vaccine:
        return Icons.vaccines_rounded;
      case InventoryCategory.supply:
        return Icons.inventory_rounded;
      case InventoryCategory.equipment:
        return Icons.precision_manufacturing_rounded;
      case InventoryCategory.food:
        return Icons.restaurant_rounded;
    }
  }
}
