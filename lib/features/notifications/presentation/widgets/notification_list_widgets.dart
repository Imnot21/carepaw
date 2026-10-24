import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart'
    as domain;
import 'package:carepaw/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_event.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/utils/formatters.dart';

/// Card rendering a single notification with actions.
class NotificationCard extends StatelessWidget {
  final domain.Notification notification;
  final Color typeColor;
  final String typeSvg;
  final VoidCallback onViewDetails;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.typeColor,
    required this.typeSvg,
    required this.onViewDetails,
    required this.onDelete,
  });

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return NeuCard(
      padding: const EdgeInsets.all(16),
      variant: NeuVariant.raised,
      borderColor: isUnread ? typeColor.withValues(alpha: 0.3) : null,
      borderWidth: isUnread ? 1 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon with background
              Stack(
                alignment: Alignment.center,
                children: [
                  NeuAvatar(
                    radius: 22,
                    svgAsset: typeSvg,
                    backgroundColor: typeColor,
                    foregroundColor: AppColors.textOnPrimary,
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Title and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: _isDark(context)
                                  ? AppColors.textPrimaryOnDark
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRelativeTime(notification.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _isDark(context)
                            ? AppColors.textSecondaryOnDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (isUnread)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: ThemeColors.primary(context),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Body preview
          Text(
            notification.message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isUnread
                  ? (_isDark(context)
                        ? AppColors.textPrimaryOnDark
                        : AppColors.textPrimary)
                  : (_isDark(context)
                        ? AppColors.textSecondaryOnDark
                        : AppColors.textSecondary),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Data preview if available
          if (notification.referenceType != null) ...[
            const SizedBox(height: 8),
            NeuCard(
              padding: const EdgeInsets.all(10),
              variant: NeuVariant.inset,
              borderRadius: NeuTokens.radiusSm,
              child: Row(
                children: [
                  NeuSvgIcon(SvgIcons.info, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${notification.referenceType}: ${notification.referenceId}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _isDark(context)
                            ? AppColors.textSecondaryOnDark
                            : AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              if (isUnread)
                Expanded(
                  child: NeuButton(
                    text: 'Mark Read',
                    variant: NeuButtonVariant.primary,
                    icon: Icons.mark_email_read_rounded,
                    svgAsset: SvgIcons.email,
                    size: NeuButtonSize.medium,
                    onPressed: () {
                      context.read<NotificationBloc>().add(
                        MarkAsRead(notification.id!),
                      );
                    },
                    expanded: true,
                  ),
                )
              else ...[
                Expanded(
                  child: NeuButton(
                    text: 'View Details',
                    variant: NeuButtonVariant.secondary,
                    icon: Icons.visibility_rounded,
                    svgAsset: SvgIcons.visibility,
                    size: NeuButtonSize.medium,
                    onPressed: () => onViewDetails(),
                    expanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NeuButton(
                    text: 'Delete',
                    variant: NeuButtonVariant.outline,
                    icon: Icons.delete_outline_rounded,
                    svgAsset: SvgIcons.delete,
                    size: NeuButtonSize.medium,
                    onPressed: () {
                      onDelete();
                    },
                    expanded: true,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class NotificationCreateDialog extends StatefulWidget {
  const NotificationCreateDialog({super.key});

  @override
  State<NotificationCreateDialog> createState() =>
      _NotificationCreateDialogState();
}

class _NotificationCreateDialogState extends State<NotificationCreateDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  domain.NotificationType _selectedType =
      domain.NotificationType.appointmentReminder;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeuDialog(
      title: 'Create Test Notification',
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeuTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'Notification title',
            ),
            const SizedBox(height: 16),
            NeuTextField(
              controller: _bodyController,
              label: 'Body',
              hint: 'Notification message',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTypeSelector(),
          ],
        ),
      ),
      actions: [
        NeuButton(
          text: 'Cancel',
          variant: NeuButtonVariant.ghost,
          onPressed: () => Navigator.pop(context),
        ),
        NeuButton(
          text: 'Create',
          variant: NeuButtonVariant.primary,
          onPressed: () {
            if (_titleController.text.isNotEmpty &&
                _bodyController.text.isNotEmpty) {
              final bloc = context.read<NotificationBloc>();
              Navigator.pop(context);
              bloc.add(
                CreateNotification(
                  title: _titleController.text,
                  body: _bodyController.text,
                  type: _selectedType,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    // PAPER-ONLY: test-create offers appointment + queue types only.
    const types = [
      domain.NotificationType.appointmentReminder,
      domain.NotificationType.queueUpdate,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((type) {
            final isSelected = _selectedType == type;
            return NeuChip(
              label: type.displayName,
              selected: isSelected,
              onTap: () => setState(() => _selectedType = type),
              selectedColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Empty state shown when a notification tab has no content.
class NotificationEmptyState extends StatelessWidget {
  final String? svgAsset;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const NotificationEmptyState({
    super.key,
    this.svgAsset,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: NeuCard(
          borderRadius: NeuTokens.radiusMd,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeuContainer(
                borderRadius: 90,
                padding: const EdgeInsets.all(22),
                color: AppColors.primary,
                boxShadow: NeuShadow.color(
                  context,
                  AppColors.primary,
                  blur: 24,
                  opacity: 0.32,
                ),
                child: svgAsset != null
                    ? NeuSvgIcon(svgAsset!, size: 48)
                    : const SizedBox(width: 48, height: 48),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryOnDark
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryOnDark
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                NeuButton(
                  text: actionLabel!,
                  onPressed: onAction,
                  variant: NeuButtonVariant.primary,
                  size: NeuButtonSize.medium,
                  icon: Icons.refresh_rounded,
                  svgAsset: SvgIcons.refresh,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Not logged in view
class NotificationNotLoggedInView extends StatelessWidget {
  const NotificationNotLoggedInView({super.key});

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark(context)
          ? AppColors.backgroundDark
          : AppColors.background,
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
                  color: AppColors.primary,
                  child: NeuSvgIcon(SvgIcons.notifications, size: 80),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Please log in to view notifications',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _isDark(context)
                      ? AppColors.textPrimaryOnDark
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to stay updated with your clinic',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: _isDark(context)
                      ? AppColors.textSecondaryOnDark
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              NeuButton(
                text: 'Log In',
                onPressed: () => context.go(Routes.login),
                icon: Icons.login_rounded,
                svgAsset: SvgIcons.login,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
