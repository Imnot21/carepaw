import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/utils/input_formatters.dart';
import 'package:carepaw/core/widgets/neomorphism/index.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/domain/services/stock_intake_service.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_state.dart';

/// Inventory tab: search the medicines in stock, add or restock them,
/// check expiry dates, and take stock out.
///
/// Stock comes in through the Scan tab or the Add stock form. Chapter 1
/// (Medicine Inventory) asks the clinic to view, monitor and update expiry
/// dates, so every medicine shows its nearest expiry, the Expiring and
/// Expired filters list what needs attention, and a wrong date can be
/// corrected from the edit sheet.
class InventoryListPage extends StatefulWidget {
  const InventoryListPage({super.key});

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  final _searchController = TextEditingController();
  String _query = '';

  /// The last loaded list, kept so an edit or a failed save does not
  /// blank the page.
  List<InventoryItem>? _items;

  /// Batches that still hold stock, from the same load as [_items].
  List<InventoryBatch> _batches = const [];

  _ExpiryFilter _filter = _ExpiryFilter.all;

  List<InventoryBatch> _batchesOf(InventoryItem item) =>
      InventoryItemsLoaded(const [], batches: _batches).batchesOf(item.id);

  _ExpiryStatus _statusOf(InventoryItem item) =>
      _expiryStatus(_batchesOf(item));

