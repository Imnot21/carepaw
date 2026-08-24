import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart' as domain;
import 'package:carepaw/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_event.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/utils/formatters.dart';

/// Notification detail page with premium design
class NotificationDetailPage extends StatefulWidget {
  final domain.Notification notification;

  const NotificationDetailPage({super.key, required this.notification});

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final typeColor = _getTypeColor(notification.type);

    return Scaffold(
      body: AnimatedGradientBackground(
        colors: [
          typeColor.withValues(alpha: 0.08),
          AppColors.surface,
        ],
        child: CustomScrollView(
          slivers: [
            _buildAppBar(notification, typeColor),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      children: [
                        _buildNotificationCard(notification, typeColor),
                        const SizedBox(height: 16),
                        _buildMetaSection(notification),
                        const SizedBox(height: 24),
                        _buildActionButtons(notification),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(domain.Notification notification, Color typeColor) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceContainerHighest,
          foregroundColor: AppColors.textPrimary,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 64, bottom: 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notification',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
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
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface.withValues(alpha: 0.9),
                AppColors.surface.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (!notification.isRead)
          IconButton(
            icon: const Icon(Icons.mark_email_read_rounded),
            onPressed: () {
              context.read<NotificationBloc>().add(
                MarkAsRead(notification.id!),
              );
              Navigator.pop(context, true);
            },
            tooltip: 'Mark as Read',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHighest,
              foregroundColor: typeColor,
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: _showDeleteConfirmation,
          tooltip: 'Delete',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceContainerHighest,
            foregroundColor: AppColors.error,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNotificationCard(
    domain.Notification notification,
    Color typeColor,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      blur: 15,
      borderColor: typeColor.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: _getTypeGradient(notification.type),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: PremiumShadows.glow(context, typeColor, intensity: 0.4),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
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
                      notification.title,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
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
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fiber_new_rounded,
                              size: 12,
                              color: AppColors.textOnPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Unread',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textOnPrimary,
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

          // Body
          Text(
            notification.message,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaSection(domain.Notification notification) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      blur: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Details',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetaRow('Created', formatDateTime(notification.createdAt)),
          if (notification.readAt != null)
            _buildMetaRow('Read At', formatDateTime(notification.readAt!)),
          _buildMetaRow('Notification ID', notification.id?.toString() ?? 'N/A'),
          _buildMetaRow('Type', notification.type.displayName),
          _buildMetaRow('Status', notification.isRead ? 'Read' : 'Unread'),
          if (notification.referenceType != null)
            _buildMetaRow('Reference', '${notification.referenceType}: ${notification.referenceId}'),
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
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(domain.Notification notification) {
    final typeColor = _getTypeColor(notification.type);
    final isUnread = !notification.isRead;

    return Row(
      children: [
        if (isUnread)
          Expanded(
            child: CpButton(
              text: 'Mark as Read',
              variant: ButtonVariant.primary,
              icon: Icons.mark_email_read_rounded,
              onPressed: () {
                context.read<NotificationBloc>().add(
                  MarkAsRead(notification.id!),
                );
                Navigator.pop(context, true);
              },
              expanded: true,
              gradient: AppColors.gradientPrimary,
            ),
          )
        else
          Expanded(
            child: CpButton(
              text: 'Back to List',
              variant: ButtonVariant.secondary,
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
              expanded: true,
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: CpButton(
            text: 'Delete',
            variant: ButtonVariant.outline,
            icon: Icons.delete_outline_rounded,
            onPressed: _showDeleteConfirmation,
            expanded: true,
            foregroundColor: AppColors.error,
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
        content: const Text('Are you sure you want to delete this notification? This action cannot be undone.'),
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
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  LinearGradient _getTypeGradient(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.appointmentReminder:
        return const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]);
      case domain.NotificationType.queueUpdate:
        return const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]);
      case domain.NotificationType.prescriptionReady:
        return const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]);
      case domain.NotificationType.inventoryLow:
        return const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]);
      case domain.NotificationType.system:
        return const LinearGradient(colors: [Color(0xFF6B7280), Color(0xFF4B5563)]);
    }
  }

  Color _getTypeColor(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.appointmentReminder:
        return const Color(0xFF3B82F6);
      case domain.NotificationType.queueUpdate:
        return const Color(0xFFF59E0B);
      case domain.NotificationType.prescriptionReady:
        return const Color(0xFF8B5CF6);
      case domain.NotificationType.inventoryLow:
        return const Color(0xFF10B981);
      case domain.NotificationType.system:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getTypeIcon(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.appointmentReminder:
        return Icons.calendar_today_rounded;
      case domain.NotificationType.queueUpdate:
        return Icons.queue_rounded;
      case domain.NotificationType.prescriptionReady:
        return Icons.medication_rounded;
      case domain.NotificationType.inventoryLow:
        return Icons.inventory_rounded;
      case domain.NotificationType.system:
        return Icons.settings_rounded;
    }
  }
}