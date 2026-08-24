import 'package:flutter/material.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/floating_animation.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
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

  LinearGradient _getCategoryGradient(InventoryCategory category) {
    switch (category) {
      case InventoryCategory.medicine:
        return AppColors.gradientPrimary;
      case InventoryCategory.vaccine:
        return const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        );
      case InventoryCategory.supply:
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        );
      case InventoryCategory.equipment:
        return const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        );
      case InventoryCategory.food:
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        );
    }
  }

  Color _getCategoryColor(InventoryCategory category) {
    switch (category) {
      case InventoryCategory.medicine:
        return AppColors.primary;
      case InventoryCategory.vaccine:
        return const Color(0xFF06B6D4);
      case InventoryCategory.supply:
        return const Color(0xFF8B5CF6);
      case InventoryCategory.equipment:
        return const Color(0xFF6366F1);
      case InventoryCategory.food:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = batch.isExpired;
    final isExpiringSoon = batch.isExpiringSoon;
    final categoryColor = _getCategoryColor(item.category);

    return FloatingAnimation(
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        blur: 10,
        borderColor: isExpired
            ? AppColors.error.withValues(alpha: 0.3)
            : isExpiringSoon || highlightExpiry
                ? AppColors.warning.withValues(alpha: 0.3)
                : categoryColor.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: _getCategoryGradient(item.category),
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${item.name} • ${item.unit}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badges
                  Row(
                    children: [
                      if (isExpired)
                        _buildStatusBadge('Expired', AppColors.error,
                            pulse: true)
                      else if (isExpiringSoon || highlightExpiry)
                        _buildStatusBadge(
                            isExpiringSoon ? 'Expiring Soon' : 'Track Expiry',
                            AppColors.warning,
                            pulse: highlightExpiry),
                      const SizedBox(width: 8),
                      if (onEdit != null || onTransaction != null)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              color: AppColors.textTertiary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) {
                            if (value == 'edit') onEdit?.call();
                            if (value == 'transaction') onTransaction?.call();
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'transaction',
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_rounded,
                                      size: 20, color: AppColors.success),
                                  SizedBox(width: 8),
                                  Text('Add Transaction'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded,
                                      size: 20, color: AppColors.primary),
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
                      'Quantity',
                      formatNumber(batch.quantity),
                      Icons.inventory_2_rounded,
                      categoryColor,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'Received',
                      formatDate(batch.receivedAt),
                      Icons.calendar_today_rounded,
                      AppColors.info,
                    ),
                  ),
                  if (batch.expiresAt != null)
                    Expanded(
                      child: _buildInfoColumn(
                        'Expires',
                        formatDate(batch.expiresAt!),
                        Icons.event_rounded,
                        isExpired
                            ? AppColors.error
                            : isExpiringSoon
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                    )
                  else
                    Expanded(
                      child: _buildInfoColumn(
                        'Expires',
                        'No expiry',
                        Icons.event_busy_rounded,
                        AppColors.textTertiary,
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
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_money_rounded,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Cost/Unit: ${formatCurrency(batch.costPerUnit!)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (batch.supplier != null) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.local_shipping_rounded,
                            size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          batch.supplier!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
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
                      child: CpButton(
                        text: 'Stock In',
                        variant: ButtonVariant.primary,
                        icon: Icons.add_circle_outline_rounded,
                        size: ButtonSize.small,
                        onPressed: onTransaction,
                        expanded: true,
                        gradient: AppColors.gradientSuccess,
                      ),
                    ),
                  if (onTransaction != null) const SizedBox(width: 8),
                  if (onTransaction != null)
                    Expanded(
                      child: CpButton(
                        text: 'Stock Out',
                        variant: ButtonVariant.outline,
                        icon: Icons.remove_circle_outline_rounded,
                        size: ButtonSize.small,
                        onPressed: onTransaction,
                        expanded: true,
                        foregroundColor: AppColors.error,
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

  Widget _buildInfoColumn(
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
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color color, {bool pulse = false}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
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
        ),
        if (pulse)
          PulsingGlow(
            glowColor: color,
            maxRadius: 20,
            duration: const Duration(seconds: 2),
            child: const SizedBox.shrink(),
          ),
      ],
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