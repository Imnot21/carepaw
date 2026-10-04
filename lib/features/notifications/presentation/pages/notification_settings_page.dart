import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_event.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_state.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_switch.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';

/// Notification settings page with the CarePaw surface system
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const LoadNotificationPreferences());
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark
          ? AppColors.backgroundDark
          : AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  if (state is NotificationLoading) {
                    return const NeuSkeletonDetail();
                  }

                  NotificationPreferences? preferences;
                  if (state is NotificationPreferencesLoaded) {
                    preferences = state.preferences;
                  }

                  return Column(
                    children: [
                      _buildMasterToggle(preferences),
                      const SizedBox(height: 20),
                      _buildCategoryToggles(preferences),
                      const SizedBox(height: 20),
                      _buildDeliverySettings(preferences),
                      const SizedBox(height: 20),
                      _buildQuietHours(preferences),
                      const SizedBox(height: 20),
                      _buildDataManagement(),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: NeuIconButton(
        icon: Icons.arrow_back_rounded,
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 64, bottom: 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notification Settings',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: _isDark
                    ? AppColors.textPrimaryOnDark
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Customize how you receive alerts',
              style: AppTextStyles.bodySmall.copyWith(
                color: _isDark
                    ? AppColors.textSecondaryOnDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterToggle(NotificationPreferences? preferences) {
    final isEnabled = preferences?.inAppEnabled ?? true;

    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          NeuAvatar(
            radius: 20,
            icon: Icons.notifications_active_rounded,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Notifications',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _isDark
                        ? AppColors.textPrimaryOnDark
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Enable or disable all notifications',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _isDark
                        ? AppColors.textSecondaryOnDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          NeuSwitch(
            value: isEnabled,
            onChanged: (value) => _updatePreference(
              preferences?.copyWith(inAppEnabled: value) ??
                  NotificationPreferences(
                    userId: 0,
                    inAppEnabled: value,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryToggles(NotificationPreferences? preferences) {
    final categories = [
      _CategorySetting(
        type: NotificationType.appointmentReminder,
        title: 'Appointment Reminders',
        subtitle: 'Booking confirmations, reminders, changes',
        icon: Icons.calendar_today_rounded,
        color: AppColors.primary,
        enabled: preferences?.appointmentReminders ?? true,
      ),
      _CategorySetting(
        type: NotificationType.queueUpdate,
        title: 'Queue Updates',
        subtitle: 'Position changes, your turn notifications',
        icon: Icons.queue_rounded,
        color: AppColors.warning,
        enabled: preferences?.queueUpdates ?? true,
      ),
      _CategorySetting(
        type: NotificationType.inventoryLow,
        title: 'Inventory Alerts',
        subtitle: 'Low stock, expiring medicines, restocks',
        icon: Icons.inventory_rounded,
        color: AppColors.success,
        enabled: preferences?.inventoryAlerts ?? true,
      ),
      _CategorySetting(
        type: NotificationType.prescriptionReady,
        title: 'Prescriptions',
        subtitle: 'New prescriptions, refill reminders',
        icon: Icons.medication_rounded,
        color: AppColors.categorySupply,
        enabled: preferences?.prescriptionReady ?? true,
      ),
      _CategorySetting(
        type: NotificationType.system,
        title: 'System',
        subtitle: 'App updates, maintenance, announcements',
        icon: Icons.settings_rounded,
        color: ThemeColors.textSecondary(context),
        enabled: preferences?.systemAnnouncements ?? true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Categories',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: _isDark
                ? AppColors.textPrimaryOnDark
                : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final category = categories[index];
            return NeuCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  NeuAvatar(
                    radius: 18,
                    icon: category.icon,
                    backgroundColor: category.color,
                    foregroundColor: AppColors.textOnPrimary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.title,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _isDark
                                ? AppColors.textPrimaryOnDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          category.subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _isDark
                                ? AppColors.textSecondaryOnDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  NeuSwitch(
                    value: category.enabled,
                    onChanged: (value) => _updateTypePreference(
                      category.type,
                      value,
                      preferences,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDeliverySettings(NotificationPreferences? preferences) {
    final settings = [
      _DeliverySetting(
        title: 'Push Notifications',
        subtitle: 'Receive push notifications on this device',
        icon: Icons.phone_android_rounded,
        value: preferences?.pushEnabled ?? true,
        onChanged: (value) => _updatePreference(
          preferences?.copyWith(pushEnabled: value) ??
              NotificationPreferences(
                userId: 0,
                pushEnabled: value,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
        ),
      ),
      _DeliverySetting(
        title: 'Email Notifications',
        subtitle: 'Receive email copies of important notifications',
        icon: Icons.email_rounded,
        value: preferences?.emailEnabled ?? false,
        onChanged: (value) => _updatePreference(
          preferences?.copyWith(emailEnabled: value) ??
              NotificationPreferences(
                userId: 0,
                emailEnabled: value,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
        ),
      ),
      _DeliverySetting(
        title: 'In-App Notifications',
        subtitle: 'Show notifications within the app',
        icon: Icons.badge_rounded,
        value: preferences?.inAppEnabled ?? true,
        onChanged: (value) => _updatePreference(
          preferences?.copyWith(inAppEnabled: value) ??
              NotificationPreferences(
                userId: 0,
                inAppEnabled: value,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Methods',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: _isDark
                ? AppColors.textPrimaryOnDark
                : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose how you receive notifications',
          style: AppTextStyles.bodySmall.copyWith(
            color: _isDark
                ? AppColors.textSecondaryOnDark
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: settings.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final setting = settings[index];
            return NeuCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  NeuAvatar(
                    radius: 18,
                    icon: setting.icon,
                    backgroundColor: ThemeColors.surfaceVariant(context),
                    foregroundColor: ThemeColors.primary(context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          setting.title,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _isDark
                                ? AppColors.textPrimaryOnDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          setting.subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _isDark
                                ? AppColors.textSecondaryOnDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  NeuSwitch(value: setting.value, onChanged: setting.onChanged),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuietHours(NotificationPreferences? preferences) {
    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          NeuAvatar(
            radius: 20,
            icon: Icons.bedtime_rounded,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiet Hours',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _isDark
                        ? AppColors.textPrimaryOnDark
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Silence notifications during specified hours (coming soon)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _isDark
                        ? AppColors.textSecondaryOnDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Management',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: _isDark
                ? AppColors.textPrimaryOnDark
                : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        NeuCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildDataAction(
                icon: Icons.delete_sweep_rounded,
                title: 'Clear All Read Notifications',
                subtitle: 'Permanently delete all read notifications',
                color: ThemeColors.warning(context),
                onTap: _clearReadNotifications,
              ),
              const Divider(height: 24),
              _buildDataAction(
                icon: Icons.delete_forever_rounded,
                title: 'Delete All Notifications',
                subtitle:
                    'Permanently delete all notifications (cannot be undone)',
                color: ThemeColors.error(context),
                onTap: _deleteAllNotifications,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            NeuAvatar(
              radius: 16,
              icon: icon,
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? color
                          : (_isDark
                                ? AppColors.textPrimaryOnDark
                                : AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _isDark
                          ? AppColors.textSecondaryOnDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _isDark
                  ? AppColors.textTertiaryOnDark
                  : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _updatePreference(NotificationPreferences preferences) {
    context.read<NotificationBloc>().add(
      UpdateNotificationPreferences(preferences),
    );
  }

  void _updateTypePreference(
    NotificationType type,
    bool enabled,
    NotificationPreferences? current,
  ) {
    final updated =
        (current ??
                NotificationPreferences(
                  userId: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ))
            .copyWith(
              appointmentReminders: type == NotificationType.appointmentReminder
                  ? enabled
                  : (current?.appointmentReminders ?? true),
              queueUpdates: type == NotificationType.queueUpdate
                  ? enabled
                  : (current?.queueUpdates ?? true),
              inventoryAlerts: type == NotificationType.inventoryLow
                  ? enabled
                  : (current?.inventoryAlerts ?? true),
              prescriptionReady: type == NotificationType.prescriptionReady
                  ? enabled
                  : (current?.prescriptionReady ?? true),
              systemAnnouncements: type == NotificationType.system
                  ? enabled
                  : (current?.systemAnnouncements ?? true),
            );
    _updatePreference(updated);
  }

  void _clearReadNotifications() {
    NeuConfirmDialog.show(
      context: context,
      title: 'Clear Read Notifications',
      message:
          'Are you sure you want to delete all read notifications? This action cannot be undone.',
      confirmText: 'Clear',
      confirmVariant: NeuButtonVariant.destructive,
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<NotificationBloc>().add(
          const DeleteAllReadNotifications(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Read notifications cleared'),
            backgroundColor: ThemeColors.success(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });
  }

  void _deleteAllNotifications() {
    NeuConfirmDialog.show(
      context: context,
      title: 'Delete All Notifications',
      message:
          'This will permanently delete ALL notifications. This action cannot be undone.',
      confirmText: 'Delete All',
      confirmVariant: NeuButtonVariant.destructive,
    ).then((confirmed) {
      if (confirmed == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Feature coming soon'),
            backgroundColor: ThemeColors.primary(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });
  }
}

class _CategorySetting {
  final NotificationType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;

  _CategorySetting({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
  });
}

class _DeliverySetting {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  _DeliverySetting({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });
}
