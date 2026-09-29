import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_bloc.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_event.dart' as scan_event;
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/utils/formatters.dart';

/// Scan detail page with premium design
class ScanDetailPage extends StatefulWidget {
  final ScanRecord record;

  const ScanDetailPage({super.key, required this.record});

  @override
  State<ScanDetailPage> createState() => _ScanDetailPageState();
}

class _ScanDetailPageState extends State<ScanDetailPage> {
  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final typeColor = _getTypeColor(record.scanType);
    final statusColor = _getStatusColor(record.status);

    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(record, typeColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                children: [
                  _buildScanCard(record, typeColor, statusColor),
                  const SizedBox(height: 20),
                  _buildMetaSection(record),
                  if (record.rawOcrText != null) ...[
                    const SizedBox(height: 20),
                    _buildOcrSection(record),
                  ],
                  if (record.extractedData != null) ...[
                    const SizedBox(height: 20),
                    _buildExtractedDataSection(record),
                  ],
                  const SizedBox(height: 28),
                  _buildActionButtons(record, typeColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ScanRecord record, Color typeColor) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: NeuIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 64, bottom: 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan Detail',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: ThemeColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            NeuContainer(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              borderRadius: 10,
              variant: NeuVariant.flat,
              child: Text(
                record.scanType.displayName,
                style: AppTextStyles.labelSmall.copyWith(
                  color: typeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: NeuIconButton(
            icon: Icons.delete_outline_rounded,
            onPressed: _showDeleteConfirmation,
            color: ThemeColors.error(context),
            tooltip: 'Delete',
          ),
        ),
      ],
    );
  }

