import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_bloc.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_event.dart' as scan_event;
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(record, typeColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  _buildScanCard(record, typeColor, statusColor),
                  const SizedBox(height: 16),
                  _buildMetaSection(record),
                  if (record.rawOcrText != null) ...[
                    const SizedBox(height: 16),
                    _buildOcrSection(record),
                  ],
                  if (record.extractedData != null) ...[
                    const SizedBox(height: 16),
                    _buildExtractedDataSection(record),
                  ],
                  const SizedBox(height: 24),
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
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
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
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
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
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
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
          const SizedBox(height: 20),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.divider.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Confidence score
          if (record.confidenceScore != null) ...[
            Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  size: 20,
                  color: ThemeColors.textSecondary(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Confidence: ${(record.confidenceScore! * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: ThemeColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: record.confidenceScore,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                record.confidenceScore! >= 0.8
                    ? AppColors.success
                    : record.confidenceScore! >= 0.5
                        ? AppColors.warning
                        : AppColors.error,
              ),
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
            const SizedBox(height: 20),
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
              const SizedBox(width: 8),
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
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
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
              const SizedBox(width: 8),
              Text(
                'Details',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
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
              const SizedBox(width: 8),
              Text(
                'Raw OCR Text',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
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
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
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
              const SizedBox(width: 8),
              Text(
                'Extracted Data',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
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
      padding: const EdgeInsets.only(bottom: 8),
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan Record'),
        content: const Text('Are you sure you want to delete this scan record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ScanBloc>().add(scan_event.DeleteScanRecord(widget.record.id!));
              Navigator.pop(context, true);
            },
            child: Text('Delete',
                style: TextStyle(color: ThemeColors.error(context))),
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case ScanStatus.pending:
        return isDark ? AppColors.warningOnDark : AppColors.warning;
      case ScanStatus.confirmed:
        return isDark ? AppColors.successOnDark : AppColors.success;
      case ScanStatus.rejected:
        return isDark ? AppColors.errorOnDark : AppColors.error;
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
