import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/notifications/presentation/notification_target.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart'
    as domain;
import 'package:carepaw/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_event.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/utils/formatters.dart';

/// Notification detail page with the CarePaw surface system
class NotificationDetailPage extends StatefulWidget {
  final domain.Notification notification;

  const NotificationDetailPage({super.key, required this.notification});

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final typeColor = _getTypeColor(notification.type);

    return Scaffold(
      backgroundColor: _isDark
          ? AppColors.backgroundDark
          : AppColors.background,
      appBar: _buildAppBar(notification, typeColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          children: [
            _buildNotificationCard(notification, typeColor),
            const SizedBox(height: 16),
            _buildMetaSection(notification),
            const SizedBox(height: 24),
            _buildOpenTargetButton(notification),
            _buildActionButtons(notification),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    domain.Notification notification,
    Color typeColor,
  ) {
    return AppBar(
      toolbarHeight: 88,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 64,
      titleSpacing: 0,
      leading: NeuIconButton(
        plain: true,
        icon: Icons.arrow_back_rounded,
        svgAsset: SvgIcons.back,
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Notification',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: _isDark
                  ? AppColors.textPrimaryOnDark
                  : AppColors.textPrimary,
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
              notification.type.displayName,
              style: AppTextStyles.labelSmall.copyWith(
                color: typeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (!notification.isRead)
          NeuIconButton(
            plain: true,
            icon: Icons.mark_email_read_rounded,
            svgAsset: SvgIcons.email,
            onPressed: () {
              context.read<NotificationBloc>().add(
                MarkAsRead(notification.id!),
              );
              Navigator.pop(context, true);
            },
            tooltip: 'Mark as Read',
            color: typeColor,
          ),
        const SizedBox(width: 8),
        NeuIconButton(
          plain: true,
          icon: Icons.delete_outline_rounded,
          svgAsset: SvgIcons.delete,
          onPressed: _showDeleteConfirmation,
          tooltip: 'Delete',
          color: ThemeColors.error(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNotificationCard(
    domain.Notification notification,
    Color typeColor,
  ) {
    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              NeuAvatar(
                radius: 22,
                svgAsset: _getTypeSvg(notification.type),
                backgroundColor: typeColor,
                foregroundColor: AppColors.textOnPrimary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _isDark
                            ? AppColors.textPrimaryOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!notification.isRead) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeColors.primary(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NeuSvgIcon(SvgIcons.sparkles, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Unread',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: ThemeColors.onPrimary(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Divider
          Divider(
            height: 1,
            color: _isDark ? AppColors.dividerDark : AppColors.divider,
          ),
          const SizedBox(height: 20),

          // Body
          Text(
            notification.message,
            style: AppTextStyles.bodyLarge.copyWith(
              color: _isDark
                  ? AppColors.textPrimaryOnDark
                  : AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaSection(domain.Notification notification) {
    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuSvgIcon(SvgIcons.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Details',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _isDark
                      ? AppColors.textPrimaryOnDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetaRow('Created', formatDateTime(notification.createdAt)),
          if (notification.readAt != null)
            _buildMetaRow('Read At', formatDateTime(notification.readAt!)),
          _buildMetaRow(
            'Notification ID',
            notification.id?.toString() ?? 'N/A',
          ),
          _buildMetaRow('Type', notification.type.displayName),
          _buildMetaRow('Status', notification.isRead ? 'Read' : 'Unread'),
          if (notification.referenceType != null)
            _buildMetaRow(
              'Reference',
              '${notification.referenceType}: ${notification.referenceId}',
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
                color: _isDark
                    ? AppColors.textSecondaryOnDark
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: _isDark
                    ? AppColors.textPrimaryOnDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the appointment/queue screen this notification is about.
  /// Renders nothing for types with no related screen.
  Widget _buildOpenTargetButton(domain.Notification notification) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final route = notificationTargetRoute(
      notification.type,
      referenceId: notification.referenceId,
      role: authState.user.role,
    );
    if (route == null) return const SizedBox.shrink();

    final isAppointment =
        notification.type == domain.NotificationType.appointmentReminder;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeuButton(
        text: isAppointment ? 'View Appointment' : 'View Queue',
        variant: NeuButtonVariant.primary,
        icon: isAppointment
            ? Icons.event_rounded
            : Icons.format_list_numbered_rounded,
        svgAsset: isAppointment ? SvgIcons.calendar : SvgIcons.queue,
        onPressed: () {
          if (!notification.isRead && notification.id != null) {
            context.read<NotificationBloc>().add(MarkAsRead(notification.id!));
          }
          context.go(route);
        },
        expanded: true,
      ),
    );
  }

  Widget _buildActionButtons(domain.Notification notification) {
    final isUnread = !notification.isRead;

    return Row(
      children: [
        if (isUnread)
          Expanded(
            child: NeuButton(
              text: 'Mark as Read',
              variant: NeuButtonVariant.primary,
              icon: Icons.mark_email_read_rounded,
              svgAsset: SvgIcons.email,
              onPressed: () {
                context.read<NotificationBloc>().add(
                  MarkAsRead(notification.id!),
                );
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
              svgAsset: SvgIcons.back,
              onPressed: () => Navigator.pop(context),
              expanded: true,
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: NeuButton(
            text: 'Delete',
            variant: NeuButtonVariant.outline,
            icon: Icons.delete_outline_rounded,
            svgAsset: SvgIcons.delete,
            onPressed: _showDeleteConfirmation,
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
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NotificationBloc>().add(
                DeleteNotification(widget.notification.id!),
              );
              Navigator.pop(context, true);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: ThemeColors.error(context)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.appointmentReminder:
        return ThemeColors.primary(context);
      case domain.NotificationType.queueUpdate:
        return _isDark ? AppColors.warningOnDark : AppColors.warning;
      case domain.NotificationType.prescriptionReady:
        return AppColors.categorySupply;
      case domain.NotificationType.inventoryLow:
        return _isDark ? AppColors.successOnDark : AppColors.success;
      case domain.NotificationType.system:
        return _isDark
            ? AppColors.textSecondaryOnDark
            : AppColors.textSecondary;
    }
  }

  String _getTypeSvg(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.appointmentReminder:
        return SvgIcons.calendar;
      case domain.NotificationType.queueUpdate:
        return SvgIcons.queue;
      case domain.NotificationType.prescriptionReady:
        return SvgIcons.medication;
      case domain.NotificationType.inventoryLow:
        return SvgIcons.inventory;
      case domain.NotificationType.system:
        return SvgIcons.settings;
    }
  }
}