  Widget _buildScanCard(
    ScanRecord record,
    Color typeColor,
    Color statusColor,
  ) {
    return NeuCard(
      padding: const EdgeInsets.all(24),
      borderColor: typeColor.withValues(alpha: 0.2),
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and status
          Row(
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(14),
                borderRadius: 16,
                color: typeColor,
                child: Icon(
                  _getTypeIcon(record.scanType),
                  size: 28,
                  color: AppColors.textOnPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.scanType.displayName,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ThemeColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    NeuContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      borderRadius: 10,
                      variant: NeuVariant.flat,
                      borderColor: statusColor.withValues(alpha: 0.3),
                      borderWidth: 1,
                      child: Text(
                        record.status.displayName,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Divider
          SizedBox(
            height: 1,
            child: NeuContainer(
              padding: EdgeInsets.zero,
              borderRadius: 0.5,
              variant: NeuVariant.flat,
              boxShadow: NeuShadow.none,
              color: ThemeColors.border(context),
              child: const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 24),

          // Confidence score
          if (record.confidenceScore != null) ...[
            Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  size: 20,
                  color: ThemeColors.textSecondary(context),
                ),
                const SizedBox(width: 10),
                Text(
                  'Confidence: ${(record.confidenceScore! * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: ThemeColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            NeuProgress(
              value: record.confidenceScore!,
              height: 10,
              color: record.confidenceScore! >= 0.8
                  ? ThemeColors.success(context)
                  : record.confidenceScore! >= 0.5
                      ? ThemeColors.warning(context)
                      : ThemeColors.error(context),
            ),
            const SizedBox(height: 24),
          ],

          // Image path
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.image_rounded,
                size: 20,
                color: ThemeColors.textSecondary(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Image: ${record.imagePath}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ThemeColors.textSecondary(context),
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaSection(ScanRecord record) {
    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: ThemeColors.primary(context),
              ),
              const SizedBox(width: 10),
              Text(
                'Details',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetaRow('Created', formatDateTime(record.createdAt)),
          if (record.confirmedAt != null)
            _buildMetaRow('Confirmed At', formatDateTime(record.confirmedAt!)),
          _buildMetaRow('Scan ID', record.id?.toString() ?? 'N/A'),
          _buildMetaRow('Type', record.scanType.displayName),
          _buildMetaRow('Status', record.status.displayName),
        ],
      ),
    );
  }

  Widget _buildOcrSection(ScanRecord record) {
    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields_rounded,
                size: 20,
                color: ThemeColors.primary(context),
              ),
              const SizedBox(width: 10),
              Text(
                'Raw OCR Text',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NeuContainer(
            padding: const EdgeInsets.all(14),
            borderRadius: 12,
            variant: NeuVariant.inset,
            child: SingleChildScrollView(
              child: Text(
                record.rawOcrText!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: ThemeColors.textPrimary(context),
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedDataSection(ScanRecord record) {
    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.data_object_rounded,
                size: 20,
                color: ThemeColors.primary(context),
              ),
              const SizedBox(width: 10),
              Text(
                'Extracted Data',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NeuContainer(
            padding: const EdgeInsets.all(14),
            borderRadius: 12,
            variant: NeuVariant.inset,
            child: SingleChildScrollView(
              child: Text(
                record.extractedData!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: ThemeColors.textPrimary(context),
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: ThemeColors.textSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: ThemeColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ScanRecord record, Color typeColor) {
    final isPending = record.status == ScanStatus.pending;

    return Row(
      children: [
        if (isPending)
          Expanded(
            child: NeuButton(
              text: 'Confirm',
              variant: NeuButtonVariant.primary,
              icon: Icons.check_circle_rounded,
              onPressed: () {
                context.read<ScanBloc>().add(scan_event.ConfirmScanRecord(recordId: record.id!));
                Navigator.pop(context, true);
              },
              expanded: true,
            ),
          )
        else
          Expanded(
            child: NeuButton(
              text: 'Back to List',
              variant: NeuButtonVariant.secondary,
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
              expanded: true,
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: NeuButton(
            text: isPending ? 'Reject' : 'Delete',
            variant: NeuButtonVariant.outline,
            icon: isPending ? Icons.close_rounded : Icons.delete_outline_rounded,
            onPressed: () {
              if (isPending) {
                context.read<ScanBloc>().add(scan_event.RejectScanRecord(
                  recordId: record.id!,
                  reason: 'User rejected scan',
                ));
                Navigator.pop(context, true);
              } else {
                _showDeleteConfirmation();
              }
            },
            expanded: true,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: NeuCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete Scan Record',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: ThemeColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete this scan record? This action cannot be undone.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: NeuButton(
                      text: 'Cancel',
                      variant: NeuButtonVariant.outline,
                      size: NeuButtonSize.medium,
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeuButton(
                      text: 'Delete',
                      variant: NeuButtonVariant.destructive,
                      size: NeuButtonSize.medium,
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        context.read<ScanBloc>().add(scan_event.DeleteScanRecord(widget.record.id!));
                        Navigator.pop(context, true);
                      },
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

  Color _getTypeColor(ScanType type) {
    switch (type) {
      case ScanType.receipt:
        return const Color(0xFFF59E0B);
      case ScanType.medicineBox:
        return AppColors.categoryMedicine;
      case ScanType.prescription:
        return AppColors.categorySupply;
      case ScanType.labReport:
        return AppColors.categoryVaccine;
      case ScanType.other:
        return AppColors.secondary;
    }
  }

  Color _getStatusColor(ScanStatus status) {
    switch (status) {
      case ScanStatus.pending:
        return ThemeColors.warning(context);
      case ScanStatus.confirmed:
        return ThemeColors.success(context);
      case ScanStatus.rejected:
        return ThemeColors.error(context);
    }
  }

  IconData _getTypeIcon(ScanType type) {
    switch (type) {
      case ScanType.receipt:
        return Icons.receipt_rounded;
      case ScanType.medicineBox:
        return Icons.medication_rounded;
      case ScanType.prescription:
        return Icons.description_rounded;
      case ScanType.labReport:
        return Icons.science_rounded;
      case ScanType.other:
        return Icons.image_rounded;
    }
  }
}
