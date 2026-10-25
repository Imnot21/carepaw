import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/utils/input_formatters.dart';
import 'package:carepaw/core/widgets/neomorphism/index.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_state.dart';

/// Inventory tab: search the medicines in stock and edit any of them.
///
/// Stock comes in through the Scan tab; this page takes it out.
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
      return words.every(name.contains);
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
      setState(() => _items = state.items);
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
          Text(
            'Inventory',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: ThemeColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Search a medicine, then tap Edit to take stock out',
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
    if (items.isEmpty) {
      return _query.isNotEmpty
          ? NeuEmptyState(
              icon: Icons.search_off_rounded,
              svgAsset: SvgIcons.searchOff,
              title: 'No match for "$_query"',
              message: 'Check the spelling, or scan the medicine to add it.',
            )
          : NeuEmptyState(
              icon: Icons.inventory_2_rounded,
              svgAsset: SvgIcons.inventory,
              title: 'No medicines yet',
              message:
                  'Scan a medicine box or a supplier receipt to add stock.',
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
          onEdit: () => _edit(items[index]),
        ),
      ),
    );
  }

  void _reload() =>
      context.read<InventoryBloc>().add(const LoadInventoryItems());

  Future<void> _edit(InventoryItem item) async {
    final result = await NeuBottomSheet.show<_EditResult>(
      context: context,
      child: _EditStockSheet(item: item),
    );
    if (result == null || !mounted) return;

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

/// One medicine: name, what is left, and an Edit button.
class _StockCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onEdit;

  const _StockCard({required this.item, required this.onEdit});

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

enum _EditAction { save, outOfStock, remove }

/// What the edit sheet asked for; the page sends it to the bloc.
class _EditResult {
  final _EditAction action;
  final String name;
  final double takeOut;

  const _EditResult(this.action, {this.name = '', this.takeOut = 0});
}

/// Rename a medicine, take some out, or mark it out of stock.
class _EditStockSheet extends StatefulWidget {
  final InventoryItem item;

  const _EditStockSheet({required this.item});

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
