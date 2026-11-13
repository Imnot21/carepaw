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
import 'package:carepaw/core/widgets/neomorphism/neu_state.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
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

  static NeuButtonSize _buttonSize(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) > 1.2
      ? NeuButtonSize.small
      : NeuButtonSize.medium;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return NeuCard(
      padding: const EdgeInsets.all(NeuTokens.spaceMd),
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
                              color: ThemeColors.textPrimary(context),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: ThemeColors.textSecondary(context),
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
                  ? (ThemeColors.textPrimary(context))
                  : (ThemeColors.textSecondary(context)),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Action buttons
          if (isUnread)
            NeuButton(
              text: 'Mark as read',
              variant: NeuButtonVariant.primary,
              icon: Icons.mark_email_read_rounded,
              svgAsset: SvgIcons.email,
              size: _buttonSize(context),
              onPressed: () {
                context.read<NotificationBloc>().add(
                  MarkAsRead(notification.id!),
                );
              },
              expanded: true,
            )
          else
            Wrap(
              spacing: NeuTokens.spaceXs,
              runSpacing: NeuTokens.spaceXs,
              children: [
                NeuButton(
                  text: 'View details',
                  variant: NeuButtonVariant.secondary,
                  icon: Icons.visibility_rounded,
                  svgAsset: SvgIcons.visibility,
                  size: _buttonSize(context),
                  onPressed: onViewDetails,
                ),
                NeuButton(
                  text: 'Delete',
                  variant: NeuButtonVariant.outline,
                  icon: Icons.delete_outline_rounded,
                  svgAsset: SvgIcons.delete,
                  size: _buttonSize(context),
                  onPressed: onDelete,
                ),
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
      title: 'Create test notification',
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeuTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'Notification title',
            ),
            const SizedBox(height: NeuTokens.spaceMd),
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
            if (_titleController.text.trim().isNotEmpty &&
                _bodyController.text.trim().isNotEmpty) {
              final bloc = context.read<NotificationBloc>();
              Navigator.pop(context);
              bloc.add(
                CreateNotification(
                  title: _titleController.text.trim(),
                  body: _bodyController.text.trim(),
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
              selectedColor: ThemeColors.primary(context),
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
    // Same quiet treatment as every other empty list (NeuEmptyState). The
    // action is a text button: refreshing an empty inbox is not the main
    // thing anyone came here to do.
    return NeuEmptyState(
      icon: Icons.notifications_none_rounded,
      svgAsset: svgAsset,
      title: title,
      message: message,
      secondaryActionLabel: actionLabel,
      onSecondaryAction: onAction,
    );
  }
}

/// Not logged in view
class NotificationNotLoggedInView extends StatelessWidget {
  const NotificationNotLoggedInView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(NeuTokens.pagePadding),
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
                  child: NeuSvgIcon(SvgIcons.notifications, size: 80),
                ),
              ),
              const SizedBox(height: NeuTokens.sectionGap),
              Text(
                'Sign in to see notifications',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.textPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to stay updated with your clinic',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NeuTokens.spaceXxl),
              NeuButton(
                text: 'Sign in',
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