  int _count(_ExpiryStatus status) => (_items ?? const <InventoryItem>[])
      .where((item) => _statusOf(item) == status)
      .length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InventoryItem> get _visible {
    final words = _query.toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    final items = (_items ?? const <InventoryItem>[]).where((item) {
      final name = item.name.toLowerCase();
      if (!words.every(name.contains)) return false;
      return switch (_filter) {
        _ExpiryFilter.all => true,
        _ExpiryFilter.expiring => _statusOf(item) == _ExpiryStatus.soon,
        _ExpiryFilter.expired => _statusOf(item) == _ExpiryStatus.expired,
      };
    }).toList();
    return items
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  int? get _userId {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthAuthenticated ? auth.user.id : null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const _NotLoggedInView();
        }
        // Only the clinic owner/admin manages stock.
        if (!authState.user.isOwnerAdmin) {
          return const _AccessDeniedView();
        }

        return Scaffold(
          backgroundColor: ThemeColors.background(context),
          body: SafeArea(
            bottom: false,
            child: BlocConsumer<InventoryBloc, InventoryState>(
              listener: _onState,
              builder: (context, state) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  Expanded(child: _buildList(state)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onState(BuildContext context, InventoryState state) {
    if (state is InventoryItemsLoaded) {
      setState(() {
        _items = state.items;
        _batches = state.batches;
      });
    } else if (state is InventoryOperationSuccess) {
      NeuToast.success(context, state.message);
    } else if (state is InventoryError && _items != null) {
      NeuToast.error(context, state.failure.message);
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Inventory',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
              ),
              NeuButton(
                text: 'Add stock',
                icon: Icons.add_rounded,
                svgAsset: SvgIcons.add,
                size: NeuButtonSize.medium,
                onPressed: () => _addStock(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Add or restock medicines, check expiry dates, take stock out',
            style: AppTextStyles.bodySmall.copyWith(
              color: ThemeColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 16),
          NeuTextField(
            controller: _searchController,
            hint: 'Search medicines',
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: NeuSvgIcon(SvgIcons.search, size: 22),
            ),
            suffixIcon: _query.isEmpty
                ? null
                : NeuIconButton(
                    plain: true,
                    icon: Icons.close_rounded,
                    svgAsset: SvgIcons.close,
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
          const SizedBox(height: 12),
          NeuChipRow(
            padding: EdgeInsets.zero,
            chips: [
              NeuChip(
                label: 'All',
                selected: _filter == _ExpiryFilter.all,
                onTap: () => setState(() => _filter = _ExpiryFilter.all),
              ),
              NeuChip(
                label: 'Expiring soon (${_count(_ExpiryStatus.soon)})',
                selected: _filter == _ExpiryFilter.expiring,
                selectedColor: ThemeColors.warning(context),
                onTap: () =>
                    setState(() => _filter = _ExpiryFilter.expiring),
              ),
              NeuChip(
                label: 'Expired (${_count(_ExpiryStatus.expired)})',
                selected: _filter == _ExpiryFilter.expired,
                selectedColor: ThemeColors.error(context),
                onTap: () => setState(() => _filter = _ExpiryFilter.expired),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList(InventoryState state) {
    if (_items == null) {
      if (state is InventoryError) {
        return NeuEmptyState(
          icon: Icons.error_outline_rounded,
          svgAsset: SvgIcons.error,
          title: 'Could not load the inventory',
          message: state.failure.message,
          actionLabel: 'Retry',
          onAction: _reload,
        );
      }
      return const NeuSkeletonList();
    }

    final items = _visible;
    if (items.isEmpty && _filter != _ExpiryFilter.all) {
      return NeuEmptyState(
        icon: Icons.event_available_rounded,
        svgAsset: SvgIcons.inventory,
        title: _filter == _ExpiryFilter.expired
            ? 'No expired medicines'
            : 'Nothing expires in the next $_soonDays days',
        message: 'Medicines without an expiry date are not listed here.',
      );
    }
    if (items.isEmpty) {
      return _query.isNotEmpty
          ? NeuEmptyState(
              icon: Icons.search_off_rounded,
              svgAsset: SvgIcons.searchOff,
              title: 'No match for "$_query"',
              message: 'Check the spelling, or tap Add stock to add it.',
            )
          : NeuEmptyState(
              icon: Icons.inventory_2_rounded,
              svgAsset: SvgIcons.inventory,
              title: 'No medicines yet',
              message:
                  'Tap Add stock, or scan a medicine box or a supplier '
                  'receipt.',
              actionLabel: 'Go to Scan',
              onAction: () => context.go(Routes.staffScanning),
            );
    }

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _StockCard(
          item: items[index],
          batches: _batchesOf(items[index]),
          onEdit: () => _edit(items[index]),
        ),
      ),
    );
  }

  void _reload() =>
      context.read<InventoryBloc>().add(const LoadInventoryItems());

  /// Opens the Add stock form; [item] prefills it for a restock.
  Future<void> _addStock([InventoryItem? item]) async {
    final result = await NeuBottomSheet.show<_AddStockResult>(
      context: context,
      child: _AddStockSheet(item: item),
    );
    if (result == null || !mounted) return;
    final userId = _userId;
    if (userId == null) {
      NeuToast.error(context, 'Sign in again to add stock');
      return;
    }
    context.read<InventoryBloc>().add(
      ReceiveStock(
        lines: [result.line],
        performedBy: userId,
        supplier: result.supplier,
      ),
    );
  }

  Future<void> _edit(InventoryItem item) async {
    final result = await NeuBottomSheet.show<_EditResult>(
      context: context,
      child: _EditStockSheet(item: item, batches: _batchesOf(item)),
    );
    if (result == null || !mounted) return;
    if (result.action == _EditAction.addStock) {
      await _addStock(item);
      return;
    }

    final userId = _userId;
    if (userId == null) {
      NeuToast.error(context, 'Sign in again to edit stock');
      return;
    }
    final bloc = context.read<InventoryBloc>();
    switch (result.action) {
      case _EditAction.save:
        bloc.add(
          EditStockItem(
            item: item,
            name: result.name,
            takeOut: result.takeOut,
            performedBy: userId,
          ),
        );
      case _EditAction.outOfStock:
        bloc.add(MarkOutOfStock(item: item, performedBy: userId));
      case _EditAction.changeExpiry:
        bloc.add(
          UpdateBatchExpiry(
            batch: result.batch!,
            expiresAt: result.expiresAt,
            performedBy: userId,
          ),
        );
      case _EditAction.addStock:
        break;
      case _EditAction.remove:
        final confirmed = await NeuConfirmDialog.show(
          context: context,
          title: 'Remove ${item.name}?',
          message:
              'It disappears from the inventory. Its stock history is kept.',
          confirmText: 'Remove',
          cancelText: 'Cancel',
        );
        if (confirmed == true && item.id != null) {
          bloc.add(ArchiveInventoryItem(item.id!));
        }
    }
  }
}

/// One medicine: name, what is left, its nearest expiry, and an Edit button.
class _StockCard extends StatelessWidget {
  final InventoryItem item;

  /// Stocked batches, the one expiring soonest first.
  final List<InventoryBatch> batches;
  final VoidCallback onEdit;

  const _StockCard({
    required this.item,
    required this.batches,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final out = item.isOutOfStock;
    final low = !out && item.isLowStock && item.minStock > 0;
    final stockColor = out
        ? ThemeColors.error(context)
        : low
        ? ThemeColors.warning(context)
        : ThemeColors.textPrimary(context);

    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(10),
            borderRadius: NeuTokens.radiusSm,
            color: ThemeColors.primary(context).withValues(alpha: 0.1),
            child: NeuSvgIcon(SvgIcons.medication, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ThemeColors.textPrimary(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${_qty(item.currentStock)} ${item.unit}',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: stockColor,
                      ),
                    ),
                    if (out || low) ...[
                      const SizedBox(width: 8),
                      NeuStatusBadge(
                        label: out ? 'Out of stock' : 'Low',
                        tone: out ? NeuStatusTone.danger : NeuStatusTone.warning,
                        compact: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                _ExpiryLine(batches: batches),
              ],
            ),
          ),
          const SizedBox(width: 8),
          NeuButton(
            text: 'Edit',
            variant: NeuButtonVariant.secondary,
            icon: Icons.edit_rounded,
            svgAsset: SvgIcons.edit,
            size: NeuButtonSize.medium,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

enum _EditAction { save, outOfStock, remove, changeExpiry, addStock }

/// What the edit sheet asked for; the page sends it to the bloc.
class _EditResult {
  final _EditAction action;
  final String name;
  final double takeOut;

  /// For [_EditAction.changeExpiry]: the batch and its new date (null
  /// clears the date).
  final InventoryBatch? batch;
  final DateTime? expiresAt;

  const _EditResult(
    this.action, {
    this.name = '',
    this.takeOut = 0,
    this.batch,
    this.expiresAt,
  });
}

/// Rename a medicine, take some out, restock it, correct a batch's expiry
/// date, or mark it out of stock.
class _EditStockSheet extends StatefulWidget {
  final InventoryItem item;

  /// Stocked batches, the one expiring soonest first.
  final List<InventoryBatch> batches;

  const _EditStockSheet({required this.item, required this.batches});

  @override
  State<_EditStockSheet> createState() => _EditStockSheetState();
}

class _EditStockSheetState extends State<_EditStockSheet> {
  late final _name = TextEditingController(text: widget.item.name);
  final _takeOut = TextEditingController(text: '0');
  String? _nameError;
  String? _takeOutError;

  InventoryItem get _item => widget.item;

  @override
  void dispose() {
    _name.dispose();
    _takeOut.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_takeOut.text.trim()) ?? 0;

  void _step(double by) {
    final next = (_amount + by).clamp(0, _item.currentStock).toDouble();
    setState(() {
      _takeOut.text = _qty(next);
      _takeOutError = null;
    });
  }

  Future<void> _changeExpiry(InventoryBatch batch) async {
    final picked = await _pickExpiryDate(context, batch.expiresAt);
    if (picked == null || !mounted) return;
    Navigator.pop(
      context,
      _EditResult(
        _EditAction.changeExpiry,
        batch: batch,
        expiresAt: picked.clear ? null : picked.date,
      ),
    );
  }

  void _save() {
    final name = _name.text.trim();
    final amount = double.tryParse(_takeOut.text.trim());
    setState(() {
      _nameError = name.isEmpty ? 'Enter the medicine name' : null;
      _takeOutError = amount == null || amount < 0
          ? 'Enter a number, 0 or more'
          : amount > _item.currentStock
          ? 'Only ${_qty(_item.currentStock)} ${_item.unit} in stock'
          : null;
    });
    if (_nameError != null || _takeOutError != null) return;
    if (name == _item.name && amount == 0) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(
      context,
      _EditResult(_EditAction.save, name: name, takeOut: amount!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final left = (_item.currentStock - _amount).clamp(0, double.infinity);
    return Padding(
      // Keep the fields above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit medicine',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: ThemeColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'In stock: ${_qty(_item.currentStock)} ${_item.unit}',
            style: AppTextStyles.bodySmall.copyWith(
              color: ThemeColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 20),
          NeuTextField(
            label: 'Name',
            controller: _name,
            error: _nameError,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _nameError = null),
          ),
          const SizedBox(height: 16),
          Text(
            'Take out',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeuIconButton(
                icon: Icons.remove_rounded,
                svgAsset: SvgIcons.remove,
                onPressed: _amount > 0 ? () => _step(-1) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeuTextField(
                  controller: _takeOut,
                  error: _takeOutError,
                  helper:
                      '${_qty(left.toDouble())} ${_item.unit} left after',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [DecimalInputFormatter.stockQuantity],
                  onChanged: (_) => setState(() => _takeOutError = null),
                ),
              ),
              const SizedBox(width: 12),
              NeuIconButton(
                icon: Icons.add_rounded,
                svgAsset: SvgIcons.add,
                onPressed: _amount < _item.currentStock ? () => _step(1) : null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          NeuButton(
            text: 'Save',
            icon: Icons.save_rounded,
            svgAsset: SvgIcons.save,
            onPressed: _save,
            expanded: true,
          ),
          const SizedBox(height: 20),
          Text(
            'Batches and expiry dates',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.batches.isEmpty)
            Text(
              'No stock left. Add stock to record a new batch.',
              style: AppTextStyles.bodySmall.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
            ),
          for (final batch in widget.batches)
            _BatchRow(
              batch: batch,
              unit: _item.unit,
              onChangeExpiry: () => _changeExpiry(batch),
            ),
          const SizedBox(height: 12),
          NeuButton(
            text: 'Add stock (restock)',
            variant: NeuButtonVariant.secondary,
            icon: Icons.add_rounded,
            svgAsset: SvgIcons.add,
            onPressed: () => Navigator.pop(
              context,
              const _EditResult(_EditAction.addStock),
            ),
            expanded: true,
          ),
          const SizedBox(height: 12),
          NeuButton(
            text: 'Mark out of stock',
            variant: NeuButtonVariant.outline,
            icon: Icons.remove_shopping_cart_rounded,
            svgAsset: SvgIcons.alert,
            isDisabled: _item.isOutOfStock,
            onPressed: () => Navigator.pop(
              context,
              const _EditResult(_EditAction.outOfStock),
            ),
            expanded: true,
          ),
          const SizedBox(height: 12),
          NeuButton(
            text: 'Remove from inventory',
            variant: NeuButtonVariant.destructive,
            icon: Icons.delete_outline_rounded,
            svgAsset: SvgIcons.delete,
            onPressed: () =>
                Navigator.pop(context, const _EditResult(_EditAction.remove)),
            expanded: true,
          ),
        ],
      ),
    );
  }
}

/// One stocked batch in the edit sheet: lot, amount, expiry, and a
/// button to correct the expiry date.
class _BatchRow extends StatelessWidget {
  final InventoryBatch batch;
  final String unit;
  final VoidCallback onChangeExpiry;

  const _BatchRow({
    required this.batch,
    required this.unit,
    required this.onChangeExpiry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lot ${batch.batchNumber} · ${_qty(batch.quantity)} $unit',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.textPrimary(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                _ExpiryLine(batches: [batch]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          NeuButton(
            text: batch.expiresAt == null ? 'Set expiry' : 'Change',
            variant: NeuButtonVariant.outline,
            size: NeuButtonSize.small,
            onPressed: onChangeExpiry,
          ),
        ],
      ),
    );
  }
}

/// The nearest expiry of [batches] (sorted soonest first), coloured by how
/// close it is.
class _ExpiryLine extends StatelessWidget {
  final List<InventoryBatch> batches;

  const _ExpiryLine({required this.batches});

  @override
  Widget build(BuildContext context) {
    final dated = batches.where((b) => b.expiresAt != null).toList();
    final status = _expiryStatus(batches);
    final color = switch (status) {
      _ExpiryStatus.expired => ThemeColors.error(context),
      _ExpiryStatus.soon => ThemeColors.warning(context),
      _ => ThemeColors.textSecondary(context),
    };
    final label = dated.isEmpty
        ? 'No expiry date recorded'
        : switch (status) {
            _ExpiryStatus.expired =>
              'Expired ${_dateLabel(dated.first.expiresAt!)}',
            _ => 'Expires ${_dateLabel(dated.first.expiresAt!)}',
          };
    return Row(
      children: [
        Icon(Icons.event_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: status == _ExpiryStatus.ok
                  ? FontWeight.w400
                  : FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (status == _ExpiryStatus.soon || status == _ExpiryStatus.expired)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: NeuStatusBadge(
              label: status == _ExpiryStatus.expired
                  ? 'Expired'
                  : 'Expires soon',
              tone: status == _ExpiryStatus.expired
                  ? NeuStatusTone.danger
                  : NeuStatusTone.warning,
              compact: true,
            ),
          ),
      ],
    );
  }
}

/// What the Add stock form returns.
class _AddStockResult {
  final StockLine line;
  final String? supplier;

  const _AddStockResult(this.line, this.supplier);
}

/// Add a new medicine, or restock one, by hand: name, amount, unit, lot,
/// expiry date and supplier. A name that matches a stocked medicine adds a
/// new batch to it instead of creating a second item.
class _AddStockSheet extends StatefulWidget {
  /// The medicine being restocked, or null for a new one.
  final InventoryItem? item;

  const _AddStockSheet({this.item});

  @override
  State<_AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<_AddStockSheet> {
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  final _quantity = TextEditingController();
  late final _unit = TextEditingController(text: widget.item?.unit ?? 'pcs');
  final _lot = TextEditingController();
  late final _supplier = TextEditingController(
    text: widget.item?.supplier ?? '',
  );
  DateTime? _expiresAt;
  String? _nameError;
  String? _quantityError;
  String? _unitError;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _unit.dispose();
    _lot.dispose();
    _supplier.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await _pickExpiryDate(context, _expiresAt);
    if (picked == null || !mounted) return;
    setState(() => _expiresAt = picked.clear ? null : picked.date);
  }

  void _save() {
    final name = _name.text.trim();
    final quantity = double.tryParse(_quantity.text.trim());
    final unit = _unit.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'Enter the medicine name' : null;
      _quantityError = quantity == null || quantity <= 0
          ? 'Enter an amount more than 0'
          : null;
      _unitError = unit.isEmpty ? 'Enter a unit, for example pcs' : null;
    });
    if (_nameError != null || _quantityError != null || _unitError != null) {
      return;
    }
    final lot = _lot.text.trim();
    final supplier = _supplier.text.trim();
    Navigator.pop(
      context,
      _AddStockResult(
        StockLine(
          name: name,
          quantity: quantity!,
          unit: unit,
          lot: lot.isEmpty ? null : lot,
          expiresAt: _expiresAt,
        ),
        supplier.isEmpty ? null : supplier,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restock = widget.item != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            restock ? 'Restock ${widget.item!.name}' : 'Add stock',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: ThemeColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            restock
                ? 'In stock: ${_qty(widget.item!.currentStock)} '
                      '${widget.item!.unit}. The new amount is added as a '
                      'new batch.'
                : 'A name that is already in stock is restocked, not added '
                      'twice.',
            style: AppTextStyles.bodySmall.copyWith(
              color: ThemeColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 20),
          NeuTextField(
            label: 'Medicine name',
            controller: _name,
            error: _nameError,
            enabled: !restock,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _nameError = null),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: NeuTextField(
                  label: 'Amount',
                  controller: _quantity,
                  error: _quantityError,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [DecimalInputFormatter.stockQuantity],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _quantityError = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: NeuTextField(
                  label: 'Unit',
                  controller: _unit,
                  error: _unitError,
                  enabled: !restock,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _unitError = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NeuTextField(
            label: 'Lot / batch number (optional)',
            controller: _lot,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          NeuTextField(
            label: 'Supplier (optional)',
            controller: _supplier,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          NeuButton(
            text: _expiresAt == null
                ? 'Set expiry date'
                : 'Expiry: ${_dateLabel(_expiresAt!)}',
            variant: NeuButtonVariant.outline,
            icon: Icons.event_rounded,
            onPressed: _pickExpiry,
            expanded: true,
          ),
          const SizedBox(height: 24),
          NeuButton(
            text: restock ? 'Add to stock' : 'Save medicine',
            icon: Icons.save_rounded,
            svgAsset: SvgIcons.save,
            onPressed: _save,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

/// Not logged in view
class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: NeuContainer(
                  borderRadius: 80,
                  variant: NeuVariant.raised,
                  color: ThemeColors.primary(context),
                  boxShadow: NeuShadow.color(
                    context,
                    ThemeColors.primary(context),
                    blur: 24,
                    opacity: 0.35,
                  ),
                  child: NeuSvgIcon(SvgIcons.inventory, size: 80),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Please log in to manage inventory',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryOnDark
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to access inventory management',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryOnDark
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              NeuButton(
                text: 'Log In',
                onPressed: () => context.go('/login'),
                icon: Icons.login_rounded,
                svgAsset: SvgIcons.login,
                size: NeuButtonSize.medium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Access denied view for pet owners
class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: NeuContainer(
                  borderRadius: 80,
                  variant: NeuVariant.raised,
                  color: ThemeColors.error(context),
                  boxShadow: NeuShadow.color(
                    context,
                    ThemeColors.error(context),
                    blur: 24,
                    opacity: 0.35,
                  ),
                  child: NeuSvgIcon(SvgIcons.block, size: 80),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Access Denied',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.error(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Only veterinarians and clinic staff can manage inventory.\n\nThis feature is for clinic operations only.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryOnDark
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              NeuButton(
                text: 'Go Back',
                onPressed: () => context.pop(),
                icon: Icons.arrow_back_rounded,
                svgAsset: SvgIcons.back,
                variant: NeuButtonVariant.secondary,
                size: NeuButtonSize.medium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A stock amount as typed: `10`, `2.5`. No thousands separator, so the
/// take-out field can parse it back.
String _qty(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');

/// How many days ahead counts as "expiring soon".
const int _soonDays = 30;

enum _ExpiryFilter { all, expiring, expired }

enum _ExpiryStatus { none, ok, soon, expired }

/// The most urgent expiry state among [batches]: expired beats expiring
/// soon beats a later date. Batches without a date are ignored.
_ExpiryStatus _expiryStatus(List<InventoryBatch> batches) {
  final today = DateUtils.dateOnly(DateTime.now());
  final horizon = today.add(const Duration(days: _soonDays));
  var status = _ExpiryStatus.none;
  for (final batch in batches) {
    final date = batch.expiresAt;
    if (date == null) continue;
    final day = DateUtils.dateOnly(date);
    if (day.isBefore(today)) return _ExpiryStatus.expired;
    if (!day.isAfter(horizon)) {
      status = _ExpiryStatus.soon;
    } else if (status == _ExpiryStatus.none) {
      status = _ExpiryStatus.ok;
    }
  }
  return status;
}

String _dateLabel(DateTime date) => DateFormat('MMM d, y').format(date);

/// Result of the expiry picker: a date, or a request to clear it.
typedef _PickedExpiry = ({DateTime? date, bool clear});

/// Asks for an expiry date. Returns null when cancelled. When [current] is
/// set, a "No expiry date" choice lets the clinic clear a wrong date.
Future<_PickedExpiry?> _pickExpiryDate(
  BuildContext context,
  DateTime? current,
) async {
  if (current != null) {
    final clear = await NeuConfirmDialog.show(
      context: context,
      title: 'Change expiry date',
      message: 'Current expiry: ${_dateLabel(current)}.',
      confirmText: 'Pick a new date',
      cancelText: 'Remove the date',
      confirmVariant: NeuButtonVariant.primary,
    );
    if (clear == false) return (date: null, clear: true);
    if (clear == null) return null;
    if (!context.mounted) return null;
  }
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: current ?? now.add(const Duration(days: 365)),
    firstDate: DateTime(now.year - 5),
    lastDate: DateTime(now.year + 15),
    helpText: 'Expiry date',
  );
  if (date == null) return null;
  return (date: date, clear: false);
}
