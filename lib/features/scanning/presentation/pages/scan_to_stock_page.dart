import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/core/utils/formatters.dart';
import 'package:carepaw/core/widgets/neomorphism/index.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:carepaw/features/inventory/presentation/widgets/inventory_detail_sheets.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/features/scanning/domain/services/scan_text_parser.dart';

/// Turns a confirmed medicine-box scan into a stock batch.
///
/// The person picks which medicine the box belongs to (the one whose name
/// matches the scan is listed first), then the add-batch form opens with the
/// scanned lot and expiry filled in. They enter the quantity and can correct
/// anything before saving, so OCR output never reaches stock unchecked.
class ScanToStockPage extends StatelessWidget {
  final ScanRecord record;

  const ScanToStockPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InventoryBloc(
        itemRepository: getIt<InventoryItemRepository>(),
        batchRepository: getIt<InventoryBatchRepository>(),
        transactionRepository: getIt<InventoryTransactionRepository>(),
      )..add(const LoadInventoryItems()),
      child: _ScanToStockView(
        scanRecordId: record.id,
        fields: ScanTextParser.fromDisplay(record.extractedData),
      ),
    );
  }
}

class _ScanToStockView extends StatelessWidget {
  final int? scanRecordId;
  final Map<String, String> fields;

  const _ScanToStockView({required this.scanRecordId, required this.fields});

  String? get _name => fields['Name'];
  String? get _lot => fields['Lot / Batch'];
  String? get _expiry => fields['Expiry'];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryOperationSuccess) {
          NeuToast.success(context, 'Batch added to stock');
          Navigator.pop(context, true);
        } else if (state is InventoryError) {
          NeuToast.error(context, state.failure.message);
        }
      },
      buildWhen: (_, state) =>
          state is InventoryItemsLoaded ||
          state is InventoryLoading ||
          state is InventoryError,
      builder: (context, state) {
        return NeuPage(
          title: 'Add to Stock',
          subtitle: 'Pick the medicine this box belongs to',
          scrollable: false,
          body: switch (state) {
            InventoryItemsLoaded(:final items) => _buildList(context, items),
            InventoryError() => NeuEmptyState(
              icon: Icons.error_outline_rounded,
              svgAsset: SvgIcons.error,
              title: 'Could not load stock',
              message: 'Check your connection, then try again.',
              actionLabel: 'Retry',
              onAction: () => context.read<InventoryBloc>().add(
                const LoadInventoryItems(),
              ),
            ),
            _ => const NeuSkeletonList(),
          },
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<InventoryItem> items) {
    if (items.isEmpty) {
      return NeuEmptyState(
        icon: Icons.inventory_2_outlined,
        svgAsset: SvgIcons.inventory,
        title: 'No medicines yet',
        message: 'Add this medicine in Stock first, then add the scanned '
            'batch to it.',
      );
    }

    final sorted = [...items]
      ..sort((a, b) => _matchScore(b).compareTo(_matchScore(a)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        NeuTokens.pagePadding,
        NeuTokens.spaceXs,
        NeuTokens.pagePadding,
        NeuTokens.spaceXxl,
      ),
      children: [
        _buildScannedCard(context),
        const SizedBox(height: NeuTokens.spaceLg),
        for (final item in sorted) ...[
          _buildItemCard(context, item, isMatch: _matchScore(item) > 0),
          const SizedBox(height: NeuTokens.spaceSm),
        ],
      ],
    );
  }

  /// How well [item] matches the scanned name: shared words, case-blind.
  int _matchScore(InventoryItem item) {
    final scanned = _words(_name);
    if (scanned.isEmpty) return 0;
    return _words(item.name).intersection(scanned).length;
  }

  static Set<String> _words(String? text) => (text ?? '')
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length >= 3)
      .toSet();

  Widget _buildScannedCard(BuildContext context) {
    Widget row(String label, String? value) => Padding(
      padding: const EdgeInsets.only(top: NeuTokens.spaceXs),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not found',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: value == null
                    ? ThemeColors.textTertiary(context)
                    : ThemeColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'From the scan',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: ThemeColors.textPrimary(context),
            ),
          ),
          row('Name', _name),
          row('Lot / Batch', _lot),
          row('Expiry', _expiry),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    InventoryItem item, {
    required bool isMatch,
  }) {
    return NeuCard(
      onTap: () => showAddBatchSheet(
        context,
        item: item,
        initialBatchNumber: _lot,
        initialExpiry: _expiry == null
            ? null
            : ScanTextParser.parseDate(_expiry!),
        scanRecordId: scanRecordId,
      ),
      child: Row(
        children: [
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
                ),
                const SizedBox(height: NeuTokens.spaceXxs),
                Text(
                  '${formatNumber(item.currentStock)} ${item.unit} in stock',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          if (isMatch)
            const NeuStatusBadge(
              label: 'Matches scan',
              tone: NeuStatusTone.success,
            ),
          const SizedBox(width: NeuTokens.spaceXs),
          NeuSvgIcon(SvgIcons.chevronRight, size: 20),
        ],
      ),
    );
  }
}
