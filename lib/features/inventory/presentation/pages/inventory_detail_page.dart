import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_state.dart';
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

  /// Local copy of the item so the header and stat cards stay in sync with
  /// edits and stock operations without re-pushing the page.
  late InventoryItem _item;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
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
        bloc.add(LoadItemBatches(_item.id!));
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

  /// Keeps the header and stat cards live: after an edit the bloc re-emits
  /// the reloaded item list, and after any batch-quantity change it re-emits
  /// this item's batches — from which the aggregate stock is derived (item
  /// stock equals the sum of its batch quantities).
  void _onInventoryState(BuildContext context, InventoryState state) {
    InventoryItem? updated;
    if (state is InventoryItemsLoaded) {
      for (final candidate in state.items) {
        if (candidate.id == _item.id) {
          updated = candidate;
          break;
        }
      }
    } else if (state is ItemBatchesLoaded && state.itemId == _item.id) {
      final stock = state.batches.fold<double>(
        0,
        (sum, batch) => sum + batch.quantity,
      );
      if (stock != _item.currentStock) {
        updated = _item.copyWith(currentStock: stock);
      }
    }
    final next = updated;
    if (next == null) return;
    setState(() => _item = next);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;

    return BlocListener<InventoryBloc, InventoryState>(
      listener: _onInventoryState,
      child: Scaffold(
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
      color: inventoryCategoryColor(_item.category),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        InventoryBatchesTab(
          item: _item,
          onBatchTap: _showBatchDetail,
          onEditBatch: _editBatch,
          onTransaction: _showTransactionDialog,
          onAddBatch: _showAddBatchDialog,
        ),
        InventoryExpiringTab(item: _item, onBatchTap: _showBatchDetail),
        InventoryTransactionsTab(item: _item),
      ],
    );
  }

  void _showBatchDetail(InventoryBatch batch) {
    showBatchDetailSheet(
      context,
      item: _item,
      batch: batch,
      onAddTransaction: () => _showTransactionDialog(batch),
    );
  }

  void _showTransactionDialog(InventoryBatch batch) {
    showTransactionSheet(context, item: _item, batch: batch);
  }

  void _showAddBatchDialog() {
    showAddBatchSheet(context, item: _item);
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
              child: InventoryFormPage(item: _item),
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
          'Are you sure you want to delete "${_item.name}"? This action cannot be undone.',
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
