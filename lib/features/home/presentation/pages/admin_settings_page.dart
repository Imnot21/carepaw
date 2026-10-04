import 'package:flutter/material.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/app/theme/theme_colors.dart';
import 'package:carepaw/core/constants/app_constants.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_divider.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: ThemeColors.surface(context),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          NeuTokens.pagePadding,
          NeuTokens.spaceMd,
          NeuTokens.pagePadding,
          NeuTokens.spaceXl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: NeuTokens.maxContentWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                title: 'Audit log',
                icon: Icons.receipt_long_outlined,
                items: [
                  _SettingItem(
                    'Retention',
                    '${AppConstants.auditLogRetentionDays} days',
                  ),
                ],
              ),
              const SizedBox(height: NeuTokens.tightGap),
              _buildSection(
                context,
                title: 'Queue',
                icon: Icons.queue_outlined,
                items: [
                  _SettingItem(
                    'Slot duration',
                    '${AppConstants.estimatedTimePerAppointment} min',
                  ),
                  _SettingItem(
                    'Check-in window',
                    '${AppConstants.checkInWindowMinutes} min before',
                  ),
                  _SettingItem(
                    'Late arrival',
                    '${AppConstants.lateArrivalMinutes} min after scheduled',
                  ),
                ],
              ),
              const SizedBox(height: NeuTokens.tightGap),
              _buildSection(
                context,
                title: 'Inventory',
                icon: Icons.inventory_2_outlined,
                items: [
                  _SettingItem(
                    'Low stock alert',
                    'Below ${AppConstants.lowStockThreshold} units',
                  ),
                  _SettingItem(
                    'Expiration warning',
                    '${AppConstants.expirationWarningDays} days',
                  ),
                  _SettingItem(
                    'Critical expiration',
                    '${AppConstants.criticalExpirationDays} days',
                  ),
                ],
              ),
              const SizedBox(height: NeuTokens.tightGap),
              _buildSection(
                context,
                title: 'OCR',
                icon: Icons.document_scanner_outlined,
                items: [
                  _SettingItem(
                    'Min confidence',
                    '${(AppConstants.ocrConfidenceThreshold * 100).round()}%',
                  ),
                  _SettingItem(
                    'Max image size',
                    '${AppConstants.maxImageSizeBytes ~/ (1024 * 1024)} MB',
                  ),
                  _SettingItem(
                    'Formats',
                    AppConstants.supportedImageFormats.join(', '),
                  ),
                ],
              ),
              const SizedBox(height: NeuTokens.tightGap),
              _buildSection(
                context,
                title: 'Pagination',
                icon: Icons.format_list_numbered_outlined,
                items: [
                  _SettingItem(
                    'Default page size',
                    '${AppConstants.defaultPageSize}',
                  ),
                  _SettingItem('Max page size', '${AppConstants.maxPageSize}'),
                ],
              ),
              const SizedBox(height: NeuTokens.tightGap),
              _buildSection(
                context,
                title: 'Authentication',
                icon: Icons.lock_outline,
                items: [
                  _SettingItem(
                    'Max login attempts',
                    '${AppConstants.maxLoginAttempts}',
                  ),
                  _SettingItem(
                    'Lockout duration',
                    '${AppConstants.lockoutDurationMinutes} min',
                  ),
                  _SettingItem(
                    'Session timeout',
                    '${AppConstants.sessionTimeoutHours} hours',
                  ),
                  _SettingItem(
                    'Password history',
                    '${AppConstants.passwordHistoryCount}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_SettingItem> items,
  }) {
    final accent = ThemeColors.primary(context);
    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuContainer(
                variant: NeuVariant.pressed,
                borderRadius: NeuTokens.radiusSm,
                padding: const EdgeInsets.all(NeuTokens.spaceXs),
                child: Icon(icon, color: accent, size: NeuTokens.iconSm),
              ),
              const SizedBox(width: NeuTokens.spaceXs),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: NeuTokens.tightGap),
          for (var i = 0; i < items.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    items[i].label,
                    style: AppTextStyles.bodyMedium.subtleOf(
                      Theme.of(context).brightness,
                    ),
                  ),
                ),
                Text(
                  items[i].value,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (i < items.length - 1) ...[
              const SizedBox(height: NeuTokens.spaceXs),
              NeuDivider(),
              const SizedBox(height: NeuTokens.spaceXs),
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
