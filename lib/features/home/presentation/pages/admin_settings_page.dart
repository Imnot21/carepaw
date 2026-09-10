import 'package:flutter/material.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/constants/app_constants.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';

/// Admin settings page - real app configuration values.
///
/// Displays the actual configuration constants that govern the system
/// (audit retention, queue timing, pagination defaults, OCR thresholds).
/// No fabricated metrics or fake counters - just the real config knobs.
class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                title: 'Audit Log',
                icon: Icons.receipt_long_outlined,
                items: [
                  _SettingItem('Retention', '${AppConstants.auditLogRetentionDays} days'),
                ],
              ),
              const SizedBox(height: 20),
              _buildSection(
                context,
                title: 'Queue',
                icon: Icons.queue_outlined,
                items: [
                  _SettingItem('Slot duration', '${AppConstants.estimatedTimePerAppointment} min'),
                  _SettingItem('Check-in window', '${AppConstants.checkInWindowMinutes} min before'),
                  _SettingItem('Late arrival', '${AppConstants.lateArrivalMinutes} min after scheduled'),
                ],
              ),
              const SizedBox(height: 20),
              _buildSection(
                context,
                title: 'Inventory',
                icon: Icons.inventory_2_outlined,
                items: [
                  _SettingItem('Low stock alert', 'Below ${AppConstants.lowStockThreshold} units'),
                  _SettingItem('Expiration warning', '${AppConstants.expirationWarningDays} days'),
                  _SettingItem('Critical expiration', '${AppConstants.criticalExpirationDays} days'),
                ],
              ),
              const SizedBox(height: 20),
              _buildSection(
                context,
                title: 'OCR',
                icon: Icons.document_scanner_outlined,
                items: [
                  _SettingItem('Min confidence', '${(AppConstants.ocrConfidenceThreshold * 100).round()}%'),
                  _SettingItem('Max image size', '${AppConstants.maxImageSizeBytes ~/ (1024 * 1024)} MB'),
                  _SettingItem('Formats', AppConstants.supportedImageFormats.join(', ')),
                ],
              ),
              const SizedBox(height: 20),
              _buildSection(
                context,
                title: 'Pagination',
                icon: Icons.format_list_numbered_outlined,
                items: [
                  _SettingItem('Default page size', '${AppConstants.defaultPageSize}'),
                  _SettingItem('Max page size', '${AppConstants.maxPageSize}'),
                ],
              ),
              const SizedBox(height: 20),
              _buildSection(
                context,
                title: 'Authentication',
                icon: Icons.lock_outline,
                items: [
                  _SettingItem('Max login attempts', '${AppConstants.maxLoginAttempts}'),
                  _SettingItem('Lockout duration', '${AppConstants.lockoutDurationMinutes} min'),
                  _SettingItem('Session timeout', '${AppConstants.sessionTimeoutHours} hours'),
                  _SettingItem('Password history', '${AppConstants.passwordHistoryCount}'),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required String title,
    required IconData icon,
    required List<_SettingItem> items,
  }) {
    final accent = ThemeColors.primary(context);
    return NeuCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuContainer(
                borderRadius: 10,
                padding: const EdgeInsets.all(8),
                variant: NeuVariant.flat,
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    items[i].label,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                Text(
                  items[i].value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ThemeColors.textSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (i < items.length - 1) ...[
              const SizedBox(height: 8),
              Divider(height: 1, color: ThemeColors.textSecondary(context).withValues(alpha: 0.2)),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _SettingItem {
  final String label;
  final String value;
  const _SettingItem(this.label, this.value);
}