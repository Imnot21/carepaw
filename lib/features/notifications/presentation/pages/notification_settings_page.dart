import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_event.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_state.dart';
import 'package:carepaw/core/widgets/common/cp_loader.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/floating_animation.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';

/// Notification settings page with premium design
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const LoadNotificationPreferences());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        colors: [
          AppColors.primary.withValues(alpha: 0.06),
          AppColors.secondary.withValues(alpha: 0.04),
          AppColors.surface,
        ],
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: BlocBuilder<NotificationBloc, NotificationState>(
                  builder: (context, state) {
                    if (state is NotificationLoading) {
                      return const Center(child: CpLoader(size: 48));
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
              'Notification Settings',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Customize how you receive alerts',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
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
    );
  }

  Widget _buildMasterToggle(NotificationPreferences? preferences) {
    final isEnabled = preferences?.inAppEnabled ?? true;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      blur: 15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 24,
                  color: AppColors.textOnPrimary,
                ),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Enable or disable all notifications',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isEnabled,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                inactiveThumbColor: AppColors.divider,
                inactiveTrackColor: AppColors.surfaceContainerHighest,
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
        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
        enabled: preferences?.appointmentReminders ?? true,
      ),
      _CategorySetting(
        type: NotificationType.queueUpdate,
        title: 'Queue Updates',
        subtitle: 'Position changes, your turn notifications',
        icon: Icons.queue_rounded,
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
        enabled: preferences?.queueUpdates ?? true,
      ),
      _CategorySetting(
        type: NotificationType.inventoryLow,
        title: 'Inventory Alerts',
        subtitle: 'Low stock, expiring medicines, restocks',
        icon: Icons.inventory_rounded,
        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        enabled: preferences?.inventoryAlerts ?? true,
      ),
      _CategorySetting(
        type: NotificationType.prescriptionReady,
        title: 'Prescriptions',
        subtitle: 'New prescriptions, refill reminders',
        icon: Icons.medication_rounded,
        gradient: LinearGradient(colors: [AppColors.categorySupply, AppColors.categorySupplyDark]),
        enabled: preferences?.prescriptionReady ?? true,
      ),
      _CategorySetting(
        type: NotificationType.system,
        title: 'System',
        subtitle: 'App updates, maintenance, announcements',
        icon: Icons.settings_rounded,
        gradient: const LinearGradient(colors: [Color(0xFF6B7280), Color(0xFF4B5563)]),
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
            color: AppColors.textPrimary,
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
            return FloatingAnimation(
              delay: Duration(milliseconds: 50 * index),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                blur: 10,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: category.gradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        category.icon,
                        size: 22,
                        color: AppColors.textOnPrimary,
                      ),
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
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            category.subtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: category.enabled,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                      inactiveThumbColor: AppColors.divider,
                      inactiveTrackColor: AppColors.surfaceContainerHighest,
                      onChanged: (value) => _updateTypePreference(
                        category.type,
                        value,
                        preferences,
                      ),
                    ),
                  ],
                ),
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
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose how you receive notifications',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
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
            return FloatingAnimation(
              delay: Duration(milliseconds: 50 * index),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                blur: 10,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        setting.icon,
                        size: 22,
                        color: AppColors.primary,
                      ),
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
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            setting.subtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: setting.value,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                      inactiveThumbColor: AppColors.divider,
                      inactiveTrackColor: AppColors.surfaceContainerHighest,
                      onChanged: setting.onChanged,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuietHours(NotificationPreferences? preferences) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      blur: 15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.bedtime_rounded,
                  size: 24,
                  color: AppColors.textOnPrimary,
                ),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Silence notifications during specified hours (coming soon)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          blur: 10,
          child: Column(
            children: [
              _buildDataAction(
                icon: Icons.delete_sweep_rounded,
                title: 'Clear All Read Notifications',
                subtitle: 'Permanently delete all read notifications',
                color: AppColors.warning,
                onTap: _clearReadNotifications,
              ),
              const Divider(height: 24),
              _buildDataAction(
                icon: Icons.delete_forever_rounded,
                title: 'Delete All Notifications',
                subtitle: 'Permanently delete all notifications (cannot be undone)',
                color: AppColors.error,
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
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
                      color: isDestructive ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
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
    final updated = (current ?? NotificationPreferences(
      userId: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )).copyWith(
      appointmentReminders: type == NotificationType.appointmentReminder ? enabled : (current?.appointmentReminders ?? true),
      queueUpdates: type == NotificationType.queueUpdate ? enabled : (current?.queueUpdates ?? true),
      inventoryAlerts: type == NotificationType.inventoryLow ? enabled : (current?.inventoryAlerts ?? true),
      prescriptionReady: type == NotificationType.prescriptionReady ? enabled : (current?.prescriptionReady ?? true),
      systemAnnouncements: type == NotificationType.system ? enabled : (current?.systemAnnouncements ?? true),
    );
    _updatePreference(updated);
  }

  void _clearReadNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Read Notifications'),
        content: const Text('Are you sure you want to delete all read notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NotificationBloc>().add(const DeleteAllReadNotifications());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Read notifications cleared'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Text('Clear', style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  void _deleteAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete All Notifications', style: TextStyle(color: AppColors.error)),
        content: const Text('This will permanently delete ALL notifications. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // This would need a new event - for now just show message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Feature coming soon'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Text('Delete All', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _CategorySetting {
  final NotificationType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final bool enabled;

  _CategorySetting({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
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