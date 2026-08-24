import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../widgets/effects/glass_container.dart';
import '../../widgets/effects/floating_animation.dart';

/// CarePaw empty state widget with premium styling.
///
/// Provides a consistent way to display empty states across the app
/// with illustrations, messages, and optional actions.
class CpEmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;
  final Widget? customIcon;
  final EdgeInsetsGeometry? padding;
  final bool animate;

  const CpEmptyState({
    super.key,
    this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconSize = 64,
    this.customIcon,
    this.padding,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon/Illustration
            if (customIcon != null)
              customIcon!
            else
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                      (iconColor ?? AppColors.primary).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.inbox_outlined,
                  size: iconSize * 0.5,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
            const SizedBox(height: 24),
            // Title
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Message
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  textStyle: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (animate) {
      return content
          .animate()
          .fadeIn(duration: 600.ms, curve: Curves.easeOut)
          .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut);
    }

    return content;
  }
}

/// Specialized empty states for common scenarios
class CpEmptyStates {
  /// No pets yet
  static Widget noPets({VoidCallback? onAdd}) => CpEmptyState(
    icon: Icons.pets_outlined,
    title: 'No Pets Yet',
    message: 'Add your first pet to start tracking their health and appointments.',
    actionLabel: 'Add Pet',
    onAction: onAdd,
    iconColor: AppColors.primary,
  );

  /// No appointments
  static Widget noAppointments({VoidCallback? onBook}) => CpEmptyState(
    icon: Icons.calendar_month_outlined,
    title: 'No Appointments',
    message: 'Book an appointment to see your upcoming visits here.',
    actionLabel: 'Book Appointment',
    onAction: onBook,
    iconColor: AppColors.primary,
  );

  /// No queue
  static Widget noQueue() => CpEmptyState(
    icon: Icons.queue_outlined,
    title: 'Queue is Empty',
    message: 'No patients waiting. Check in a patient to start the queue.',
    iconColor: AppColors.info,
  );

  /// No medical records
  static Widget noRecords({VoidCallback? onAdd}) => CpEmptyState(
    icon: Icons.medical_information_outlined,
    title: 'No Medical Records',
    message: 'Medical records from vet visits will appear here.',
    actionLabel: 'Add Record',
    onAction: onAdd,
    iconColor: AppColors.success,
  );

  /// No inventory items
  static Widget noInventory({VoidCallback? onAdd}) => CpEmptyState(
    icon: Icons.inventory_2_outlined,
    title: 'No Medicines in Inventory',
    message: 'Add your first medicine to start tracking stock levels and expiration dates.',
    actionLabel: 'Add Medicine',
    onAction: onAdd,
    iconColor: AppColors.primary,
  );

  /// No scans
  static Widget noScans({VoidCallback? onScan}) => CpEmptyState(
    icon: Icons.document_scanner_outlined,
    title: 'No Scans Yet',
    message: 'Scan receipts, medicine boxes, or prescriptions to extract information.',
    actionLabel: 'Start Scanning',
    onAction: onScan,
    iconColor: AppColors.tertiary,
  );

  /// No notifications
  static Widget noNotifications() => CpEmptyState(
    icon: Icons.notifications_none_rounded,
    title: 'No Notifications',
    message: 'You\'re all caught up! New notifications will appear here.',
    iconColor: AppColors.info,
  );

  /// Search no results
  static Widget noSearchResults({String? query}) => CpEmptyState(
    icon: Icons.search_off_rounded,
    title: 'No Results Found',
    message: query != null
        ? 'No results for "$query". Try adjusting your search.'
        : 'No results match your search criteria.',
    iconColor: AppColors.textTertiary,
  );

  /// Generic error
  static Widget error({
    required String message,
    VoidCallback? onRetry,
  }) => CpEmptyState(
    icon: Icons.error_outline_rounded,
    title: 'Something Went Wrong',
    message: message,
    actionLabel: 'Try Again',
    onAction: onRetry,
    iconColor: AppColors.error,
  );

  /// Offline
  static Widget offline({VoidCallback? onRetry}) => CpEmptyState(
    icon: Icons.wifi_off_rounded,
    title: 'You\'re Offline',
    message: 'Check your connection and try again. Some features may be limited.',
    actionLabel: 'Retry',
    onAction: onRetry,
    iconColor: AppColors.warning,
  );
}