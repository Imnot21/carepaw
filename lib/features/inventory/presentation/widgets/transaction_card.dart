import 'package:flutter/material.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/utils/formatters.dart';

/// Transaction card widget with premium design
class TransactionCard extends StatelessWidget {
  final InventoryTransaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(context, transaction.type);
    final typeIcon = _getTypeIcon(transaction.type);
    final isPositive = transaction.quantityChange > 0;

    return NeuCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      borderColor: typeColor.withValues(alpha: 0.15),
      borderWidth: 1,
      child: Row(
        children: [
          // Type indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, size: 24, color: typeColor),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      transaction.type.displayName,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ThemeColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPositive ? '+' : '−',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.reason,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12, color: ThemeColors.textTertiary(context)),
                    const SizedBox(width: 4),
                    Text(
                      formatDateTime(transaction.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: ThemeColors.textTertiary(context),
                      ),
                    ),
                    if (transaction.referenceType != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.link_rounded,
                          size: 12, color: ThemeColors.textTertiary(context)),
                      const SizedBox(width: 4),
                      Text(
                        '${transaction.referenceType}: ${transaction.referenceId}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: ThemeColors.textTertiary(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Quantity change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${formatNumber(transaction.quantityChange.abs())}',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: typeColor,
                ),
              ),
              if (transaction.notes != null &&
                  transaction.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    transaction.notes!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ThemeColors.textTertiary(context),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(BuildContext context, TransactionType type) {
    switch (type) {
      case TransactionType.in_:
        return ThemeColors.success(context);
      case TransactionType.out:
        return ThemeColors.error(context);
      case TransactionType.adjustment:
        return ThemeColors.warning(context);
    }
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.in_:
        return Icons.add_circle_rounded;
      case TransactionType.out:
        return Icons.remove_circle_rounded;
      case TransactionType.adjustment:
        return Icons.tune_rounded;
    }
  }
}
