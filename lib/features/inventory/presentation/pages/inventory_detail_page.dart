import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:carepaw/features/inventory/presentation/pages/inventory_form_page.dart';
import 'package:carepaw/features/inventory/presentation/widgets/inventory_detail_sheets.dart';
import 'package:carepaw/features/inventory/presentation/widgets/inventory_detail_widgets.dart';
import 'package:carepaw/features/inventory/presentation/widgets/inventory_visuals.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_fab.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/core/utils/formatters.dart';

/// Inventory detail page with the CarePaw surface system.
class InventoryDetailPage extends StatefulWidget {
  final InventoryItem item;

  const InventoryDetailPage({super.key, required this.item});

  @override
  State<InventoryDetailPage> createState() => _InventoryDetailPageState();
}

class _InventoryDetailPageState extends State<InventoryDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _loadedTab = 0;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTabData(0);
  }

  /// Loads the data for [index]'s tab. The bloc holds a single state for the
  /// whole page, so dispatching every load at once clobbered the previous
  /// ones and left the visible tab without a matching state (blank tab
  /// body). Dispatch only the active tab's load and re-dispatch when the
  /// tab changes.
  void _loadTabData(int index) {
    final bloc = context.read<InventoryBloc>();
    switch (index) {
      case 0:
      case 2:
        // The transactions tab also renders from the batch list.
        bloc.add(LoadItemBatches(widget.item.id!));
      case 1:
        bloc.add(LoadExpiringBatches());
    }
  }

  void _onTabChanged() {
    final index = _tabController.index;
    if (index == _loadedTab) return;
    _loadedTab = index;
    _loadTabData(index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      backgroundColor: _isDark
          ? AppColors.backgroundDark
          : AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            InventoryDetailHeader(item: item, onDelete: _showDeleteDialog),
            _buildStockOverview(item),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
      floatingActionButton: NeuFAB.extended(
        onPressed: _navigateToForm,
        icon: Icons.edit_rounded,
        svgAsset: SvgIcons.edit,
        extendedText: 'Edit',
        variant: NeuButtonVariant.primary,
      ),
    );
  }

  Widget _buildStockOverview(InventoryItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: InventoryStatCard(
              label: 'Current Stock',
              value: formatNumber(item.currentStock),
              unit: item.unit,
              color: inventoryCategoryColor(item.category),
              icon: Icons.inventory_2_rounded,
              svgAsset: SvgIcons.inventory,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InventoryStatCard(
              label: 'Minimum',
              value: formatNumber(item.minStock),
              unit: item.unit,
              color: _isDark ? AppColors.warningOnDark : AppColors.warning,
              icon: Icons.warning_amber_rounded,
              svgAsset: SvgIcons.alert,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InventoryStatCard(
              label: item.maxStock != null ? 'Maximum' : 'No Max',
              value: item.maxStock != null ? formatNumber(item.maxStock!) : '-',
              unit: item.unit,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.infoDark
                  : AppColors.info,
              icon: Icons.flag_rounded,
              svgAsset: SvgIcons.flag,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return InventoryTabBar(
      tabController: _tabController,
      tabs: const ['Batches', 'Expiring', 'Transactions'],
      color: inventoryCategoryColor(widget.item.category),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        InventoryBatchesTab(
          item: widget.item,
          onBatchTap: _showBatchDetail,
          onEditBatch: _editBatch,
          onTransaction: _showTransactionDialog,
          onAddBatch: _showAddBatchDialog,
        ),
        InventoryExpiringTab(item: widget.item, onBatchTap: _showBatchDetail),
        InventoryTransactionsTab(item: widget.item),
      ],
    );
  }

  void _showBatchDetail(InventoryBatch batch) {
    showBatchDetailSheet(
      context,
      item: widget.item,
      batch: batch,
      onAddTransaction: () => _showTransactionDialog(batch),
    );
  }

  void _showTransactionDialog(InventoryBatch batch) {
    showTransactionSheet(context, item: widget.item, batch: batch);
  }

  void _showAddBatchDialog() {
    showAddBatchSheet(context, item: widget.item);
  }

  void _editBatch(InventoryBatch batch) {
    // Similar to add batch but pre-filled
    _showAddBatchDialog(); // Simplified for now
  }

  void _navigateToForm() {
    // The form route needs the route-scoped InventoryBloc, which a pushed
    // route can't see on its own — pass it explicitly.
    final bloc = context.read<InventoryBloc>();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: InventoryFormPage(item: widget.item),
            ),
          ),
        )
        .then((_) {
          // Refresh on return
          setState(() {});
          _loadTabData(_tabController.index);
        });
  }

  void _showDeleteDialog() {
    NeuConfirmDialog.show(
      context: context,
      title: 'Delete Item',
      message:
          'Are you sure you want to delete "${widget.item.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmVariant: NeuButtonVariant.destructive,
    ).then((confirmed) {
      if (!mounted) return;
      if (confirmed == true) {
        Navigator.pop(context);
        // TODO: Implement delete
      }
    });
  }
}
