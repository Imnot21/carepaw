import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:carepaw/features/inventory/presentation/pages/inventory_form_page.dart';
import 'package:carepaw/features/inventory/presentation/widgets/batch_card.dart';
import 'package:carepaw/features/inventory/presentation/widgets/transaction_card.dart';
import 'package:carepaw/core/widgets/common/cp_empty_state.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/utils/formatters.dart';

/// Inventory detail page with neumorphic design.
class InventoryDetailPage extends StatefulWidget {
  final InventoryItem item;

  const InventoryDetailPage({super.key, required this.item});

  @override
  State<InventoryDetailPage> createState() => _InventoryDetailPageState();
}

class _InventoryDetailPageState extends State<InventoryDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    context.read<InventoryBloc>().add(LoadItemBatches(widget.item.id!));
    context.read<InventoryBloc>().add(LoadExpiringBatches());
    context.read<InventoryBloc>().add(LoadExpiredBatches());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isLowStock = item.isLowStock;
    final isOutOfStock = item.isOutOfStock;

    return Scaffold(
      backgroundColor: _isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(item, isLowStock, isOutOfStock),
          _buildStockOverview(item),
          _buildTabBar(),
          _buildTabContent(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Edit'),
        backgroundColor: _getCategoryColor(item.category),
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildAppBar(
      InventoryItem item, bool isLowStock, bool isOutOfStock) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: NeuIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        NeuIconButton(
          icon: Icons.delete_outline_rounded,
          onPressed: _showDeleteDialog,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: NeuContainer(
                    borderRadius: 18,
                    variant: NeuVariant.raised,
                    color: _getCategoryColor(item.category),
                    boxShadow: NeuShadow.color(
                        context, _getCategoryColor(item.category),
                        blur: 18, opacity: 0.32),
                    child: Icon(
                      _getCategoryIcon(item.category),
                      size: 36,
                      color: AppColors.textOnPrimary,
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
                          color: _isDark
                              ? AppColors.textPrimaryOnDark
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.category.displayName,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: _getCategoryColor(item.category),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isOutOfStock)
                            _buildStatusChip('Out of Stock', AppColors.error)
                          else if (isLowStock)
                            _buildStatusChip('Low Stock', AppColors.warning)
                          else
                            _buildStatusChip('In Stock', AppColors.success),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
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

  Widget _buildStockOverview(InventoryItem item) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Current Stock',
                formatNumber(item.currentStock),
                item.unit,
                _getCategoryColor(item.category),
                Icons.inventory_2_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Minimum',
                formatNumber(item.minStock),
                item.unit,
                AppColors.warning,
                Icons.warning_amber_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                item.maxStock != null ? 'Maximum' : 'No Max',
                item.maxStock != null
                    ? formatNumber(item.maxStock!)
                    : '—',
                item.unit,
                AppColors.info,
                Icons.flag_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return NeuContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      variant: NeuVariant.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: _isDark
                      ? AppColors.textSecondaryOnDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: _isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
            ),
          ),
          Text(
            unit,
            style: AppTextStyles.bodySmall.copyWith(
              color: _isDark
                  ? AppColors.textSecondaryOnDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        tabController: _tabController,
        tabs: const [
          Tab(text: 'Batches'),
          Tab(text: 'Expiring'),
          Tab(text: 'Transactions'),
        ],
        color: _getCategoryColor(widget.item.category),
      ),
    );
  }

  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildBatchesTab(),
          _buildExpiringTab(),
          _buildTransactionsTab(),
        ],
      ),
    );
  }

  Widget _buildBatchesTab() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is ItemBatchesLoaded &&
            state.itemId == widget.item.id) {
          final batches = state.batches;
          if (batches.isEmpty) {
            return CpEmptyState(
              icon: Icons.batch_prediction_outlined,
              title: 'No Batches',
              message:
                  'Add batches to track inventory lots and expiration dates',
              actionLabel: 'Add Batch',
              onAction: _showAddBatchDialog,
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
                  item: widget.item,
                  onTap: () => _showBatchDetail(batch),
                  onEdit: () => _editBatch(batch),
                  onTransaction: () => _showTransactionDialog(batch),
                ),
              );
            },
          );
        }
        if (state is InventoryLoading) {
          return const Center(
            child: SizedBox(
              width: 48,
              height: 48,
              child: NeuCircularProgress(),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildExpiringTab() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is ExpiringBatchesLoaded) {
          final batches = state.batches
              .where((b) => b.inventoryId == widget.item.id)
              .toList();
          if (batches.isEmpty) {
            return CpEmptyState(
              icon: Icons.event_available_rounded,
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
                  item: widget.item,
                  highlightExpiry: true,
                  onTap: () => _showBatchDetail(batch),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTransactionsTab() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is ItemBatchesLoaded &&
            state.itemId == widget.item.id) {
          // Get all transactions for all batches
          final allTransactions = <InventoryTransaction>[];
          for (final batch in state.batches) {
            context
                .read<InventoryBloc>()
                .add(LoadBatchTransactions(batch.id!));
          }
          if (allTransactions.isEmpty) {
            return CpEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Transactions',
              message: 'Transaction history will appear here',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: allTransactions.length,
            itemBuilder: (context, index) {
              final transaction = allTransactions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TransactionCard(transaction: transaction),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showBatchDetail(InventoryBatch batch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NeuContainer(
        margin: const EdgeInsets.all(20),
        borderRadius: 24,
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
                    borderRadius: 14,
                    variant: NeuVariant.raised,
                    color: _getCategoryColor(widget.item.category),
                    boxShadow: NeuShadow.color(
                        context, _getCategoryColor(widget.item.category),
                        blur: 14, opacity: 0.3),
                    child: Icon(_getCategoryIcon(widget.item.category),
                        size: 28, color: AppColors.textOnPrimary),
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
                          color: _isDark
                              ? AppColors.textPrimaryOnDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        batch.batchNumber,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _isDark
                              ? AppColors.textSecondaryOnDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (batch.isExpired)
                  _buildStatusChip('Expired', AppColors.error)
                else if (batch.isExpiringSoon)
                  _buildStatusChip('Expiring Soon', AppColors.warning),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Quantity',
                '${formatNumber(batch.quantity)} ${widget.item.unit}'),
            _buildDetailRow('Received',
                formatDate(batch.receivedAt)),
            if (batch.expiresAt != null)
              _buildDetailRow('Expires',
                  formatDate(batch.expiresAt!)),
            if (batch.costPerUnit != null)
              _buildDetailRow('Cost/Unit',
                  formatCurrency(batch.costPerUnit!)),
            if (batch.supplier != null)
              _buildDetailRow('Supplier', batch.supplier!),
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
                    onPressed: () {
                      Navigator.pop(context);
                      _showTransactionDialog(batch);
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: _isDark
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
                color: _isDark
                    ? AppColors.textPrimaryOnDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDialog(InventoryBatch batch) {
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
          borderRadius: 24,
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
                  color: _isDark
                      ? AppColors.textPrimaryOnDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Batch: ${batch.batchNumber}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _isDark
                      ? AppColors.textSecondaryOnDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SegmentedButton<TransactionType>(
                segments: TransactionType.values
                    .map((t) => ButtonSegment(
                          value: t,
                          label: Text(t.displayName),
                          icon: Icon(_getTransactionIcon(t)),
                        ))
                    .toList(),
                selected: {selectedType},
                onSelectionChanged: (selection) {
                  setState(() => selectedType = selection.first);
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerHighest,
                  selectedBackgroundColor:
                      _getCategoryColor(widget.item.category)
                          .withValues(alpha: 0.2),
                  selectedForegroundColor:
                      _getCategoryColor(widget.item.category),
                  side: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              NeuTextField(
                controller: quantityController,
                hint: 'Quantity',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.numbers_rounded),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              NeuTextField(
                controller: reasonController,
                hint: 'Reason (e.g., Restock, Sale, Adjustment)',
                prefixIcon: const Icon(Icons.description_rounded),
              ),
              const SizedBox(height: 12),
              NeuTextField(
                controller: notesController,
                hint: 'Notes (optional)',
                prefixIcon: const Icon(Icons.notes_rounded),
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
                      onPressed: () {
                        final quantity =
                            double.tryParse(quantityController.text);
                        if (quantity == null || quantity <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Please enter a valid quantity'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        _recordTransaction(
                          batch,
                          selectedType,
                          quantity,
                          reasonController.text.trim(),
                          notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
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

  void _recordTransaction(
    InventoryBatch batch,
    TransactionType type,
    double quantity,
    String reason,
    String? notes,
  ) {
    final userId = 1; // TODO: Get from auth state
    switch (type) {
      case TransactionType.in_:
        context.read<InventoryBloc>().add(CreateStockInTransaction(
              batchId: batch.id!,
              quantity: quantity,
              reason: reason,
              performedBy: userId,
              notes: notes,
            ));
        break;
      case TransactionType.out:
        context.read<InventoryBloc>().add(CreateStockOutTransaction(
              batchId: batch.id!,
              quantity: quantity,
              reason: reason,
              performedBy: userId,
              notes: notes,
            ));
        break;
      case TransactionType.adjustment:
        context.read<InventoryBloc>().add(CreateAdjustmentTransaction(
              batchId: batch.id!,
              quantityChange: quantity,
              reason: reason,
              performedBy: userId,
              notes: notes,
            ));
        break;
    }
  }

  void _showAddBatchDialog() {
    final batchNumberController = TextEditingController();
    final quantityController = TextEditingController();
    final costController = TextEditingController();
    final supplierController = TextEditingController();
    DateTime? expiryDate;

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
          borderRadius: 24,
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
                  color: _isDark
                      ? AppColors.textPrimaryOnDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              NeuTextField(
                controller: batchNumberController,
                hint: 'Batch Number',
                prefixIcon: const Icon(Icons.confirmation_number_rounded),
              ),
              const SizedBox(height: 12),
              NeuTextField(
                controller: quantityController,
                hint: 'Quantity',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.numbers_rounded),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              NeuTextField(
                controller: costController,
                hint: 'Cost per Unit (optional)',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.attach_money_rounded),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              const SizedBox(height: 12),
              NeuTextField(
                controller: supplierController,
                hint: 'Supplier (optional)',
                prefixIcon: const Icon(Icons.local_shipping_rounded),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() => expiryDate = date);
                  }
                },
                child: NeuContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 14,
                  variant: NeuVariant.inset,
                  borderColor: AppColors.border.withValues(alpha: 0.3),
                  borderWidth: 1,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: _isDark
                              ? AppColors.textSecondaryOnDark
                              : AppColors.textSecondary,
                          size: 20),
                      const SizedBox(width: 12),
                      Text(
                        expiryDate != null
                            ? 'Expiry: ${formatDate(expiryDate!)}'
                            : 'Set Expiry Date (optional)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: expiryDate != null
                              ? (_isDark
                                  ? AppColors.textPrimaryOnDark
                                  : AppColors.textPrimary)
                              : (_isDark
                                  ? AppColors.textSecondaryOnDark
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
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
                      onPressed: () {
                        final batchNumber =
                            batchNumberController.text.trim();
                        final quantity =
                            double.tryParse(quantityController.text);
                        final cost = costController.text.isEmpty
                            ? null
                            : double.tryParse(costController.text);
                        if (batchNumber.isEmpty || quantity == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Please fill required fields'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        context.read<InventoryBloc>().add(CreateBatch(
                              inventoryId: widget.item.id!,
                              batchNumber: batchNumber,
                              quantity: quantity,
                              receivedAt: DateTime.now(),
                              expiresAt: expiryDate,
                              costPerUnit: cost,
                              supplier: supplierController.text.trim()
                                  .isEmpty
                                  ? null
                                  : supplierController.text.trim(),
                            ));
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

  void _editBatch(InventoryBatch batch) {
    // Similar to add batch but pre-filled
    _showAddBatchDialog(); // Simplified for now
  }

  void _navigateToForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryFormPage(item: widget.item),
      ),
    ).then((_) {
      // Refresh on return
      setState(() {});
      _loadData();
    });
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Item',
            style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete "${widget.item.name}"? This action cannot be undone.',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary)),
          ),
          NeuButton(
            text: 'Delete',
            variant: NeuButtonVariant.destructive,
            size: NeuButtonSize.small,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              // TODO: Implement delete
            },
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(InventoryCategory category) {
    switch (category) {
      case InventoryCategory.medicine:
        return AppColors.categoryMedicine;
      case InventoryCategory.vaccine:
        return AppColors.categoryVaccine;
      case InventoryCategory.supply:
        return AppColors.categorySupply;
      case InventoryCategory.equipment:
        return const Color(0xFF6366F1);
      case InventoryCategory.food:
        return const Color(0xFFF59E0B);
    }
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

  IconData _getTransactionIcon(TransactionType type) {
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

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<Tab> tabs;
  final Color color;

  _TabBarDelegate({
    required this.tabController,
    required this.tabs,
    required this.color,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _isDarkOf(context)
          ? AppColors.surfaceDarkMode.withValues(alpha: 0.95)
          : AppColors.surface.withValues(alpha: 0.95),
      child: TabBar(
        controller: tabController,
        tabs: tabs,
        indicatorColor: color,
        indicatorWeight: 3,
        labelColor: color,
        unselectedLabelColor: _isDarkOf(context)
            ? AppColors.textSecondaryOnDark
            : AppColors.textSecondary,
        labelStyle: AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
      ),
    );
  }

  bool _isDarkOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}