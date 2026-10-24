import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_badge.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:carepaw/features/inventory/presentation/widgets/batch_card.dart';
import 'package:carepaw/features/inventory/presentation/widgets/inventory_visuals.dart';

/// The scrolling header of the inventory detail page: category medallion,
/// item name, category + stock-status chips, back and archive actions.
class InventoryDetailHeader extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onArchive;

  const InventoryDetailHeader({
    super.key,
    required this.item,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLowStock = item.isLowStock;
    final isOutOfStock = item.isOutOfStock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 8),
              NeuIconButton(
                plain: true,
                icon: Icons.arrow_back_ios_new_rounded,
                svgAsset: SvgIcons.back,
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              NeuIconButton(
                plain: true,
                icon: Icons.archive_outlined,
                svgAsset: SvgIcons.archive,
                tooltip: 'Archive item',
                onPressed: onArchive,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: NeuContainer(
                    borderRadius: NeuTokens.radiusSm,
                    variant: NeuVariant.raised,
                    color: inventoryCategoryColor(item.category),
                    boxShadow: NeuShadow.color(
                      context,
                      inventoryCategoryColor(item.category),
                      blur: 18,
                      opacity: 0.32,
                    ),
                    child: NeuSvgIcon(
                      inventoryCategorySvg(item.category),
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textPrimaryOnDark
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          NeuTag(
                            label: item.category.displayName,
                            color: inventoryCategoryColor(item.category),
                          ),
                          const SizedBox(width: 8),
                          if (isOutOfStock)
                            NeuStatusBadge(
                              label: 'Out of Stock',
                              tone: NeuStatusTone.danger,
                            )
                          else if (isLowStock)
                            NeuStatusBadge(
                              label: 'Low Stock',
                              tone: NeuStatusTone.warning,
                            )
                          else
                            NeuStatusBadge(
                              label: 'In Stock',
                              tone: NeuStatusTone.success,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A single metric in the stock overview row (`Current Stock`, `Minimum`, ...).
class InventoryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  final String? svgAsset;

  const InventoryStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    this.svgAsset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NeuContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: NeuTokens.radiusSm,
      variant: NeuVariant.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(8),
            borderRadius: NeuTokens.radiusSm,
            variant: NeuVariant.raised,
            color: color.withValues(alpha: 0.1),
            child: svgAsset != null
                ? NeuSvgIcon(svgAsset!, size: 20)
                : Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryOnDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryOnDark
                  : AppColors.textPrimary,
            ),
          ),
          Text(
            unit,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryOnDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Label/value row used inside the batch details sheet.
class InventoryDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const InventoryDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryOnDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryOnDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip tab bar for the detail page's three tabs.
class InventoryTabBar extends StatelessWidget {
  final TabController tabController;
  final List<String> tabs;
  final Color color;

  const InventoryTabBar({
    super.key,
    required this.tabController,
    required this.tabs,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark
          ? AppColors.surfaceDarkMode.withValues(alpha: 0.95)
          : AppColors.surface.withValues(alpha: 0.95),
      child: AnimatedBuilder(
        animation: tabController,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              final isSelected = tabController.index == index;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: NeuChip(
                    label: label,
                    selected: isSelected,
                    selectedColor: color,
                    onTap: () => tabController.animateTo(index),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Empty state shown when an inventory tab has no content.
class InventoryDetailEmptyState extends StatelessWidget {
  final String? svgAsset;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const InventoryDetailEmptyState({
    super.key,
    this.svgAsset,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: NeuCard(
          borderRadius: NeuTokens.radiusMd,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeuContainer(
                borderRadius: 90,
                padding: const EdgeInsets.all(24),
                color: ThemeColors.primary(context),
                boxShadow: NeuShadow.color(
                  context,
                  ThemeColors.primary(context),
                  blur: 24,
                  opacity: 0.32,
                ),
                child: svgAsset != null
                    ? NeuSvgIcon(svgAsset!, size: 48)
                    : const SizedBox(width: 48, height: 48),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryOnDark
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryOnDark
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                NeuButton(
                  text: actionLabel!,
                  onPressed: onAction,
                  variant: NeuButtonVariant.primary,
                  size: NeuButtonSize.medium,
                  icon: Icons.add_rounded,
                  svgAsset: SvgIcons.add,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Batches tab: every batch of the item, with actions per batch.
class InventoryBatchesTab extends StatelessWidget {
  final InventoryItem item;
  final void Function(InventoryBatch batch) onBatchTap;
  final void Function(InventoryBatch batch) onTransaction;
  final VoidCallback onAddBatch;

  const InventoryBatchesTab({
    super.key,
    required this.item,
    required this.onBatchTap,
    required this.onTransaction,
    required this.onAddBatch,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is ItemBatchesLoaded && state.itemId == item.id) {
          final batches = state.batches;
          if (batches.isEmpty) {
            return InventoryDetailEmptyState(
              svgAsset: SvgIcons.barcode,
              title: 'No Batches',
              message:
                  'Add batches to track inventory lots and expiration dates',
              actionLabel: 'Add Batch',
              onAction: onAddBatch,
            );
          }
          // First row is the Add Batch action so new lots can be received
          // once the item already has batches.
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: batches.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NeuButton(
                    text: 'Add Batch',
                    onPressed: onAddBatch,
                    variant: NeuButtonVariant.outline,
                    size: NeuButtonSize.medium,
                    icon: Icons.add_rounded,
                    svgAsset: SvgIcons.add,
                    expanded: true,
                  ),
                );
              }
              final batch = batches[index - 1];
              // No batch edit: quantities change only through transactions
              // so every stock movement stays traceable.
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BatchCard(
                  batch: batch,
                  item: item,
                  onTap: () => onBatchTap(batch),
                  onTransaction: () => onTransaction(batch),
                ),
              );
            },
          );
        }
        if (state is InventoryLoading) {
          return const NeuSkeletonDetail(blocks: 4);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Expiring tab: batches of the item that are close to (or past) expiry.
class InventoryExpiringTab extends StatelessWidget {
  final InventoryItem item;
  final void Function(InventoryBatch batch) onBatchTap;

  const InventoryExpiringTab({
    super.key,
    required this.item,
    required this.onBatchTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is ExpiringBatchesLoaded) {
          final batches = state.batches
              .where((b) => b.inventoryId == item.id)
              .toList();
          if (batches.isEmpty) {
            return const InventoryDetailEmptyState(
              svgAsset: SvgIcons.eventAvailable,
              title: 'No Expiring Batches',
              message: 'All batches have sufficient shelf life',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BatchCard(
                  batch: batch,
                  item: item,
                  highlightExpiry: true,
                  onTap: () => onBatchTap(batch),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Transactions tab: stock in/out/adjustment history for the item.
class InventoryTransactionsTab extends StatelessWidget {
  final InventoryItem item;

  const InventoryTransactionsTab({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is ItemBatchesLoaded && state.itemId == item.id) {
          // TODO(post-demo): the bloc exposes transactions one batch at a
          // time, so there is nothing to aggregate here yet. Previously this
          // builder dispatched a load per batch on every rebuild, which could
          // loop forever once the item had batches; removed for the demo.
          return const InventoryDetailEmptyState(
            svgAsset: SvgIcons.receipt,
            title: 'No Transactions',
            message: 'Transaction history will appear here',
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
